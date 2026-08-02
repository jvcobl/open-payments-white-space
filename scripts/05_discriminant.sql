-- ─────────────────────────────────────────────────────────────────────────────
-- 05_discriminant.sql
--
-- PRODUCES : the two-axis channel discriminant by state group and by
--            organization, nationally and state-relative; the per-organization
--            table consumed by figures/fig1_discriminant.py
-- SOURCE   : PHASE_R_FINDINGS.md §R2; PHASE_W_FINDINGS.md §W4, §W5
-- INPUTS   : work/analysis_base.parquet
-- OUTPUTS  : figures/data/discriminant_orgs.csv (for figure 1)
--
-- DEFINITION. Each unit gets two ratios, observed over expected, where the
-- expectation is the mean rate in that physician's own specialty x volume-decile
-- (x state, for the state-relative version) cell:
--
--   ratio_fnb = P(any food & beverage)      observed / expected
--   ratio_non = P(any non-F&B relationship) observed / expected   [incl. research]
--   discriminant = ratio_non / ratio_fnb
--
-- 1.0 means both channels are suppressed equally. Above 1 = meals suppressed
-- more than relationships (gift-ban-like). Below 1 = relationships suppressed
-- more than meals (contact-ban-like).
--
-- Phase W's W5 finding is why the state-relative version is the one to use:
-- organizations in gift-ban states score 1.130 nationally but 0.994
-- state-relative — they inherit their state's signature. Kaiser does not move
-- (0.713 -> 0.727), which is what makes it an organizational result.
-- ─────────────────────────────────────────────────────────────────────────────
SET memory_limit='9GB'; SET threads=3;

CREATE OR REPLACE TEMP TABLE k AS
SELECT *, (n_nonfnb5>0 OR has_research) AS any_non,
  (org_primary_name ILIKE '%PERMANENTE%' OR org_primary_name ILIKE '%KAISER%') AS is_kaiser
FROM 'work/analysis_base.parquet';

CREATE OR REPLACE TEMP TABLE crN AS      -- national expectation
SELECT coalesce(partd_specialty,'?') sp, clms_decile vd,
  avg((n_fnb5>0)::INT) p_fnb, avg(any_non::INT) p_non FROM k GROUP BY 1,2;
CREATE OR REPLACE TEMP TABLE crS AS      -- state-relative expectation
SELECT coalesce(partd_specialty,'?') sp, clms_decile vd, coalesce(partd_state,'?') st,
  avg((n_fnb5>0)::INT) p_fnb, avg(any_non::INT) p_non FROM k GROUP BY 1,2,3;

.print '--- national four-cell channel distribution ---'
SELECT cell4w AS cell, count(*) AS n, round(100.0*count(*)/sum(count(*)) OVER (),2) AS pct
FROM k GROUP BY 1 ORDER BY 1;

.print '--- three-axis (F = food/bev, G = general non-F&B, R = research) ---'
SELECT axis3, count(*) AS n, round(100.0*count(*)/sum(count(*)) OVER (),2) AS pct
FROM k GROUP BY 1 ORDER BY n DESC;

.print '--- discriminant by state group (national expectation) ---'
SELECT grp, n, round(ratio_fnb,3) AS ratio_fnb, round(ratio_non,3) AS ratio_non,
       round(ratio_non/ratio_fnb,3) AS discriminant
FROM (SELECT grp, count(*) n,
        avg((k.n_fnb5>0)::INT)/avg(crN.p_fnb) ratio_fnb,
        avg(k.any_non::INT)/avg(crN.p_non)    ratio_non
      FROM (SELECT *, CASE WHEN is_kaiser THEN 'Kaiser/Permanente'
              WHEN partd_state IN ('VT','MN','ME','MA') THEN 'Gift-ban (VT,MN,ME,MA)'
              WHEN partd_state IN ('WA','OR','WI')      THEN 'Empirically similar (WA,OR,WI)'
              WHEN partd_state IN ('MS','AL','TX')      THEN 'Low-restriction (MS,AL,TX)'
              ELSE 'Other' END AS grp FROM k) k
      JOIN crN ON coalesce(k.partd_specialty,'?')=crN.sp AND k.clms_decile=crN.vd
      GROUP BY 1) ORDER BY discriminant;

.print '--- organization-level medians: national vs state-relative (Phase W W5) ---'
SELECT grp, count(*) AS n_orgs, sum(n) AS n_physicians,
  round(median(dN),3) AS median_national, round(median(dS),3) AS median_state_relative
