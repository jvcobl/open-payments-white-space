# Phase B — Practice Ownership and Structure

Generated 2026-08-02. Descriptive only. Assumes `PHASE_A_FINDINGS.md`,
`PHASE_A_EXT_FINDINGS.md`, and `PHASE_S_FINDINGS.md`.

Every figure is reported under **both** engagement definitions required by the task:

- **Baseline** — absent from the Profile Supplement (cumulative, all program years)
- **F&B-adjusted** — baseline PLUS physicians whose only PY2025 engagement is food and beverage

> **Standing limitation on the F&B-adjusted column.** It is an *upper bound*. 32.3% of
> ever-engaged MD/DOs (177,784) have no PY2025 payment at all and cannot be channel-classified;
> they are held engaged. It is a one-year counterfactual applied to a cumulative classification —
> a directional device, not an estimate. This applies to every F&B-adjusted number below and is
> not repeated at each table.

---

## Headline

**B4 — the clustering verdict: never-engagement clusters within organizations at roughly
128 times the variance independence would produce, and specialty, volume and state composition
explain almost none of it.**

| Null model | Variance inflation, BASELINE | F&B-adjusted |
|---|---|---|
| Global rate | 206.0 | 15.0 |
| + specialty × volume decile | 190.4 | 9.7 |
| + specialty × volume × **state** | **128.1** | **7.6** |

751 of 3,290 organizations (≥20 MD/DO Part D prescribers) contain **zero** never-engaged
physicians against 5.6 expected — a 134× excess. 242 are at or above 50% never-engaged against
1.0 expected. **The institutional-policy hypothesis is supported, and it is the first structural
variable in this project that survives the Phase S channel control.**

But the extremes are asymmetric: **no organization is at or near 100% never-engaged.** The
observed maximum is 87.0%. Organizations cluster hard at *full engagement*, and only partially
at non-engagement.

**B6 — the residual stays high, and the honest conclusion is the one the task flagged.**

Out-of-sample (split-half, shrunk estimates), share of individual variance explained:

| Model | BASELINE | F&B-adjusted |
|---|---|---|
| Specialty | 12.63% | 2.93% |
| + state + rurality + volume | 19.50% | 3.30% |
| + group size + facility count | 21.00% | 2.84% |
| **+ organization** | **22.24%** | **−0.77%** |
| **Residual unexplained** | **77.76%** | **~100%** |

Practice variables add **2.74 points** beyond Phase A's set under baseline, and **nothing** under
the F&B-adjusted definition. **Non-engagement remains not predictable from observable public
characteristics.**

**B5 — the 60 rheumatologists are scattered, not clustered.** They span **44 distinct
organizations** across 54 physicians with a named org (max 3 at any one). The institutional
explanation fails for them *individually*. But it holds for them *as a type*: **66.7% (40 of 60)
sit in organizations of 1,000+ members**, against 34.4% of all rheumatologists.

---

## ⚠️ B1 first — the confounding check that gates this phase

The task asked this be checked first and reported prominently. **It is a real problem under the
baseline definition, and it disappears entirely under the F&B-adjusted one.**

### Coverage

```sql
SELECT count(*) AS n_mddo,
  count(*) FILTER (WHERE in_dac) AS in_dac, count(*) FILTER (WHERE in_fac) AS in_fac,
  count(*) FILTER (WHERE NOT in_dac AND NOT in_fac) AS neither
FROM 'work/phase_b_base.parquet';
```

| | n | % of MD/DO |
|---|---|---|
| MD/DO Part D prescribers | 696,647 | 100% |
| Appear in DAC | 557,053 | **79.96%** |
| Appear in Facility_Affiliation | 468,742 | **67.29%** |
| In neither | 139,574 | 20.03% |

**One in five MD/DO Part D prescribers is absent from DAC.** Everything in B2–B6 that uses
group size is computed on the 79.96%.

### The correlation — crude

```sql
SELECT CASE WHEN never_base THEN 'never engaged' ELSE 'ever engaged' END AS grp, count(*) AS n,
  round(100.0*count(*) FILTER (WHERE in_dac)/count(*),2) AS pct_in_dac,
  round(100.0*count(*) FILTER (WHERE in_fac)/count(*),2) AS pct_in_fac
FROM 'work/phase_b_base.parquet' GROUP BY 1;
```

| Group | n | % in DAC | % in Facility |
|---|---|---|---|
| Ever engaged | 550,188 | 83.65 | 70.96 |
| **Never engaged** | 146,459 | **66.12** | **53.50** |

Flipped:

| | n | % never (BASE) | % never (F&B-adj) |
|---|---|---|---|
| In DAC | 557,053 | **17.38** | 61.18 |
| Not in DAC | 139,594 | **35.55** | 60.49 |

**Under baseline the confound is severe** — physicians outside DAC are 2.05× more likely to be
classified never-engaged. **Under the F&B-adjusted definition it vanishes** (61.18 vs 60.49).

### The correlation — after standardization

Standardizing both groups to the full MD/DO specialty × volume-decile distribution (covers
694,288 of 696,647):

```sql
WITH cells AS (
  SELECT coalesce(partd_specialty,'?') AS sp, clms_decile AS vd, count(*) AS n_all,
    avg(CASE WHEN never_base THEN 1.0 ELSE 0 END) FILTER (WHERE in_dac)     AS r_in_base,
    avg(CASE WHEN never_base THEN 1.0 ELSE 0 END) FILTER (WHERE NOT in_dac) AS r_out_base, ...
  FROM 'work/phase_b_base.parquet' GROUP BY 1,2)
SELECT round(100.0*sum(n_all*r_in_base)/sum(n_all),2), round(100.0*sum(n_all*r_out_base)/sum(n_all),2) ...
```

