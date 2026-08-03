-- ─────────────────────────────────────────────────────────────────────────────
-- 02_channel_classification.sql
--
-- PRODUCES : work/mddo_payments_5yr.parquet  (per-MD/DO general-payment rollup)
--            work/analysis_base.parquet      (the master analysis table)
-- SOURCE   : PHASE_S_FINDINGS.md §S1 (F&B split); PHASE_B_FINDINGS.md §B2
--            (DAC group size); PHASE_R_FINDINGS.md §R2 (four-cell);
--            PHASE_W_FINDINGS.md §W2 (research/ownership, three-axis)
-- INPUTS   : work/analytic_population.parquet, work/op_general_py202*.parquet,
--            work/op_rsrch_py202*.parquet, work/op_ownrshp_py202*.parquet,
--            work/dac_national.parquet, work/facility_affiliation.parquet
--
-- Three things here are easy to get wrong and are called out:
--
-- 1. RESEARCH NPIs. Research files carry Covered_Recipient_NPI *and*
--    Principal_Investigator_1..5_NPI. 54,119 physicians appear only in the PI
--    slots against 16,210 as covered recipient, because the covered recipient on
--    a research payment is usually the institution. Using the obvious field
--    alone misses ~70% of the population. All six are unioned below.
--
-- 2. DAC GRANULARITY. One row per NPI x organization x address. Collapsed to one
--    row per NPI; primary organization = the non-blank org_pac_id with the most
--    address rows, tie-broken by larger group size then org id. Blank org_pac_id
--    always carries grp_assgn='M' (no group reassignment) and is treated as solo.
--
-- 3. ENGAGEMENT DEFINITIONS. Three are carried and must never be mixed:
--      never_base  — absent from the Profile Supplement (cumulative, all years,
--                    all three payment categories). THE headline definition.
--      never_fnb5  — never_base OR five-year general-payment footprint is
--                    food-and-beverage only. Upper bound; 2013-2020 unobserved.
--      never_adj_w — never_fnb5 but also requiring no research payment.
-- ─────────────────────────────────────────────────────────────────────────────
SET memory_limit='9GB';
SET threads=3;
SET preserve_insertion_order=false;

-- ── per-MD/DO general-payment rollup, PY2021-2025 ────────────────────────────
COPY (
WITH m AS (SELECT npi, partd_state, partd_specialty, tot_clms, tot_drug_cst, never_engaged
           FROM 'work/analytic_population.parquet' WHERE is_mddo),
p AS (SELECT trim(Covered_Recipient_NPI) AS npi,
             TRY_CAST(Program_Year AS INTEGER) AS yr,
             (Nature_of_Payment_or_Transfer_of_Value='Food and Beverage') AS is_fnb,
             TRY_CAST(Total_Amount_of_Payment_USDollars AS DOUBLE) AS usd
      FROM read_parquet('work/op_general_py202*.parquet')
      WHERE length(trim(coalesce(Covered_Recipient_NPI,'')))=10)
SELECT m.npi,
  any_value(m.partd_state) AS partd_state, any_value(m.partd_specialty) AS partd_specialty,
  any_value(m.tot_clms) AS tot_clms, any_value(m.tot_drug_cst) AS tot_drug_cst,
  any_value(m.never_engaged) AS never_engaged,
  count(*) AS n_records, round(sum(p.usd),2) AS total_usd,
  count(*) FILTER (WHERE p.is_fnb)      AS n_fnb,
  round(sum(p.usd) FILTER (WHERE p.is_fnb),2)     AS usd_fnb,
  count(*) FILTER (WHERE NOT p.is_fnb)  AS n_nonfnb,
  round(sum(p.usd) FILTER (WHERE NOT p.is_fnb),2) AS usd_nonfnb,
  count(DISTINCT p.yr) AS n_years_paid, min(p.yr) AS first_year, max(p.yr) AS last_year
FROM m JOIN p ON m.npi=p.npi GROUP BY m.npi
) TO 'work/mddo_payments_5yr.parquet' (FORMAT PARQUET, COMPRESSION ZSTD, ROW_GROUP_SIZE 100000);

