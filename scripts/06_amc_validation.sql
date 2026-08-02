-- ─────────────────────────────────────────────────────────────────────────────
-- 06_amc_validation.sql
--
-- PRODUCES : blind validation of the discriminant against the 19 academic
--            medical centers coded by Larkin et al., JAMA 2017;317(17):1785-1795
-- SOURCE   : PHASE_X_FINDINGS.md §X1-X3
-- INPUTS   : work/analysis_base.parquet
-- OUTPUTS  : figures/data/discriminant_amcs.csv (for figure 1)
--
-- The org_pac_id values below are a HAND-BUILT crosswalk, not a verified one.
-- Two caveats travel with it:
--   * New York Medical College is matched to Westchester Medical Center, its
--     principal teaching hospital, NOT the college. Flagged; dropping it moves
--     the median from 1.110 to 1.118.
--   * Four UC campuses are identified by DAC practice city, because several
--     org_pac_ids carry the undifferentiated name "Regents of the University of
--     California". Cities are unambiguous (Los Angeles/Santa Monica -> UCLA,
--     Sacramento -> Davis, San Francisco -> UCSF, San Diego/La Jolla -> UCSD)
--     but this is inference. UC Irvine (Orange, CA) was identified and excluded.
--   * Tufts does not appear: its three organizations total 49 MD/DO Part D
--     prescribers, below the 50 threshold. 18 of 19 institutions matched.
--
-- The discriminant is used exactly as defined in 05_discriminant.sql. It was
-- NOT tuned for this test.
-- ─────────────────────────────────────────────────────────────────────────────
SET memory_limit='9GB'; SET threads=3;

CREATE OR REPLACE TEMP TABLE k AS
SELECT *, (n_nonfnb5>0 OR has_research) AS any_non,
  (org_primary_name ILIKE '%PERMANENTE%' OR org_primary_name ILIKE '%KAISER%') AS is_kaiser
FROM 'work/analysis_base.parquet';
CREATE OR REPLACE TEMP TABLE crS AS
SELECT coalesce(partd_specialty,'?') sp, clms_decile vd, coalesce(partd_state,'?') st,
  avg((n_fnb5>0)::INT) p_fnb, avg(any_non::INT) p_non FROM k GROUP BY 1,2,3;

CREATE OR REPLACE TEMP TABLE amc AS SELECT * FROM (VALUES
  -- all three policy areas (gift + access + enforcement), n = 11 (Tufts unmatched)
  ('1355248584','UCLA','all three'), ('1456255959','UCLA','all three'),
  ('0749180453','UCLA','all three'), ('4587857727','UCLA','all three'),
  ('7416946546','Boston University','all three'),
  ('3072422716','Univ Illinois Chicago','all three'),
  ('0446157747','USC Keck','all three'),
  ('8729990239','Univ Pittsburgh','all three'),
  ('5799699088','Univ Rochester','all three'),
  ('4284539891','Univ Massachusetts','all three'),
  ('5496658874','Rush','all three'),
  ('3173660776','New York Medical College*','all three'),
  ('0749192284','SUNY Downstate','all three'), ('7113318122','SUNY Downstate','all three'),
  -- fewer than three policy areas, n = 8
  ('6709797491','Stanford','fewer'),
  ('4587576814','Northwestern','fewer'),
  ('3375456619','UC Davis','fewer'), ('8022922475','UC Davis','fewer'),
  ('4486567229','UCSF','fewer'), ('5496668410','UCSF','fewer'),
  ('4284547274','UCSF','fewer'), ('6305160300','UCSF','fewer'),
  ('2264691070','Mount Sinai','fewer'), ('8224282926','Mount Sinai','fewer'),
  ('3577476761','UC San Diego','fewer'), ('3971849175','UC San Diego','fewer'),
  ('0345588711','Temple','fewer'), ('2062317233','Temple','fewer'),
  ('7911819180','Thomas Jefferson','fewer')
) AS t(org, inst, policy);