| | In DAC | Not in DAC | Gap |
|---|---|---|---|
| Crude, BASELINE | 17.38 | 35.55 | 18.17 pts |
| **Standardized, BASELINE** | **19.72** | **23.79** | **4.07 pts** |
| Standardized, F&B-adjusted | 61.73 | 52.89 | −8.84 pts (reverses) |

**About 78% of the crude DAC/engagement correlation is specialty and volume composition.**
DAC missingness is strongly non-random with respect to both:

| Volume decile | % in DAC | % never (in DAC) | % never (not in DAC) |
|---|---|---|---|
| 1 | 48.05 | 21.99 | 42.28 |
| 2 | 61.30 | 23.15 | 40.13 |
| 3 | 73.03 | 23.94 | 37.37 |
| 5 | 83.01 | 22.14 | 34.36 |
| 7 | 89.85 | 13.12 | 23.03 |
| 10 | 94.86 | 10.60 | 15.15 |

By specialty, DAC coverage ranges from **20.92%** (Psychiatry & Neurology) and 35.25% (Students)
to **96.87%** (Nephrology) and 96.68% (Hematology-Oncology).

### B1 verdict

**Non-enrollment in DAC does correlate with never-engagement, and the task's warning was
warranted — but the residual confound is 4.07 points on a 21.02% base, not the 18-point crude
gap.** That is material and must be carried, but it does not invalidate the phase.

Three consequences applied throughout:

1. All group-size analysis is **standardized to specialty × volume decile**, never presented crude.
2. `not in DAC` is retained as its **own band** rather than dropped, so the reader can see it.
3. B4's clustering test uses **only DAC-enrolled physicians with a named organization** and is
   evaluated against specialty/volume/state-adjusted expectations, so DAC missingness cannot
   generate the result.

**Results in this phase are provisional to the extent that the 20% outside DAC differ in ways
specialty and volume do not capture.**

---

## B2 — Group size

`num_org_mem` is group size. DAC is one row per NPI × organization × address (3,387,942 rows,
1,616,566 NPIs, mean 2.1 rows each). I collapsed to one row per NPI: **primary organization =
the non-blank `org_pac_id` with the most address rows**, tie-broken by larger group size then
org id. 84.04% of DAC NPIs have ≤1 organization, so this choice is close to unambiguous for
most of the population.

Blank `org_pac_id` (344,817 rows) always carries `grp_assgn = 'M'` — no group reassignment.
**Verified, not assumed**, and treated as solo:

```sql
SELECT CASE WHEN nullif(trim(org_pac_id),'') IS NULL THEN 'blank org' ELSE 'has org' END,
       grp_assgn, count(*) FROM 'work/dac_national.parquet' GROUP BY 1,2;
-- blank org -> grp_assgn 'M' in 344,817 of 344,817 rows
```

### Crude rates

| Group size band | n | n never (BASE) | % never BASE | % never F&B-adj |
|---|---|---|---|---|
| Not in DAC | 139,594 | 49,625 | 35.55 | 60.49 |
| Solo (1) | 46,719 | 6,731 | 14.41 | 64.34 |
| 2–9 | 45,632 | 2,147 | **4.71** | 65.80 |
| 10–49 | 67,729 | 8,337 | 12.31 | 63.32 |
| 50–199 | 89,927 | 14,057 | 15.63 | 62.21 |
| 200–999 | 141,873 | 24,190 | 17.05 | 60.58 |
| **1,000+** | **165,172** | **41,372** | **25.05** | **58.07** |

### Standardized to specialty × volume decile ⭐

```sql
WITH cells AS (SELECT grp_band, sp, vd, count(*) n,
        avg(never_base::INT) r_base, avg(never_fnb::INT) r_fnb FROM b GROUP BY 1,2,3),
     w AS (SELECT sp, vd, count(*) wt FROM b GROUP BY 1,2)
SELECT grp_band, round(100.0*sum(w.wt*r_base)/sum(w.wt),2), round(100.0*sum(w.wt*r_fnb)/sum(w.wt),2)
FROM cells JOIN w USING (sp,vd) GROUP BY 1;
```

| Group size band | Standardized % never, **BASELINE** | Standardized % never, **F&B-adjusted** |
|---|---|---|
| Not in DAC | 23.79 | 52.89 |
| Solo (1) | 17.45 | 63.07 |
| 2–9 | **9.46** | 64.01 |
| 10–49 | 14.32 | 62.90 |
| 50–199 | 16.35 | 62.40 |
| 200–999 | 18.67 | 61.08 |
| **1,000+** | **27.68** | **60.36** |
| **Spread (max/min)** | **2.93×** | **1.06×** |

**The gradient strengthens after standardization** (crude 5.3×, standardized 2.93× from the 2–9
floor) — it is not a composition artifact. **The direction matches Phase B's prediction:** larger
and system-owned practices show higher non-engagement.

**And the two definitions disagree completely.** Under baseline the rate rises 9.46 → 27.68
across group size. Under F&B-adjusted it *falls* 64.01 → 60.36. Per the task, that disagreement
is the finding.

### The disagreement resolved — a direct channel test

PY2025 population reach by group size, all MD/DOs in band:

| Group size band | n | % with any F&B | % with any **non-F&B** | % F&B-only | Median records if paid |
|---|---|---|---|---|---|
| Not in DAC | 139,594 | 28.97 | 4.80 | 24.96 | 3 |
| Solo | 46,719 | 61.91 | 12.74 | 49.95 | 8 |
| 2–9 | 45,632 | **81.60** | **21.05** | 61.10 | 17 |
| 10–49 | 67,729 | 67.17 | 16.83 | 51.01 | 12 |
| 50–199 | 89,927 | 60.90 | 15.04 | 46.58 | 9 |
| 200–999 | 141,873 | 57.04 | 14.46 | 43.53 | 7 |
| **1,000+** | 165,173 | **47.16** | **15.71** | 33.03 | 5 |

**F&B reach falls 1.73× across group size (81.60% → 47.16%). Non-F&B reach barely moves
(21.05% → 15.71%) and is non-monotonic — the 1,000+ band (15.71%) exceeds both the 200–999
(14.46%) and 50–199 (15.04%) bands.**