-- ── master analysis table ────────────────────────────────────────────────────
CREATE OR REPLACE TEMP TABLE rsrch AS
SELECT npi, count(*) AS n_rsrch, sum(usd) AS usd_rsrch, count(DISTINCT yr) AS n_years_rsrch
FROM (
  SELECT trim(Covered_Recipient_NPI)        AS npi, TRY_CAST(Program_Year AS INTEGER) AS yr,
         TRY_CAST(Total_Amount_of_Payment_USDollars AS DOUBLE) AS usd FROM read_parquet('work/op_rsrch_py202*.parquet')
  UNION ALL SELECT trim(Principal_Investigator_1_NPI), TRY_CAST(Program_Year AS INTEGER), TRY_CAST(Total_Amount_of_Payment_USDollars AS DOUBLE) FROM read_parquet('work/op_rsrch_py202*.parquet')
  UNION ALL SELECT trim(Principal_Investigator_2_NPI), TRY_CAST(Program_Year AS INTEGER), TRY_CAST(Total_Amount_of_Payment_USDollars AS DOUBLE) FROM read_parquet('work/op_rsrch_py202*.parquet')
  UNION ALL SELECT trim(Principal_Investigator_3_NPI), TRY_CAST(Program_Year AS INTEGER), TRY_CAST(Total_Amount_of_Payment_USDollars AS DOUBLE) FROM read_parquet('work/op_rsrch_py202*.parquet')
  UNION ALL SELECT trim(Principal_Investigator_4_NPI), TRY_CAST(Program_Year AS INTEGER), TRY_CAST(Total_Amount_of_Payment_USDollars AS DOUBLE) FROM read_parquet('work/op_rsrch_py202*.parquet')
  UNION ALL SELECT trim(Principal_Investigator_5_NPI), TRY_CAST(Program_Year AS INTEGER), TRY_CAST(Total_Amount_of_Payment_USDollars AS DOUBLE) FROM read_parquet('work/op_rsrch_py202*.parquet')
) WHERE length(coalesce(npi,''))=10 GROUP BY 1;

CREATE OR REPLACE TEMP TABLE own AS
SELECT trim(Physician_NPI) AS npi, count(*) AS n_own,
       sum(TRY_CAST(Total_Amount_Invested_USDollars AS DOUBLE)) AS usd_own
FROM read_parquet('work/op_ownrshp_py202*.parquet')
WHERE length(trim(coalesce(Physician_NPI,'')))=10 GROUP BY 1;

CREATE OR REPLACE TEMP TABLE dac_rows AS
SELECT NPI AS npi, nullif(trim(org_pac_id),'') AS org,
       TRY_CAST(nullif(trim(num_org_mem),'') AS BIGINT) AS grp,
       nullif(trim("Facility Name"),'') AS org_name
FROM 'work/dac_national.parquet';
CREATE OR REPLACE TEMP TABLE dac_primary AS
SELECT npi, org AS org_primary, grp AS grp_primary, org_name AS org_primary_name FROM (
  SELECT npi, org, max(grp) AS grp, any_value(org_name) AS org_name, count(*) AS n_rows,
         row_number() OVER (PARTITION BY npi ORDER BY count(*) DESC, max(grp) DESC NULLS LAST, org) AS rn
  FROM dac_rows WHERE org IS NOT NULL GROUP BY npi, org) WHERE rn=1;
CREATE OR REPLACE TEMP TABLE dac_agg AS
SELECT npi, count(*) AS n_dac_rows, count(DISTINCT org) AS n_orgs FROM dac_rows GROUP BY 1;
CREATE OR REPLACE TEMP TABLE fac_agg AS
SELECT NPI AS npi,
  count(DISTINCT nullif(trim("Facility Affiliations Certification Number"),'')) AS n_facilities,
  count(DISTINCT nullif(trim(facility_type),'')) AS n_fac_types
FROM 'work/facility_affiliation.parquet' GROUP BY 1;

