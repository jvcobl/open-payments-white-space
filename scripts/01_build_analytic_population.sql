-- ─────────────────────────────────────────────────────────────────────────────
-- 01_build_analytic_population.sql
--
-- PRODUCES : work/nppes_slim.parquet          (NPPES reduced to 13 used fields)
--            work/analytic_population.parquet (one row per Part D 2024 NPI)
-- SOURCE   : PHASE_A_FINDINGS.md §A1
-- INPUTS   : work/nppes_npidata.parquet, work/partd_2024.parquet,
--            work/op_profile_supplement.parquet
--
-- The one subtlety worth reading: NPPES stores up to 15 taxonomy slots and marks
-- the primary with "Primary Taxonomy Switch_N". 14.5% of individuals have their
-- primary outside slot 1, so using Taxonomy Code_1 as "primary specialty" — the
-- obvious reading — misclassifies 41,643 MD/DO Part D prescribers. tax_slot1 is
-- carried alongside so the earlier (incorrect) figure stays reproducible.
--
-- never_engaged derives from the Profile Supplement, NOT from any payment file.
-- Phase W verified the supplement is comprehensive across all three Open
-- Payments categories (general, research, ownership).
-- ─────────────────────────────────────────────────────────────────────────────
SET memory_limit='9GB';
SET threads=3;
SET preserve_insertion_order=false;

COPY (
  SELECT
    NPI AS npi,
    "Entity Type Code" AS entity_type,
    nullif(trim("Healthcare Provider Taxonomy Code_1"),'') AS tax_slot1,
    COALESCE(
      CASE
        WHEN "Healthcare Provider Primary Taxonomy Switch_1"='Y'  THEN nullif(trim("Healthcare Provider Taxonomy Code_1"),'')
        WHEN "Healthcare Provider Primary Taxonomy Switch_2"='Y'  THEN nullif(trim("Healthcare Provider Taxonomy Code_2"),'')
        WHEN "Healthcare Provider Primary Taxonomy Switch_3"='Y'  THEN nullif(trim("Healthcare Provider Taxonomy Code_3"),'')
        WHEN "Healthcare Provider Primary Taxonomy Switch_4"='Y'  THEN nullif(trim("Healthcare Provider Taxonomy Code_4"),'')
        WHEN "Healthcare Provider Primary Taxonomy Switch_5"='Y'  THEN nullif(trim("Healthcare Provider Taxonomy Code_5"),'')
        WHEN "Healthcare Provider Primary Taxonomy Switch_6"='Y'  THEN nullif(trim("Healthcare Provider Taxonomy Code_6"),'')
        WHEN "Healthcare Provider Primary Taxonomy Switch_7"='Y'  THEN nullif(trim("Healthcare Provider Taxonomy Code_7"),'')
        WHEN "Healthcare Provider Primary Taxonomy Switch_8"='Y'  THEN nullif(trim("Healthcare Provider Taxonomy Code_8"),'')
        WHEN "Healthcare Provider Primary Taxonomy Switch_9"='Y'  THEN nullif(trim("Healthcare Provider Taxonomy Code_9"),'')
        WHEN "Healthcare Provider Primary Taxonomy Switch_10"='Y' THEN nullif(trim("Healthcare Provider Taxonomy Code_10"),'')
        WHEN "Healthcare Provider Primary Taxonomy Switch_11"='Y' THEN nullif(trim("Healthcare Provider Taxonomy Code_11"),'')
        WHEN "Healthcare Provider Primary Taxonomy Switch_12"='Y' THEN nullif(trim("Healthcare Provider Taxonomy Code_12"),'')
        WHEN "Healthcare Provider Primary Taxonomy Switch_13"='Y' THEN nullif(trim("Healthcare Provider Taxonomy Code_13"),'')
        WHEN "Healthcare Provider Primary Taxonomy Switch_14"='Y' THEN nullif(trim("Healthcare Provider Taxonomy Code_14"),'')
        WHEN "Healthcare Provider Primary Taxonomy Switch_15"='Y' THEN nullif(trim("Healthcare Provider Taxonomy Code_15"),'')
      END,
      nullif(trim("Healthcare Provider Taxonomy Code_1"),'')      -- fallback
    ) AS tax_primary,
    upper(trim(coalesce("Provider Credential Text",''))) AS credential_raw,
    upper(regexp_replace(coalesce("Provider Credential Text",''),'[^A-Za-z]','','g')) AS credential_norm,
    nullif(trim("Provider Business Practice Location Address State Name"),'') AS nppes_state,
    left(regexp_replace(coalesce("Provider Business Practice Location Address Postal Code",''),'[^0-9]','','g'),5) AS nppes_zip5,
    nullif(trim("Provider Enumeration Date"),'') AS enumeration_date,
    nullif(trim("NPI Deactivation Date"),'')     AS deactivation_date,
    nullif(trim("Provider Sex Code"),'')         AS sex_code,
    nullif(trim("Is Sole Proprietor"),'')        AS is_sole_proprietor
  FROM 'work/nppes_npidata.parquet'
) TO 'work/nppes_slim.parquet' (FORMAT PARQUET, COMPRESSION ZSTD, ROW_GROUP_SIZE 100000);