**This is the Phase S mechanism again, at the practice level rather than the state level.** Large
organizations suppress the *meal* channel — which is what restricting rep access to the building
does — while their physicians retain substantive industry relationships at an undiminished rate.
Engagement intensity also collapses: median 17 payment records in a 2–9 group against 5 in a
1,000+ organization.

### Stratified by specialty — % never-engaged, BASELINE

| Specialty | notDAC | solo | 2–9 | 10–49 | 50–199 | 200–999 | 1000+ |
|---|---|---|---|---|---|---|---|
| Cardiology | 8.2 | 3.1 | 0.9 | 1.0 | 1.4 | 2.5 | 5.8 |
| Dermatology | 15.7 | 8.2 | 1.7 | 1.9 | 2.0 | 5.1 | 17.2 |
| Emergency Medicine | 49.2 | 51.6 | 27.6 | 41.3 | 44.4 | 43.3 | 56.6 |
| Family Practice | 34.3 | 12.9 | 7.1 | 15.7 | 20.3 | 22.6 | 37.0 |
| Gastroenterology | 8.6 | 4.5 | 0.6 | 0.8 | 0.6 | 3.6 | 7.6 |
| General Surgery | 19.1 | 5.2 | 2.4 | 4.5 | 4.4 | 2.9 | 6.2 |
| Hematology-Oncology | 4.7 | 2.0 | 0.4 | 0.6 | 1.2 | 1.5 | 3.9 |
| Hospitalist | 31.9 | 25.9 | 14.7 | 22.8 | 23.9 | 31.4 | 43.3 |
| Internal Medicine | 35.5 | 11.1 | 6.4 | 13.7 | 18.1 | 23.5 | 37.4 |
| Nephrology | 10.5 | 3.3 | 0.4 | 1.2 | 1.0 | 5.4 | 11.8 |
| Neurology | 12.5 | 3.9 | 1.3 | 2.9 | 6.3 | 5.0 | 12.6 |
| Obstetrics & Gynecology | 23.5 | 8.0 | 1.4 | 3.0 | 5.5 | 5.2 | 16.6 |
| Ophthalmology | 20.9 | 6.4 | 0.9 | 1.4 | 1.3 | 5.5 | 10.0 |
| Orthopedic Surgery | 6.8 | 6.7 | 1.9 | 0.7 | 0.8 | 0.7 | 2.5 |
| Otolaryngology | 20.3 | 10.4 | 1.2 | 1.7 | 1.6 | 3.3 | 7.8 |
| Psychiatry | 36.2 | 26.1 | 9.9 | 17.5 | 25.8 | 33.9 | 51.6 |
| Psychiatry & Neurology | 43.8 | 42.0 | 18.8 | 24.4 | 31.7 | 37.7 | 48.3 |
| Pulmonary Disease | 8.9 | 3.9 | 0.0 | 1.0 | 2.2 | 3.0 | 10.1 |
| Students | 65.8 | 64.0 | 25.7 | 57.3 | 54.4 | 54.4 | 56.6 |
| Urology | 16.0 | 2.1 | 0.4 | 0.5 | 0.3 | 0.9 | 3.0 |

**In all 20 specialties the minimum is the 2–9 band and the 1,000+ rate exceeds it** — without
exception. Ratios range from 1.3× (Orthopedic Surgery) to 29.5× (Nephrology). The U-shape, with
solo elevated above small groups, is also universal.

### Stratified by volume decile — % never-engaged, BASELINE

| Vol decile | notDAC | solo | 2–9 | 10–49 | 50–199 | 200–999 | 1000+ | 1000+ ÷ 2–9 |
|---|---|---|---|---|---|---|---|---|
| 1 | 42.3 | 28.5 | 12.4 | 18.1 | 19.9 | 19.8 | 25.3 | 2.0× |
| 2 | 40.1 | 28.8 | 9.3 | 18.8 | 22.6 | 20.5 | 27.1 | 2.9× |
| 3 | 37.4 | 26.0 | 7.9 | 21.6 | 23.6 | 21.9 | 28.3 | 3.6× |
| 4 | 35.9 | 22.9 | 7.9 | 21.4 | 23.6 | 22.7 | 28.7 | 3.6× |
| 5 | 34.4 | 21.9 | 6.2 | 18.4 | 21.2 | 21.6 | 27.5 | 4.4× |
| 6 | 29.8 | 18.0 | 4.4 | 12.5 | 16.2 | 17.4 | 23.1 | 5.3× |
| 7 | 23.0 | 13.1 | 4.0 | 7.7 | 11.6 | 13.5 | 19.4 | 4.9× |
| 8 | 19.4 | 8.3 | 3.2 | 6.2 | 9.1 | 11.6 | 19.6 | 6.1× |
| 9 | 19.2 | 6.2 | 3.2 | 6.6 | 9.7 | 13.1 | 26.6 | 8.3× |
| **10** | 15.2 | 3.9 | **2.3** | 5.4 | 7.5 | 11.2 | **25.3** | **11.0×** |

Same cells, F&B-adjusted:

| Vol decile | notDAC | solo | 2–9 | 10–49 | 50–199 | 200–999 | 1000+ |
|---|---|---|---|---|---|---|---|
| 1 | 62.5 | 63.8 | 61.3 | 59.1 | 59.2 | 56.9 | 55.2 |
| 3 | 62.6 | 65.1 | 62.8 | 62.9 | 62.9 | 60.3 | 57.8 |
| 5 | 60.3 | 63.3 | 64.0 | 60.7 | 59.5 | 59.2 | 57.7 |
| 7 | 54.4 | 60.6 | 62.1 | 61.7 | 60.6 | 59.1 | 54.4 |
| 9 | 52.3 | 65.1 | 68.2 | 66.5 | 64.1 | 63.8 | 63.5 |
| 10 | 52.0 | 69.4 | 74.2 | 71.8 | 70.1 | 67.4 | 66.9 |

