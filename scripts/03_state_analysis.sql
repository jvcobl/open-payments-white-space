-- ─────────────────────────────────────────────────────────────────────────────
-- 03_state_analysis.sql
--
-- PRODUCES : state-level never-engaged rates under both definitions; dispersion
--            (max/min, SD, CV); Spearman rank correlation; the volume gradient
--            used by figures/fig3_volume_gradient.py
-- SOURCE   : PHASE_A_FINDINGS.md §A5, §A3; PHASE_S_FINDINGS.md §S3;
--            PHASE_R_FINDINGS.md §R1
-- INPUTS   : work/analysis_base.parquet
--
-- The headline correction this reproduces: Phase S computed the counterfactual
-- on ONE program year and reported the state rank ordering dissolving
-- (Spearman rho = 0.121). On five years rho = 0.845 — the magnitude compresses,
-- the ordering survives. Mississippi ranks 40 of 52, not 2.
-- ─────────────────────────────────────────────────────────────────────────────
SET memory_limit='9GB'; SET threads=3;

CREATE OR REPLACE TEMP TABLE st AS
SELECT partd_state AS state, count(*) AS n,
  count(*) FILTER (WHERE never_base) AS k_base,
  count(*) FILTER (WHERE never_fnb5) AS k_cf5,
  100.0*count(*) FILTER (WHERE never_base)/count(*) AS p_base,
  100.0*count(*) FILTER (WHERE never_fnb5)/count(*) AS p_cf5
FROM 'work/analysis_base.parquet'
WHERE partd_state IS NOT NULL GROUP BY 1 HAVING count(*)>=500;

.print '--- national ---'
SELECT count(*) AS mddo,
  count(*) FILTER (WHERE never_base) AS never_base,
  round(100.0*count(*) FILTER (WHERE never_base)/count(*),2) AS pct_base,
  count(*) FILTER (WHERE never_fnb5) AS never_fnb5,
  round(100.0*count(*) FILTER (WHERE never_fnb5)/count(*),2) AS pct_fnb5
FROM 'work/analysis_base.parquet';

.print '--- dispersion across states (n>=500) ---'
SELECT count(*) AS n_states,
  round(max(p_base),2) AS base_max, round(min(p_base),2) AS base_min,
  round(max(p_base)/min(p_base),2) AS base_ratio,
  round(stddev_samp(p_base),2) AS base_sd,
  round(stddev_samp(p_base)/avg(p_base),3) AS base_cv,
  round(max(p_cf5),2) AS adj_max, round(min(p_cf5),2) AS adj_min,
  round(max(p_cf5)/min(p_cf5),2) AS adj_ratio,
  round(stddev_samp(p_cf5),2) AS adj_sd,
  round(stddev_samp(p_cf5)/avg(p_cf5),3) AS adj_cv
FROM st;

.print '--- Spearman rho, baseline vs five-year adjusted ranking ---'
WITH r AS (SELECT rank() OVER (ORDER BY p_base) rb, rank() OVER (ORDER BY p_cf5) r5 FROM st)
SELECT round(corr(rb,r5),3) AS spearman_rho FROM r;

.print '--- full state table ---'
SELECT state, n, round(p_base,2) AS baseline, round(p_cf5,2) AS adjusted_5yr,
  rank() OVER (ORDER BY p_base DESC) AS rank_base,
  rank() OVER (ORDER BY p_cf5 DESC)  AS rank_adj
FROM st ORDER BY p_cf5 DESC;

.print '--- channel composition by state (feeds figure 2) ---'
SELECT partd_state AS state, count(*) AS n,
  round(100.0*count(*) FILTER (WHERE n_fnb5>0)/count(*),2)                     AS pct_any_fnb,
  round(100.0*count(*) FILTER (WHERE cell4='1 fully engaged')/count(*),2)      AS pct_fully_engaged,
  round(100.0*count(*) FILTER (WHERE cell4='2 meal-only')/count(*),2)          AS pct_meal_only,
  round(100.0*count(*) FILTER (WHERE cell4='3 relationship-only')/count(*),2)  AS pct_relationship_only,
  round(100.0*count(*) FILTER (WHERE cell4='4 no record')/count(*),2)          AS pct_no_record
FROM 'work/analysis_base.parquet'
WHERE partd_state IS NOT NULL GROUP BY 1 HAVING count(*)>=500 ORDER BY pct_any_fnb;

.print '--- never-engaged by volume decile, both definitions (feeds figure 3) ---'
SELECT clms_decile AS volume_decile, count(*) AS n,
  min(tot_clms) AS clms_min, max(tot_clms) AS clms_max,
  round(100.0*count(*) FILTER (WHERE never_base)/count(*),2) AS pct_never_baseline,
  round(100.0*count(*) FILTER (WHERE never_fnb5)/count(*),2) AS pct_never_adjusted
FROM 'work/analysis_base.parquet' GROUP BY 1 ORDER BY 1;

-- exports consumed by the figure scripts
COPY (
  SELECT partd_state AS state, count(*) AS n,
    round(100.0*count(*) FILTER (WHERE n_fnb5>0)/count(*),3)                    AS pct_any_fnb,
    round(100.0*count(*) FILTER (WHERE cell4='1 fully engaged')/count(*),3)     AS pct_fully_engaged,
    round(100.0*count(*) FILTER (WHERE cell4='2 meal-only')/count(*),3)         AS pct_meal_only,
    round(100.0*count(*) FILTER (WHERE cell4='3 relationship-only')/count(*),3) AS pct_relationship_only,
    round(100.0*count(*) FILTER (WHERE cell4='4 no record')/count(*),3)         AS pct_no_record
  FROM 'work/analysis_base.parquet'
  WHERE partd_state IS NOT NULL GROUP BY 1 HAVING count(*)>=500 ORDER BY pct_any_fnb
) TO 'figures/data/state_channel.csv' (HEADER, DELIMITER ',');

COPY (
  SELECT clms_decile AS volume_decile, count(*) AS n,
    min(tot_clms) AS clms_min, max(tot_clms) AS clms_max,
    round(100.0*count(*) FILTER (WHERE never_base)/count(*),3) AS pct_never_baseline,
    round(100.0*count(*) FILTER (WHERE never_fnb5)/count(*),3) AS pct_never_adjusted
  FROM 'work/analysis_base.parquet' GROUP BY 1 ORDER BY 1
) TO 'figures/data/volume_gradient.csv' (HEADER, DELIMITER ',');