COPY (
WITH sup AS (
  SELECT DISTINCT Covered_Recipient_NPI AS npi
  FROM 'work/op_profile_supplement.parquet'
  WHERE trim(coalesce(Covered_Recipient_NPI,'')) <> ''
),
base AS (
  SELECT
    p.PRSCRBR_NPI                              AS npi,
    p.Prscrbr_Ent_Cd                           AS partd_entity_cd,
    nullif(trim(p.Prscrbr_Type),'')            AS partd_specialty,
    nullif(trim(p.Prscrbr_Type_src),'')        AS partd_specialty_src,
    nullif(trim(p.Prscrbr_Crdntls),'')         AS partd_credential,
    nullif(trim(p.Prscrbr_State_Abrvtn),'')    AS partd_state,
    nullif(trim(p.Prscrbr_zip5),'')            AS partd_zip5,
    nullif(trim(p.Prscrbr_RUCA),'')            AS partd_ruca,
    nullif(trim(p.Prscrbr_RUCA_Desc),'')       AS partd_ruca_desc,
    TRY_CAST(p.Tot_Clms        AS BIGINT)      AS tot_clms,
    TRY_CAST(p.Tot_Drug_Cst    AS DOUBLE)      AS tot_drug_cst,
    TRY_CAST(p.Tot_Benes       AS BIGINT)      AS tot_benes,
    TRY_CAST(p.Tot_30day_Fills AS DOUBLE)      AS tot_30day_fills,
    TRY_CAST(p.Tot_Day_Suply   AS BIGINT)      AS tot_day_suply,
    n.entity_type                              AS nppes_entity_type,
    n.tax_primary, n.tax_slot1,
    n.credential_raw                           AS nppes_credential,
    n.credential_norm                          AS nppes_credential_norm,
    n.nppes_state, n.nppes_zip5, n.enumeration_date, n.deactivation_date,
    n.sex_code, n.is_sole_proprietor,
    (s.npi IS NOT NULL)                        AS ever_engaged
  FROM 'work/partd_2024.parquet' p
  LEFT JOIN 'work/nppes_slim.parquet' n ON p.PRSCRBR_NPI = n.npi
  LEFT JOIN sup s                          ON p.PRSCRBR_NPI = s.npi
)
SELECT *,
  NOT ever_engaged AS never_engaged,
  (tax_primary LIKE '207%' OR tax_primary LIKE '208%')            AS is_mddo,
  (tax_slot1   LIKE '207%' OR tax_slot1   LIKE '208%')            AS is_mddo_slot1,
  (tax_primary LIKE '363L%' OR tax_primary LIKE '363A%'
     OR tax_primary LIKE '364S%' OR tax_primary LIKE '367%')      AS is_npp,
  (tax_primary LIKE '1835%')                                      AS is_pharmacist_tax,
  (tax_primary LIKE '3902%')                                      AS is_student_tax,
  (partd_specialty = 'Pharmacist')                                AS is_pharmacist_partd,
  (partd_specialty = 'Student in an Organized Health Care Education/Training Program')
                                                                  AS is_student_partd,
  TRY_CAST(right(enumeration_date,4) AS INTEGER)                  AS enum_year,
  (deactivation_date IS NOT NULL)                                 AS nppes_deactivated,
  (tax_primary IS NULL)                                           AS unclassifiable
FROM base
) TO 'work/analytic_population.parquet' (FORMAT PARQUET, COMPRESSION ZSTD, ROW_GROUP_SIZE 100000);

-- Checkpoint: these three must reproduce reconnaissance exactly.
SELECT 'ALL Part D'                  AS denom, count(*) AS n,
       count(*) FILTER (WHERE never_engaged) AS never_engaged,
       round(100.0*count(*) FILTER (WHERE never_engaged)/count(*),2) AS pct
FROM 'work/analytic_population.parquet'
UNION ALL SELECT 'ELIGIBLE', count(*), count(*) FILTER (WHERE never_engaged),
       round(100.0*count(*) FILTER (WHERE never_engaged)/count(*),2)
FROM 'work/analytic_population.parquet' WHERE NOT is_pharmacist_partd AND NOT is_student_partd
UNION ALL SELECT 'MD/DO (slot1, recon method)', count(*), count(*) FILTER (WHERE never_engaged),
       round(100.0*count(*) FILTER (WHERE never_engaged)/count(*),2)
FROM 'work/analytic_population.parquet' WHERE is_mddo_slot1
UNION ALL SELECT 'MD/DO (true primary taxonomy)', count(*), count(*) FILTER (WHERE never_engaged),
       round(100.0*count(*) FILTER (WHERE never_engaged)/count(*),2)
FROM 'work/analytic_population.parquet' WHERE is_mddo;