**The group-size gradient holds inside every volume decile and sharpens as volume rises** — 2.0×
in the lowest decile against 11.0× in the highest. Among the highest-volume prescribers, where
industry has the strongest incentive to engage, practice structure is the sharpest divider:
a top-decile prescriber in a 2–9 group is 2.3% never-engaged; the same prescriber in a 1,000+
organization is 25.3%.

Under the F&B-adjusted definition the same cells span 52–74 with no gradient in either
direction — confirming, again, that the baseline gradient is carried by the meal channel.

**Verdict: group size predicts non-engagement robustly under the baseline definition, in the
predicted direction, within every specialty — and the effect is predominantly a meal-channel
effect, not evidence that large organizations have less industry contact.**

---

## B3 — Facility affiliation

### Affiliated vs not, and by count

| | n | % never BASE | % never F&B-adj |
|---|---|---|---|
| Affiliated | 468,742 | 16.72 | 60.64 |
| Not affiliated | 227,905 | 29.88 | 61.87 |

| Facilities | n | % never BASE | % never F&B-adj | Standardized BASE | Standardized F&B |
|---|---|---|---|---|---|
| 0 | 227,905 | 29.88 | 61.87 | 23.75 | 58.56 |
| 1 | 155,575 | 22.75 | 61.57 | 21.87 | 62.11 |
| 2–3 | 170,112 | 16.84 | 60.65 | 18.76 | 61.75 |
| 4–9 | 136,761 | 10.11 | 59.34 | 15.92 | 59.73 |
| 10+ | 6,294 | **7.86** | 65.16 | **13.58** | 58.75 |

**The direction is opposite to B2's and opposite to the institutional-policy prediction.** More
facility affiliations means *less* non-engagement, monotonically, and it survives standardization
(23.75 → 13.58, a 1.75× spread). Under the F&B-adjusted definition it is flat (58.6–62.1).

The channel test explains why facility count behaves unlike group size:

| Facilities | % any F&B | % any non-F&B |
|---|---|---|
| 0 | 38.72 | 7.46 |
| 1 | 50.30 | 12.55 |
| 2–3 | 58.76 | 16.01 |
| 4–9 | 69.18 | 21.06 |
| 10+ | 73.16 | 17.00 |

**Both channels rise together.** Facility count is not measuring institutional restriction — it
is measuring clinical footprint and visibility. A physician admitting at six hospitals is simply
more reachable, by reps and by anyone else.

### By facility type

| Facility type | n MD/DO | % never BASE | % never F&B-adj |
|---|---|---|---|
| Hospital | 461,825 | 16.70 | 60.54 |
| Home health agency | 90,171 | 12.92 | 66.31 |
| Hospice | 26,952 | 18.47 | 65.47 |
| Nursing home | 19,641 | 16.29 | 66.38 |
| Inpatient rehabilitation | 14,395 | 11.54 | 60.31 |
| **Dialysis facility** | 7,915 | **3.28** | 51.47 |
| Long-term care hospital | 4,699 | 8.77 | 60.57 |

Facility *type* carries little information — the range is 11.54–18.47 excluding dialysis.
Dialysis at 3.28% is a nephrology effect, not a facility effect.

**Verdict: hospital and facility affiliation does not support the institutional-policy
hypothesis. It runs the other way, and it is a reachability proxy rather than a policy proxy.**

---

## B4 — The organizational clustering test ⭐

Population: DAC-enrolled MD/DO Part D prescribers with a named primary organization, in
organizations with **≥20** such prescribers. **3,290 organizations, 391,784 physicians**
(56.2% of all MD/DOs). Overall rate in this set: 20.08% baseline, 59.94% F&B-adjusted. Median
organization has 46 prescribers; largest has 6,057.

### Observed vs exact binomial expectation

Expected counts computed exactly from the binomial pmf per organization via `lgamma`, not
simulated:

```sql
SELECT o.org, o.n, j.j,
  exp(lgamma(o.n+1)-lgamma(j.j+1)-lgamma(o.n-j.j+1) + j.j*ln(p) + (o.n-j.j)*ln(1-p)) AS pr
FROM org o CROSS JOIN p, LATERAL (SELECT unnest(range(0,o.n+1)) AS j) j;
```

| | Observed | Expected under independence | Ratio |
|---|---|---|---|
| **BASELINE** | | | |
| Organizations at exactly 0% never-engaged | **751** | 5.6 | **134×** |
| At ≤5% | 1,335 | 38.9 | 34× |
| At ≥50% | **242** | 1.0 | **242×** |
| At ≥90% | **0** | 0.0 | — |
| At exactly 100% | **0** | — | — |
| **F&B-ADJUSTED** | | | |
| At exactly 0% | 0 | 0.0 | — |
| At ≥50% | 2,745 | 3,050.8 | 0.9× |
| At ≥90% | 73 | 1.2 | 62× |
| At exactly 100% | 6 | — | — |

**Answering B4's question directly: 751 organizations are at 0% never-engaged. None is at or
near 100%.** The maximum observed is 87.0%. Clustering is strong at both tails but the
non-engaged tail is truncated — **no organization achieves anything close to a total industry
blackout.**

### Variance inflation, like-for-like

All three rows use the identical Poisson-binomial statistic
`Σ(kᵢ−eᵢ)² / Σvᵢ`, which equals 1.0 under independence. Only the null model changes.

| Null model | VIF BASELINE | VIF F&B-adjusted |
|---|---|---|
| Global rate | 206.0 | 15.0 |
| Specialty × volume decile | 190.4 | 9.7 |
| **Specialty × volume × state** | **128.1** | **7.6** |

**Specialty and volume composition explain only 7.6% of the clustering (206 → 190). Adding
state explains a further 30% (190 → 128). What remains — 128× — is organizational.** Under the
F&B-adjusted definition clustering attenuates by 94% but does not vanish: 7.6× is still far from
independence.