COPY (
WITH mddo AS (
  SELECT npi, partd_specialty, partd_state, partd_ruca, tot_clms, tot_drug_cst, never_engaged,
    tot_drug_cst/tot_clms AS cpc,
    -- DETERMINISM: npi is a tiebreaker, and it matters more than it looks.
    -- 99.2% of MD/DOs share a tot_clms value with at least one other physician
    -- and the largest tie group is 5,687. NTILE splits tie groups by physical
    -- row order, so without a tiebreaker ~1,838 physicians (0.26%) change decile
    -- between runs of the identical query. That is enough to move the
    -- discriminant medians by 0.001 and, in principle, the membership of the
    -- 553. The published findings were computed WITHOUT this tiebreaker; see
    -- notes/PHASE_P_NOTES.md for the reconciliation.
    NTILE(10) OVER (ORDER BY tot_clms, npi) AS clms_decile,
    NTILE(10) OVER (ORDER BY tot_drug_cst/tot_clms, npi) AS cpc_decile,
    CASE WHEN TRY_CAST(partd_ruca AS DOUBLE) IS NULL THEN 'Unknown'
         WHEN floor(TRY_CAST(partd_ruca AS DOUBLE)) BETWEEN 1 AND 3 THEN '1 Metropolitan'
         WHEN floor(TRY_CAST(partd_ruca AS DOUBLE)) BETWEEN 4 AND 6 THEN '2 Micropolitan'
         WHEN floor(TRY_CAST(partd_ruca AS DOUBLE)) BETWEEN 7 AND 9 THEN '3 Small town'
         WHEN floor(TRY_CAST(partd_ruca AS DOUBLE)) = 10 THEN '4 Rural'
         ELSE 'Unknown' END AS ruca_cat
  FROM 'work/analytic_population.parquet' WHERE is_mddo)
SELECT m.*,
  m.never_engaged AS never_base,
  (d.npi IS NOT NULL) AS in_dac, coalesce(d.n_orgs,0) AS n_orgs,
  dp.org_primary, dp.org_primary_name,
  CASE WHEN d.npi IS NULL THEN NULL WHEN coalesce(d.n_orgs,0)=0 THEN 1 ELSE dp.grp_primary END AS grp_size,
  (f.npi IS NOT NULL) AS in_fac, coalesce(f.n_facilities,0) AS n_facilities,
  (p.npi IS NOT NULL) AS paid_5yr,
  coalesce(p.n_records,0) AS n_rec5, coalesce(p.total_usd,0) AS usd5,
  coalesce(p.n_fnb,0) AS n_fnb5, coalesce(p.n_nonfnb,0) AS n_nonfnb5,
  coalesce(p.n_years_paid,0) AS n_years5,
  (r.npi IS NOT NULL) AS has_research, coalesce(r.n_rsrch,0) AS n_rsrch, coalesce(r.usd_rsrch,0) AS usd_rsrch,
  (o.npi IS NOT NULL) AS has_ownership,
  -- engagement definitions
  (m.never_engaged OR (p.npi IS NOT NULL AND p.n_nonfnb=0)) AS never_fnb5,
  (m.never_engaged OR (p.npi IS NOT NULL AND p.n_nonfnb=0 AND r.npi IS NULL)) AS never_adj_w,
  -- four-cell, research folded into the non-F&B axis
  CASE WHEN coalesce(p.n_fnb,0)>0 AND (coalesce(p.n_nonfnb,0)>0 OR r.npi IS NOT NULL) THEN '1 fully engaged'
       WHEN coalesce(p.n_fnb,0)>0                                                     THEN '2 meal-only'
       WHEN coalesce(p.n_nonfnb,0)>0 OR r.npi IS NOT NULL                             THEN '3 relationship-only'
       ELSE '4 no record' END AS cell4w,
  -- four-cell, general payments only (the Phase R / R2 definition)
  CASE WHEN coalesce(p.n_fnb,0)>0 AND coalesce(p.n_nonfnb,0)>0 THEN '1 fully engaged'
       WHEN coalesce(p.n_fnb,0)>0                              THEN '2 meal-only'
       WHEN coalesce(p.n_nonfnb,0)>0                           THEN '3 relationship-only'
       ELSE '4 no record' END AS cell4,
  -- three-axis: F&B / general non-F&B / research
  CASE WHEN coalesce(p.n_fnb,0)>0 THEN 'F' ELSE '-' END ||
  CASE WHEN coalesce(p.n_nonfnb,0)>0 THEN 'G' ELSE '-' END ||
  CASE WHEN r.npi IS NOT NULL THEN 'R' ELSE '-' END AS axis3
FROM mddo m
LEFT JOIN 'work/mddo_payments_5yr.parquet' p ON m.npi=p.npi
LEFT JOIN rsrch r       ON m.npi=r.npi
LEFT JOIN own o         ON m.npi=o.npi
LEFT JOIN dac_agg d     ON m.npi=d.npi
LEFT JOIN dac_primary dp ON m.npi=dp.npi
LEFT JOIN fac_agg f     ON m.npi=f.npi
) TO 'work/analysis_base.parquet' (FORMAT PARQUET, COMPRESSION ZSTD, ROW_GROUP_SIZE 100000);

SELECT count(*) AS mddo,
  count(*) FILTER (WHERE never_base)  AS never_base,
  count(*) FILTER (WHERE never_fnb5)  AS never_fnb5,
  count(*) FILTER (WHERE paid_5yr)    AS paid_5yr,
  count(*) FILTER (WHERE has_research) AS has_research,
  count(*) FILTER (WHERE has_ownership) AS has_ownership
FROM 'work/analysis_base.parquet';