FROM (
  SELECT CASE WHEN any_value(k.is_kaiser) THEN 'Kaiser entities'
              WHEN mode(k.partd_state) IN ('VT','MN','ME','MA') THEN 'Orgs in gift-ban states'
              WHEN mode(k.partd_state) IN ('MS','AL','TX','LA','GA','FL','KY','TN') THEN 'Orgs in low-restriction states'
              ELSE 'Orgs elsewhere' END AS grp,
    count(*) AS n,
    (avg(k.any_non::INT)/avg(crN.p_non))/(avg((k.n_fnb5>0)::INT)/avg(crN.p_fnb)) AS dN,
    (avg(k.any_non::INT)/avg(crS.p_non))/(avg((k.n_fnb5>0)::INT)/avg(crS.p_fnb)) AS dS
  FROM k JOIN crN ON coalesce(k.partd_specialty,'?')=crN.sp AND k.clms_decile=crN.vd
         JOIN crS ON coalesce(k.partd_specialty,'?')=crS.sp AND k.clms_decile=crS.vd
                 AND coalesce(k.partd_state,'?')=crS.st
  WHERE k.org_primary IS NOT NULL GROUP BY k.org_primary HAVING count(*)>=100)
GROUP BY 1 ORDER BY median_state_relative;

.print '--- Kaiser entity by entity, state-relative ---'
SELECT k.org_primary_name AS org, count(*) AS n, mode(k.partd_state) AS state,
  round(avg((k.n_fnb5>0)::INT)/avg(crS.p_fnb),3) AS ratio_fnb,
  round(avg(k.any_non::INT)/avg(crS.p_non),3) AS ratio_non,
  round((avg(k.any_non::INT)/avg(crS.p_non))/(avg((k.n_fnb5>0)::INT)/avg(crS.p_fnb)),3) AS discriminant
FROM k JOIN crS ON coalesce(k.partd_specialty,'?')=crS.sp AND k.clms_decile=crS.vd
               AND coalesce(k.partd_state,'?')=crS.st
WHERE k.is_kaiser GROUP BY 1 HAVING count(*)>=100 ORDER BY n DESC;

-- State-group export for figure 1.
-- NOTE ON NORMALISATION: state groups MUST be scored against the NATIONAL
-- expectation. Scoring a state against its own state's baseline is circular and
-- returns 1.0 by construction. Organizations in the same figure are scored
-- state-relative (Phase W W5), so the two marker families use different
-- denominators. Figure 1 says so explicitly; do not compare them numerically.
COPY (
  SELECT grp AS state_group, count(*) AS n_mddo,
    round(avg((k.n_fnb5>0)::INT)/avg(crN.p_fnb),4) AS ratio_fnb,
    round(avg(k.any_non::INT)/avg(crN.p_non),4)    AS ratio_non
  FROM (SELECT *, CASE WHEN is_kaiser THEN NULL
          WHEN partd_state IN ('VT','MN','ME','MA') THEN 'Gift-ban states (VT, MN, ME, MA)'
          WHEN partd_state IN ('WA','OR','WI')      THEN 'Empirically similar (WA, OR, WI)'
          WHEN partd_state IN ('MS','AL','TX')      THEN 'Low-restriction states (MS, AL, TX)'
          ELSE NULL END AS grp FROM k) k
  JOIN crN ON coalesce(k.partd_specialty,'?')=crN.sp AND k.clms_decile=crN.vd
  WHERE grp IS NOT NULL GROUP BY grp
) TO 'figures/data/discriminant_states.csv' (HEADER, DELIMITER ',');

-- Per-organization export for figure 1.
COPY (
  SELECT k.org_primary AS org_pac_id, any_value(k.org_primary_name) AS org_name,
    count(*) AS n_mddo, mode(k.partd_state) AS state, any_value(k.is_kaiser) AS is_kaiser,
    round(avg((k.n_fnb5>0)::INT)/avg(crS.p_fnb),4) AS ratio_fnb,
    round(avg(k.any_non::INT)/avg(crS.p_non),4)    AS ratio_non
  FROM k JOIN crS ON coalesce(k.partd_specialty,'?')=crS.sp AND k.clms_decile=crS.vd
                 AND coalesce(k.partd_state,'?')=crS.st
  WHERE k.org_primary IS NOT NULL GROUP BY k.org_primary HAVING count(*)>=100
) TO 'figures/data/discriminant_orgs.csv' (HEADER, DELIMITER ',');