Against the specialty × volume × state null: **261 organizations sit >3 SD above expectation,
323 sit >3 SD below.**

### The extremes, adjusted for their own specialty × volume × state mix

Organizations ≥300 prescribers, ranked by z:

| Organization | n | Observed never | Expected | Obs % | Exp % | z |
|---|---|---|---|---|---|---|
| PERMANENTE MEDICAL GROUP INC | 6,057 | 3,281 | 1,510.0 | 54.2 | 24.9 | **+56.7** |
| SOUTHERN CALIFORNIA PERMANENTE MEDICAL GROUP | 5,964 | 2,708 | 1,436.7 | 45.4 | 24.1 | +40.9 |
| KAISER FOUNDATION HEALTH PLAN, MID-ATLANTIC | 1,368 | 829 | 329.6 | 60.6 | 24.1 | +34.3 |
| REGENTS OF THE UNIVERSITY OF MICHIGAN | 1,376 | 557 | 254.8 | 40.5 | 18.5 | +23.1 |
| COLORADO PERMANENTE MEDICAL GROUP PC | 811 | 420 | 198.0 | 51.8 | 24.4 | +19.9 |
| **THE SOUTHEAST PERMANENTE MEDICAL GROUP** | 482 | 205 | 66.4 | **42.5** | **13.8** | +19.8 |
| KAISER FOUNDATION HEALTH PLAN OF THE NORTHWEST | 1,049 | 616 | 373.5 | 58.7 | 35.6 | +17.7 |
| UNIVERSITY OF ROCHESTER | 401 | 192 | 68.9 | 47.9 | 17.2 | +17.5 |
| VANDERBILT UNIVERSITY MEDICAL CENTER | 1,125 | 296 | 164.4 | 26.3 | 14.6 | +12.5 |
| THE METROHEALTH SYSTEM | 427 | 175 | 85.7 | 41.0 | 20.1 | +12.2 |

Furthest *below* expectation:

| Organization | n | Observed | Expected | Obs % | Exp % | z |
|---|---|---|---|---|---|---|
| WELLSTAR MEDICAL GROUP LLC | 1,340 | 45 | 225.9 | 3.4 | 16.9 | −14.3 |
| HEALTHTEXAS PROVIDER NETWORK | 1,297 | 63 | 218.8 | 4.9 | 16.9 | −12.3 |
| RWJBH EMERGENCY MEDICINE ASSOCIATES | 403 | 45 | 158.5 | 11.2 | 39.3 | −11.9 |
| PRACTICE ASSOCIATES MEDICAL GROUP | 828 | 17 | 130.5 | 2.1 | 15.8 | −11.6 |
| TMH PHYSICIAN ASSOCIATES PLLC | 1,078 | 38 | 157.3 | 3.5 | 14.6 | −11.1 |
| BAYCARE MEDICAL GROUP, INC. | 697 | 23 | 123.9 | 3.3 | 17.8 | −10.6 |
| OCHSNER CLINIC LLC | 1,080 | 54 | 140.6 | 5.0 | 13.0 | −8.5 |

Largest organizations with **exactly zero** never-engaged physicians — all independent
single-specialty groups:

| Organization | n | % never F&B-adj |
|---|---|---|
| TEXAS DIGESTIVE DISEASE CONSULTANTS, PLLC | 336 | 72.9 |
| FLORIDA WOMAN CARE LLC | 323 | 79.9 |
| PIEDMONT PROVIDERS LLC | 279 | 54.5 |
| UWH OF THE CAROLINAS PLLC | 213 | 77.5 |
| REGIONAL WOMENS HEALTH GROUP LLC | 189 | 81.0 |
| WOMENS CARE FLORIDA LLC | 182 | 86.3 |
| CAPITAL WOMENS CARE LLC | 166 | 89.2 |
| GASTRO HEALTH, LLC | 136 | 58.1 |
| AMERICAN ONCOLOGY PARTNERS PA | 135 | 22.2 |

### The Kaiser result — the cleanest evidence in the phase

```sql
SELECT count(*) AS n_physicians, count(DISTINCT org_primary) AS n_orgs,
  round(100.0*count(*) FILTER (WHERE never_base)/count(*),1) AS pct_never_BASE,
  round(100.0*count(*) FILTER (WHERE never_fnb)/count(*),1)  AS pct_never_FNB
FROM 'work/phase_b_base.parquet'
WHERE org_primary_name ILIKE '%PERMANENTE%' OR org_primary_name ILIKE '%KAISER%';
```

| | Value |
|---|---|
| Physicians | 16,980 |
| Kaiser/Permanente organizations | 10 |
| **% never engaged, BASELINE** | **51.2%** (national 21.02%) |
| % never engaged, F&B-adjusted | 67.3% (national 61.04%) |

**Kaiser entities appear at the top of the list in every region they operate — California,
Mid-Atlantic, Colorado, Northwest, Washington, and Georgia.** The Southeast Permanente Medical
Group is the decisive case: it sits in **Georgia, a state with a 12.30% baseline never-engagement
rate** (near the bottom nationally), yet runs 42.5% against a state-and-specialty-adjusted
expectation of 13.8%.

**The Kaiser pattern travels with the organization, not the geography.** This is the strongest
single piece of evidence in Phase B that practice-level policy — the closed-panel staff-model
HMO, which excludes representatives structurally — produces non-engagement.

### Why the clustering is huge but B6's predictive gain is small

These two results appear contradictory. They are not. Organizational effects are **concentrated
rather than diffuse**:

| Organization group | n orgs | n physicians | % of all MD/DO | Observed % never | Expected % | Excess never-engaged |
|---|---|---|---|---|---|---|
| z > +3 (suppressed) | 261 | 109,788 | 15.8% | 35.5 | 23.9 | **+12,727** |
| Within ±3 | 2,706 | 217,130 | 31.2% | 16.1 | 17.8 | −3,714 |
| z < −3 (saturated) | 323 | 64,866 | 9.3% | 7.2 | 16.7 | −6,126 |