.print '--- X1 match table (verify by hand) ---'
SELECT a.inst, a.policy, any_value(k.org_primary_name) AS matched_organization,
  a.org AS org_pac_id, count(*) AS n_mddo, mode(k.partd_state) AS state
FROM k JOIN amc a ON k.org_primary=a.org
GROUP BY a.inst, a.policy, a.org ORDER BY a.policy, a.inst, n_mddo DESC;

CREATE OR REPLACE TEMP TABLE inst AS
SELECT a.inst AS inst, a.policy AS policy, count(*) AS n_mddo, mode(k.partd_state) AS st,
  avg((k.n_fnb5>0)::INT)/avg(crS.p_fnb) AS r_fnb,
  avg(k.any_non::INT)/avg(crS.p_non)    AS r_non,
  (avg(k.any_non::INT)/avg(crS.p_non))/(avg((k.n_fnb5>0)::INT)/avg(crS.p_fnb)) AS discr
FROM k JOIN crS ON coalesce(k.partd_specialty,'?')=crS.sp AND k.clms_decile=crS.vd
               AND coalesce(k.partd_state,'?')=crS.st
JOIN amc a ON k.org_primary=a.org GROUP BY 1,2;

.print '--- X2 institution-level scores, state-relative ---'
SELECT inst, policy, n_mddo, st, round(r_fnb,3) AS ratio_fnb,
       round(r_non,3) AS ratio_non, round(discr,3) AS discriminant
FROM inst ORDER BY discr DESC;

.print '--- X3 primary test: AMCs vs Kaiser vs reference ---'
SELECT 'AMCs (Larkin et al.)' AS grp, count(*) AS n_units, sum(n_mddo) AS n_physicians,
  round(median(r_fnb),3) AS med_ratio_fnb, round(median(r_non),3) AS med_ratio_non,
  round(median(discr),3) AS median_discriminant,
  round(min(discr),3) AS min_discr, round(max(discr),3) AS max_discr FROM inst
UNION ALL
SELECT 'Kaiser entities', count(*), sum(n), round(median(rf),3), round(median(rn),3),
  round(median(d),3), round(min(d),3), round(max(d),3)
FROM (SELECT count(*) n, avg((k.n_fnb5>0)::INT)/avg(crS.p_fnb) rf,
        avg(k.any_non::INT)/avg(crS.p_non) rn,
        (avg(k.any_non::INT)/avg(crS.p_non))/(avg((k.n_fnb5>0)::INT)/avg(crS.p_fnb)) d
      FROM k JOIN crS ON coalesce(k.partd_specialty,'?')=crS.sp AND k.clms_decile=crS.vd
                     AND coalesce(k.partd_state,'?')=crS.st
      WHERE k.is_kaiser AND k.org_primary IS NOT NULL GROUP BY k.org_primary HAVING count(*)>=100);

.print '--- X3 secondary: does policy strength grade? (expect: no) ---'
SELECT policy, count(*) AS n_institutions, sum(n_mddo) AS n_physicians,
  round(median(discr),3) AS median_discriminant,
  round(min(discr),3) AS min, round(max(discr),3) AS max,
  count(*) FILTER (WHERE discr>1) AS n_above_1
FROM inst GROUP BY 1
UNION ALL SELECT 'ALL matched AMCs', count(*), sum(n_mddo), round(median(discr),3),
  round(min(discr),3), round(max(discr),3), count(*) FILTER (WHERE discr>1) FROM inst;

COPY (SELECT inst AS institution, policy, n_mddo, st AS state,
        round(r_fnb,4) AS ratio_fnb, round(r_non,4) AS ratio_non, round(discr,4) AS discriminant
      FROM inst ORDER BY discr DESC)
TO 'figures/data/discriminant_amcs.csv' (HEADER, DELIMITER ',');
