-- ─────────────────────────────────────────────────────────────────────────────
-- 04_organization_analysis.sql
--
-- PRODUCES : organizational clustering (variance inflation vs three null models),
--            observed-vs-expected extremes, the group-size gradient
-- SOURCE   : PHASE_B_FINDINGS.md §B2, §B4; PHASE_R_FINDINGS.md §R3
-- INPUTS   : work/analysis_base.parquet
--
-- The clustering statistic is Poisson-binomial variance inflation,
--   VIF = sum((k_i - e_i)^2) / sum(v_i),
-- which equals 1.0 under independence regardless of null model. Only the
-- expectation changes between rows, so the three numbers are directly
-- comparable — an equal-weight eta-squared and a size-weighted VIF are NOT
-- comparable, which is why a single statistic is used throughout.
--
-- Note on eta-squared elsewhere: with k levels and N observations roughly
-- (k-1)/(N-1) is explained by chance alone. For organization (38,721 levels)
-- that floor is 5.6%, and for the full interaction it is 50.4%. Raw eta-squared
-- on high-cardinality factors is not usable; see PHASE_R §R3 for the
-- out-of-sample alternative.
-- ─────────────────────────────────────────────────────────────────────────────
SET memory_limit='9GB'; SET threads=3;

CREATE OR REPLACE TEMP TABLE b AS
SELECT *, CASE WHEN NOT in_dac THEN '0 notDAC'
   WHEN grp_size=1   THEN '1 solo'   WHEN grp_size<=9   THEN '2 2-9'
   WHEN grp_size<=49 THEN '3 10-49'  WHEN grp_size<=199 THEN '4 50-199'
   WHEN grp_size<=999 THEN '5 200-999' ELSE '6 1000+' END AS grp_band
FROM 'work/analysis_base.parquet';

-- expectations under three null models
CREATE OR REPLACE TEMP TABLE cr2 AS
SELECT coalesce(partd_specialty,'?') sp, clms_decile vd,
  avg(never_base::INT) pb, avg(never_fnb5::INT) p5 FROM b GROUP BY 1,2;
CREATE OR REPLACE TEMP TABLE cr3 AS
SELECT coalesce(partd_specialty,'?') sp, clms_decile vd, coalesce(partd_state,'?') st,
  avg(never_base::INT) pb, avg(never_fnb5::INT) p5 FROM b GROUP BY 1,2,3;

CREATE OR REPLACE TEMP TABLE o AS
SELECT b.org_primary AS org, any_value(b.org_primary_name) AS org_name, count(*) AS n,
  count(*) FILTER (WHERE b.never_base) AS kb, count(*) FILTER (WHERE b.never_fnb5) AS k5,
  count(*)*avg(g.pb) AS e0b, count(*)*avg(g.pb)*(1-avg(g.pb)) AS v0b,
  count(*)*avg(g.p5) AS e05, count(*)*avg(g.p5)*(1-avg(g.p5)) AS v05,
  sum(cr2.pb) e2b, sum(cr2.pb*(1-cr2.pb)) v2b, sum(cr2.p5) e25, sum(cr2.p5*(1-cr2.p5)) v25,
  sum(cr3.pb) e3b, sum(cr3.pb*(1-cr3.pb)) v3b, sum(cr3.p5) e35, sum(cr3.p5*(1-cr3.p5)) v35
FROM b
CROSS JOIN (SELECT avg(never_base::INT) pb, avg(never_fnb5::INT) p5 FROM b
            WHERE in_dac AND org_primary IS NOT NULL) g
JOIN cr2 ON coalesce(b.partd_specialty,'?')=cr2.sp AND b.clms_decile=cr2.vd
JOIN cr3 ON coalesce(b.partd_specialty,'?')=cr3.sp AND b.clms_decile=cr3.vd
        AND coalesce(b.partd_state,'?')=cr3.st
WHERE b.in_dac AND b.org_primary IS NOT NULL
GROUP BY 1 HAVING count(*)>=20;