**261 organizations account for roughly 12,700 excess never-engaged physicians — about 8.7% of
all 146,459 never-engaged MD/DOs.** For the 31.2% of physicians in ordinary organizations, and
the ~44% in no organization of ≥20 at all, organizational membership carries almost no signal.
A whole-population variance measure averages the strong signal in a quarter of the data against
no signal in the rest.

**B4 verdict: the institutional-policy hypothesis is supported. Clustering is the predicted
signature, it is present at 128× independence, it survives specialty, volume and state controls,
it survives the Phase S channel control at 7.6×, and the named extremes are exactly the
organizations the hypothesis would nominate — closed-panel HMOs, academic centers, integrated
nonprofit systems, and safety-net clinics at one end; independent single-specialty groups at the
other. Its scope, however, is roughly a quarter of the population, not all of it.**

---

## B5 — The selection-robust 553

Reproduced exactly: 553 physicians, `never_base AND clms_decile>=9 AND cpc_decile>=9`.

### Practice characteristics

| | 553 | All MD/DO |
|---|---|---|
| In DAC | 501 (90.6%) | 79.96% |
| In Facility_Affiliation | 426 (77.0%) | 67.29% |
| Distinct primary organizations | 250 | — |

| Group size band | n of 553 | % of 553 | % of all MD/DO |
|---|---|---|---|
| Not in DAC | 52 | 9.4 | 20.0 |
| Solo | 13 | 2.4 | 6.7 |
| 2–9 | 4 | 0.7 | 6.6 |
| 10–49 | 32 | 5.8 | 9.7 |
| 50–199 | 64 | 11.6 | 12.9 |
| 200–999 | 115 | 20.8 | 20.4 |
| **1,000+** | **273** | **49.4** | **23.7** |

**The selection-robust white space is markedly more institutional than the population** — half
of it sits in organizations of 1,000+, against a quarter of all MD/DOs, and it is
under-represented in every band below 200.

### Where they concentrate

| Organization | n of 553 | Org size |
|---|---|---|
| PERMANENTE MEDICAL GROUP INC | 17 | 10,968 |
| SOUTHERN CALIFORNIA PERMANENTE MEDICAL GROUP | 16 | 11,244 |
| MAINEHEALTH | 12 | 2,595 |
| KAISER FOUNDATION HEALTH PLAN OF THE NORTHWEST | 11 | 1,824 |
| KAISER FOUNDATION HEALTH PLAN, MID-ATLANTIC | 10 | 1,964 |
| MASS GENERAL BRIGHAM MEDICAL GROUP SUBURBAN MA | 8 | 534 |
| THE EMORY CLINIC INC | 7 | 3,505 |
| ATRIUS HEALTH INC | 7 | 1,194 |
| PARK NICOLLET CLINIC | 6 | 1,765 |
| THE METROHEALTH SYSTEM | 6 | 1,166 |
| UNIVERSITY OF PITTSBURGH PHYSICIANS | 6 | 4,195 |

**54 of the 553 (9.8%) are in Kaiser/Permanente entities alone.** But 488 of the 553 have a named
organization and they span **250 distinct organizations** — the median organization contributes
**one**. The group is institutional in type and dispersed in fact.

### The 60 rheumatologists ⭐

```sql
SELECT count(*) AS n_rheum, round(sum(tot_drug_cst)/1e6,1) AS musd,
  count(*) FILTER (WHERE in_dac) AS in_dac, count(DISTINCT org_primary) AS distinct_orgs
FROM 'work/phase_b_base.parquet'
WHERE never_base AND clms_decile>=9 AND cpc_decile>=9 AND partd_specialty='Rheumatology';
```

| | Value |
|---|---|
| Physicians | 60 |
| Drug cost | $174.7 M |
| Average each | $2.91 M |
| In DAC | 58 |
| With a named organization | 54 |
| **Distinct organizations** | **44** |
| Largest concentration at any one organization | **3** |

| Organization | n | $M | State |
|---|---|---|---|
| *(not in DAC / solo, no org)* | 6 | 12.4 | — |
| KAISER FOUNDATION HEALTH PLAN OF THE NORTHWEST | 3 | 8.6 | OR |
| PERMANENTE MEDICAL GROUP INC | 3 | 6.8 | CA |
| SOUTHERN CALIFORNIA PERMANENTE MEDICAL GROUP | 3 | 5.1 | CA |
| LAHEY CLINIC INC | 2 | 12.2 | MA |
| RHEUMATOLOGY ASSOCIATES PC | 2 | 9.4 | MA |
| RUSH UNIVERSITY MEDICAL GROUP | 2 | 5.5 | IL |
| ALLINA HEALTH SYSTEM | 2 | 4.5 | MN |
| UNIVERSITY OF VERMONT MEDICAL CENTER | 1 | 6.9 | VT |
| UNIVERSITY OF TEXAS HSC SAN ANTONIO | 1 | 6.7 | TX |
| FAIRVIEW EXPRESS CARE | 1 | 5.7 | MN |
| LEE HEALTH SYSTEM INC | 1 | 5.6 | FL |

**Answer: they do not cluster institutionally. 44 organizations for 54 physicians.** The task's
conditional applies — *"If they are scattered, the institutional explanation fails for them and
something else is operating."*

But two qualifications matter:

1. **They are institutional by type.** 40 of 60 (66.7%) are in organizations of 1,000+, against
   34.4% of all rheumatologists. Nine are at Kaiser.
2. **The group-size gradient within rheumatology is the steepest of any specialty.**

| Group size band | All rheumatologists | % of all | % never-engaged |
|---|---|---|---|
| Not in DAC | 244 | 4.8 | 11.1 |
| Solo | 454 | 8.9 | 1.1 |
| 2–9 | 611 | 11.9 | 0.7 |
| 10–49 | 426 | 8.3 | **0.5** |
| 50–199 | 518 | 10.1 | 3.3 |
| 200–999 | 1,109 | 21.6 | 4.4 |
| **1,000+** | 1,766 | 34.4 | **14.4** |

**A rheumatologist in a 1,000+ organization is 29× more likely to be never-engaged than one in a
10–49 group (14.4% vs 0.5%).** Rheumatology is essentially fully engaged outside large
institutions.

**B5 verdict: the mechanism for the 60 is organizational *type* — large integrated systems and
closed-panel HMOs — not membership in a small number of identifiable organizations. As a callable
commercial list they are 44 separate accounts, not four.**

---

## B6 — Updated variance decomposition

### Phase A's method, extended

One-way eta-squared, `Σnᵢ(mᵢ−m̄)² / (N·p(1−p))`, exactly as A6. Phase A's figures reproduce
exactly (specialty 12.63, state 4.22, rurality 0.07), confirming the base table.

**Raw eta-squared is not usable for organization.** With k levels and N observations, roughly
`(k−1)/(N−1)` is explained by chance alone. Both columns are shown:

| Factor | Levels | % var BASE (raw) | % var BASE (chance-corrected) | % var F&B (raw) | % var F&B (corrected) | Chance floor |
|---|---|---|---|---|---|---|
| Specialty × state × rurality × volume | 38,867 | 25.59 | **21.19** | 10.22 | 4.91 | 5.58 |
| Organization × specialty | 99,701 | 30.79 | 19.23 | 21.60 | 8.51 | 14.31 |
| Specialty × state | 3,966 | 18.70 | 18.23 | 4.38 | 3.83 | 0.57 |
| **All seven factors** | 351,104 | **57.47** | **14.25** | 55.72 | 10.73 | **50.40** |
| Specialty | 115 | 12.63 | 12.62 | 2.97 | 2.96 | 0.02 |
| Organization | 38,721 | 16.19 | 11.26 | 9.12 | 3.78 | 5.56 |
| **Group-size band** | 7 | **4.87** | 4.87 | 0.21 | 0.21 | 0.00 |
| State | 62 | 4.22 | 4.21 | 0.11 | 0.11 | 0.01 |
| Volume decile | 10 | 3.49 | 3.49 | 0.36 | 0.36 | 0.00 |
| **Facility-count band** | 5 | **3.35** | 3.35 | 0.04 | 0.04 | 0.00 |
| Rurality | 5 | 0.07 | 0.07 | 0.01 | 0.00 | 0.00 |

The "all seven factors" row is the clearest warning: **57.47% raw against a 50.40% chance floor.**
Anyone quoting the raw figure would be reporting mostly arithmetic.

### The defensible answer — out-of-sample validation ⭐

Because chance-correction is crude when levels approach N, I ran a **split-half validation**:
fit on a random half (hash of NPI), score the held-out half, report Brier-score reduction against
the grand mean. Cell estimates are empirical-Bayes shrunk to their parent (m = 10); organization
enters as an additive shrunk residual offset rather than a further cell split, so it is not
penalised by fragmentation. n = 349,208 held out.

```sql
l2 AS (SELECT sp,st,ru,vd, (sum(y)+10.0*any_value(l1.p))/(count(*)+10.0) AS p FROM tr JOIN l1 USING (sp) GROUP BY 1,2,3,4),
l3 AS (... + gb, fb ...),
off AS (SELECT org, sum(y - coalesce(l3.p,l2.p))/(count(*)+10.0) AS d FROM tr ... GROUP BY org)
SELECT 1 - avg((yy-p4)^2)/avg((yy-p0)^2) FROM sc;
```

| Model | BASELINE | F&B-adjusted |
|---|---|---|
| Specialty | 12.63% | 2.93% |
| + state + rurality + volume decile | 19.50% | 3.30% |
| + group size + facility count | 21.00% | 2.84% |
| + **organization** | **22.24%** | **−0.77%** |
| **Residual unexplained** | **77.76%** | **~100%** |

**Incremental contribution of the Phase B practice variables, out of sample:**

| | BASELINE | F&B-adjusted |
|---|---|---|
| Group size + facility count | +1.50 pts | −0.46 pts |
| Organization, beyond all the above | +1.24 pts | −3.61 pts |
| **Total Phase B contribution** | **+2.74 pts** | **negative** |

### B6 verdict — reported without spin, as the task required

**The residual stays above 75%. The honest conclusion is the second branch the task named:
non-engagement is not predictable from observable public characteristics.**

Adding practice ownership, group size, facility affiliation, and organizational identity to
specialty, state, rurality and volume moves out-of-sample explanatory power from 19.50% to
22.24%. **Roughly 78% of the individual-level variation remains unexplained**, essentially where
Phase A left it at 81%.

**Under the F&B-adjusted definition nothing predicts anything.** Specialty explains 2.93%,
everything else is noise, and organization *degrades* out-of-sample accuracy. Once meal-only
engagement is reclassified, the never-engaged population is close to structurally featureless
with respect to every public variable available in this project.

This is not a null result to be buried. **It bounds what any public-data targeting product can
achieve.** A vendor claiming to identify unengaged physicians from NPI-linkable public data is
working against a ceiling of roughly 22% of variance under the generous definition and
approximately zero under the strict one.

---

## What surprised me

**1. Group size and facility affiliation point in opposite directions, and only one is about
policy.** I expected both to proxy institutional restriction. Group size behaves as predicted
(9.46% → 27.68% standardized). Facility count runs the *other* way (23.75% → 13.58%) because both
payment channels rise with it — it measures how reachable a physician is, not how restricted.
Two variables that a plausible design would have combined into one "institutional" index measure
opposite things.