.print '--- organizational clustering: variance inflation (1.0 = independence) ---'
SELECT 'global rate' AS null_model, count(*) AS n_orgs, sum(n) AS n_physicians,
  round(sum((kb-e0b)^2)/sum(v0b),1) AS VIF_baseline,
  round(sum((k5-e05)^2)/sum(v05),1) AS VIF_adjusted FROM o
UNION ALL SELECT 'specialty x volume', count(*), sum(n),
  round(sum((kb-e2b)^2)/sum(v2b),1), round(sum((k5-e25)^2)/sum(v25),1) FROM o
UNION ALL SELECT 'specialty x volume x state', count(*), sum(n),
  round(sum((kb-e3b)^2)/sum(v3b),1), round(sum((k5-e35)^2)/sum(v35),1) FROM o;

.print '--- observed vs exact binomial expectation at the extremes (baseline) ---'
WITH p AS (SELECT sum(kb)::DOUBLE/sum(n) AS pr FROM o),
pmf AS (SELECT o.org, o.n, j.j,
          exp(lgamma(o.n+1)-lgamma(j.j+1)-lgamma(o.n-j.j+1)
              + j.j*ln(p.pr) + (o.n-j.j)*ln(1-p.pr)) AS pr
        FROM o CROSS JOIN p, LATERAL (SELECT unnest(range(0,o.n+1)) AS j) j)
SELECT (SELECT count(*) FROM o WHERE kb=0)               AS obs_at_0pct,
       round((SELECT sum(pr) FROM pmf WHERE j=0),1)      AS exp_at_0pct,
       (SELECT count(*) FROM o WHERE kb::DOUBLE/n>=0.50) AS obs_at_50pct_plus,
       round((SELECT sum(pr) FROM pmf WHERE j>=0.50*n),1) AS exp_at_50pct_plus,
       (SELECT count(*) FROM o WHERE kb::DOUBLE/n>=0.90) AS obs_at_90pct_plus;

.print '--- organizations furthest above expectation (specialty x volume x state) ---'
SELECT org_name, n, kb AS observed_never, round(e3b,1) AS expected,
  round(100.0*kb/n,1) AS obs_pct, round(100.0*e3b/n,1) AS exp_pct,
  round((kb-e3b)/sqrt(v3b),1) AS z
FROM o WHERE n>=300 ORDER BY z DESC LIMIT 12;

.print '--- group-size gradient, standardized to specialty x volume ---'
WITH cells AS (SELECT grp_band, coalesce(partd_specialty,'?') sp, clms_decile vd, count(*) n,
   avg(never_base::INT) rb, avg(never_fnb5::INT) r5,
   avg((n_fnb5>0)::INT) f5, avg((n_nonfnb5>0 OR has_research)::INT) nf5 FROM b GROUP BY 1,2,3),
w AS (SELECT coalesce(partd_specialty,'?') sp, clms_decile vd, count(*) wt FROM b GROUP BY 1,2)
SELECT c.grp_band, sum(c.n) AS n,
  round(100.0*sum(w.wt*c.rb)/sum(w.wt),2)  AS std_never_baseline,
  round(100.0*sum(w.wt*c.r5)/sum(w.wt),2)  AS std_never_adjusted,
  round(100.0*sum(w.wt*c.f5)/sum(w.wt),2)  AS std_pct_any_fnb,
  round(100.0*sum(w.wt*c.nf5)/sum(w.wt),2) AS std_pct_any_nonfnb
FROM cells c JOIN w USING (sp,vd) GROUP BY 1 ORDER BY 1;

.print '--- Kaiser under both definitions ---'
SELECT count(*) AS n_physicians, count(DISTINCT org_primary) AS n_orgs,
  round(100.0*count(*) FILTER (WHERE never_base)/count(*),1) AS pct_never_baseline,
  round(100.0*count(*) FILTER (WHERE never_fnb5)/count(*),1) AS pct_never_adjusted
FROM b WHERE org_primary_name ILIKE '%PERMANENTE%' OR org_primary_name ILIKE '%KAISER%';