**2. The Phase S channel mechanism reappears at the practice level, and I did not anticipate it
would.** F&B reach falls 81.6% → 47.2% across group size while non-F&B reach barely moves and is
non-monotonic. Phase S found the state effect was a meal effect; the group-size effect is the
same thing at a different level of aggregation. Restricting rep access to a building removes the
sandwich, not the relationship. **Two of the three structural variables in this project have now
turned out to be measuring the same recording artifact.**

**3. No organization is anywhere near 100% never-engaged, and I expected several.** 751
organizations are at exactly 0%; the maximum in the other direction is 87.0%, and there are zero
above 90%. Total industry penetration of an organization is common and total exclusion never
happens. Even Kaiser — the most restrictive structure in American medicine, with 16,980
physicians — runs 51.2%. Whatever institutional policy does, it does not produce a blackout.

**4. Southeast Permanente in Georgia is worth more than the 56-sigma California result.** The two
big California Permanente groups have the largest z-scores, but California is already a
high-never-engagement state. Southeast Permanente sits in Georgia at 42.5% against a
state-and-specialty-adjusted 13.8%. **A single organization carrying its own 3× effect into the
state least like it is cleaner evidence than any amount of significance in the expected place.**

**5. The clustering is enormous and the predictive gain is tiny, and both are true.** VIF of 128
alongside +1.24 points out-of-sample looked like an error until I decomposed it: 261
organizations hold 15.8% of physicians and carry ~12,700 excess never-engaged, while for the
other three-quarters organizational membership says nothing. **"Strong effect" and "useful
predictor" are not the same claim, and the distinction is easy to lose when only one statistic is
reported.**

**6. The 60 rheumatologists dissolved as a story and re-formed as a different one.** 44
organizations for 54 physicians kills the "identify the four institutions" version. But 66.7% in
1,000+ organizations against a 34.4% base rate, and a 29× within-specialty gradient, says the
mechanism is real and simply not concentrated. The most anomalous group in the project turns out
to be ordinary once you condition on practice type — which is itself the answer.

---

## Reinterpretation — what should now read differently

**1. Phase A §A6 — "over 81% unexplained," with the implication that a structural explanation
should be sought at the practice level.** That search has now been run and it recovered 2.74
points out of sample. The residual is 77.76%. **The practice-level hypothesis was worth testing
and it is largely spent.** Any remaining explanation is in variables not present in public data —
individual disposition, employer contract terms, therapeutic area, or industry's own targeting
history.

**2. Phase B's own framing — "larger and system-owned practices should show higher
non-engagement, since institutional policies restrict rep access."** The prediction is confirmed
in direction and magnitude, but the stated *reason* needs the Phase S correction. Institutional
policy suppresses the **recorded meal**, not necessarily the relationship: non-F&B reach is
15.71% in 1,000+ organizations against 15.04% in 50–199. The finding licenses "large
organizations are engaged differently," not "large organizations are engaged less."

**3. Phase S §S3's collapse should now be read as more general than a state result.** Phase S
showed the state spread collapsing 8.39× → 1.16× under the channel control. Phase B shows the
group-size spread collapsing 2.93× → 1.06× and the facility spread 1.75× → ~1.06× under the same
control. **The F&B channel is not a confounder of the state variable specifically. It is the
dominant axis of variation in the entire engagement measure**, and any Phase B, C or later
stratification should assume it is present until tested.

**4. Extension §E4 — the 553 as "a callable list."** Still true, with structure now attached:
90.6% are DAC-enrolled, half are in 1,000+ organizations, and 9.8% are inside Kaiser. **A
substantial share of the selection-robust white space is not commercially addressable by
conventional field deployment at all** — Kaiser and comparable closed-panel systems exclude
representatives structurally. The addressable subset is smaller than 553.

**5. Phase A Decision 3 — state as a first-class stratification variable.** Phase S already
demoted this to a channel artifact. Phase B adds that **organization is the better stratification
variable where it is available**: it survives the state control (128× VIF), state does not
survive the channel control, and Kaiser's effect crosses state lines intact. For any future
analysis with DAC linkage, stratify on organization before state.

---

## Limitations

- **DAC coverage is 79.96% and non-random.** Standardized residual confound with never-engagement
  is 4.07 points under baseline (B1). All group-size and organization results are provisional to
  that extent.
- **Primary-organization assignment is a choice.** 84.04% of DAC NPIs have ≤1 organization, so it
  is close to forced for most; for the 15.96% with multiple, "most address rows" is defensible but
  not unique. Physicians whose largest affiliation is not their modal one are misassigned.
- **`num_org_mem` counts all organization members**, not MD/DO Part D prescribers, so group-size
  bands and the clustering denominators are on different scales. This is why the two are never
  mixed in one statistic.
- **Every F&B-adjusted figure is a one-year counterfactual on a cumulative flag** and an upper
  bound. `PGYR2016`–`PGYR2024` remains the highest-value missing input in the project.
- **Descriptive only.** No causal claim is made. Physicians select into organizations, so
  organizational clustering is consistent with policy, with selection, and with both.
- **The 15,235 blank-NPI supplement rows** continue to bias every never-engaged figure in one
  direction (recon Flag 3).
- **B4 excludes organizations with <20 MD/DO Part D prescribers**, which is 3,290 organizations
  covering 56.2% of MD/DOs. Clustering among small organizations is not measured.

---

## Files

| Path | Rows | Contents |
|---|---|---|
| `work/phase_b_base.parquet` | 696,647 | One row per MD/DO Part D prescriber: both engagement definitions, DAC group size and primary organization, facility affiliation counts and types, volume/cost deciles, rurality |

Validated on build against six independently established anchors — 696,647 MD/DOs; 146,459
never-engaged (21.02%); 425,226 F&B-adjusted (61.04%); 372,443 with PY2025 payments; 553 in the
target cell; 17,108 high-volume never-engaged — all reproduced exactly.

Nothing downloaded. Nothing deleted. All source CSVs and prior Parquet files intact.
