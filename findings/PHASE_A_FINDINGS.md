# Phase A Findings — Characterizing the Never-Engaged Population

Generated 2026-08-02. Descriptive analysis only — no models, no causal claims.

Tooling: DuckDB v1.5.5 CLI over the Parquet files in `work/`. Source CSVs untouched, nothing
downloaded, nothing deleted.

---

## Headline

### The three denominators

| Denominator | Prescribers | Never engaged | Share |
|---|---|---|---|
| All Part D 2024 prescribers | 1,416,883 | 332,718 | 23.48% |
| Eligible (excl. pharmacists + students) | 1,317,858 | 254,254 | 19.29% |
| **MD/DO — primary anchor** | **696,647** | **146,459** | **21.02%** |

The first two reproduce reconnaissance exactly. **The MD/DO figure does not**, and the reason
is a methodology correction, not a data change — see Contradiction 1 below. Recon's number was
655,004 / 135,160 / 20.63%.

### The A3 finding

**17,108 never-engaged MD/DOs sit in the top two prescribing-volume deciles** (≥2,370 Part D
claims in 2024).

| | Value |
|---|---|
| High-volume never-engaged MD/DOs | **17,108** |
| Their Part D claims | **97,886,665** |
| Their Part D drug cost | **$8.21 B** |
| Share of all MD/DO claims | **8.12%** |
| Share of all MD/DO drug cost | **3.89%** |
| Share of *all* Part D claims (any prescriber) | 5.72% |
| Share of *all* Part D drug cost | 2.85% |

For scale, all Part D 2024 is 1.71 billion claims and $288.4 billion.

**This is not near zero.** These are 11.68% of never-engaged MD/DOs but they account for
**71.55% of all never-engaged MD/DO claims** and 60.5% of their drug cost. The white space is
concentrated: a small, identifiable group of high-volume physicians carries most of it. The
commercial premise of the project survives.

**But read it with the qualifier in the next line.** Never-engaged MD/DOs prescribe at roughly
**half the drug cost per claim** of engaged peers, and that ratio holds in every single volume
decile (0.38–0.69, no exceptions). So the white space is real in *volume* but materially
cheaper per script. The 8.12%-of-claims / 3.89%-of-cost gap is that fact showing up in the
headline. Any commercial sizing that uses claims will overstate the opportunity roughly 2× versus
one that uses drug spend. This was not anticipated by the task list and I think it is the second
most important result in Phase A.

### Contradictions and deviations

**Contradiction 1 — the MD/DO denominator is larger than recon reported (+41,643).**
Recon Q7 classified physicians using `Healthcare Provider Taxonomy Code_1`. But NPPES stores
up to 15 taxonomy slots and marks the primary one with `Primary Taxonomy Switch_N = 'Y'` — and
**1,071,079 of 7,372,909 NPPES individuals (14.5%) have their primary taxonomy in a slot other
than slot 1.** Using slot 1 as "primary" therefore misclassifies a real population. Using the
true primary taxonomy, MD/DO Part D prescribers = **696,647**, not 655,004, and the never-engaged
rate is **21.02%**, not 20.63%. I have anchored on the corrected figure and carried
`is_mddo_slot1` in the analytic table so the recon number remains reproducible. All three recon
figures reproduce exactly under recon's own definition — the checkpoint passed before I changed
anything.

**Contradiction 2 — A2's hypothesis has its premise backwards.** The task predicted NPP
never-engagement is *inflated* relative to MD/DO by the shorter observation window. In the data
NPPs are **less** never-engaged than MD/DOs (20.11% vs 21.02%), despite ~5 program years of
coverage versus ~13. Against a like-for-like primary-care comparison the gap widens to 5.5
points (NPP 20.11% vs MD/DO primary care 25.65%). Correcting for the window artifact would make
this gap *larger*, not smaller. Detail in A2.

**Deviation — A2 cannot be completed with the data on disk.** The proper test needs PY2021+
engagement history; only PY2025 is present. I ran a matched *single-year* window instead and
have labelled it as a bound, not the requested test. Exact files needed are listed in A2.

**Minor — 5,575 Part D prescribers are deactivated NPIs.** Recon's "only 2 Part D NPIs absent
from NPPES" is correct. But a further 5,575 are *present* in NPPES with an
`NPI Deactivation Date` and every attribute field blank. They cannot be assigned a specialty,
state, or population flag. Together 5,577 rows (0.39% of Part D, 5.7M claims) are unclassifiable
and are excluded from every MD/DO figure above.

---

## A1 — Analytic table

Persisted as **`work/analytic_population.parquet`** — 1,416,883 rows, one per NPI, 45 MB.

Built in two steps. First a slim NPPES table deriving the true primary taxonomy:

```sql
COPY (
  SELECT NPI AS npi, "Entity Type Code" AS entity_type,
    nullif(trim("Healthcare Provider Taxonomy Code_1"),'') AS tax_slot1,
    COALESCE(
      CASE
        WHEN "Healthcare Provider Primary Taxonomy Switch_1"='Y'
             THEN nullif(trim("Healthcare Provider Taxonomy Code_1"),'')
        -- ... repeated for slots 2..15 ...
      END,
      nullif(trim("Healthcare Provider Taxonomy Code_1"),'')   -- fallback
    ) AS tax_primary,
    upper(regexp_replace(coalesce("Provider Credential Text",''),'[^A-Za-z]','','g')) AS credential_norm,
    nullif(trim("Provider Business Practice Location Address State Name"),'') AS nppes_state,
    left(regexp_replace(coalesce("Provider Business Practice Location Address Postal Code",''),'[^0-9]','','g'),5) AS nppes_zip5,
    nullif(trim("Provider Enumeration Date"),'') AS enumeration_date,
    nullif(trim("NPI Deactivation Date"),'')     AS deactivation_date,
    nullif(trim("Is Sole Proprietor"),'')        AS is_sole_proprietor
  FROM 'work/nppes_npidata.parquet'
) TO 'work/nppes_slim.parquet' (FORMAT PARQUET, COMPRESSION ZSTD);
```

Then the join:

```sql
WITH sup AS (
  SELECT DISTINCT Covered_Recipient_NPI AS npi
  FROM 'work/op_profile_supplement.parquet'
  WHERE trim(coalesce(Covered_Recipient_NPI,'')) <> ''
)
SELECT p.PRSCRBR_NPI AS npi, ..., (s.npi IS NOT NULL) AS ever_engaged
FROM 'work/partd_2024.parquet' p
LEFT JOIN 'work/nppes_slim.parquet' n ON p.PRSCRBR_NPI = n.npi
LEFT JOIN sup s                        ON p.PRSCRBR_NPI = s.npi;
```

Population flags, all derived from `tax_primary`:

| flag | rule | n |
|---|---|---|
| `is_mddo` | `207%` or `208%` | 696,647 |
| `is_mddo_slot1` | same rule on `tax_slot1` (recon's method, kept for reproducibility) | 655,004 |
| `is_npp` | `363L%` (NP), `363A%` (PA), `364S%` (CNS), `367%` (CNM/CRNA) | 414,906 |
| `is_pharmacist_tax` | `1835%` | 30,989 |
| `is_student_tax` | `3902%` | 63,241 |
| `unclassifiable` | `tax_primary IS NULL` | 5,577 |

`is_pharmacist_partd` / `is_student_partd` are also carried, keyed off Part D `Prscrbr_Type`,
because the "eligible" denominator in recon was defined that way and I wanted it reproducible.

The NPP families were derived empirically by cross-tabulating `Prscrbr_Type` against
`tax_primary` rather than assumed — 363L/363A/364S/367A account for essentially all Part D
prescribers labelled Nurse Practitioner, Physician Assistant, Clinical Nurse Specialist and
Certified Nurse Midwife.

### Checkpoint — passed

```sql
SELECT 'ALL' AS denom, count(*) AS n, count(*) FILTER (WHERE never_engaged) AS never_eng,
       round(100.0*count(*) FILTER (WHERE never_engaged)/count(*),2) AS pct
FROM 'work/analytic_population.parquet'
UNION ALL SELECT 'ELIGIBLE', count(*), count(*) FILTER (WHERE never_engaged), ...
  FROM 'work/analytic_population.parquet' WHERE NOT is_pharmacist_partd AND NOT is_student_partd
UNION ALL SELECT 'MD/DO slot1 (recon method)', ... WHERE is_mddo_slot1;
```

| Denominator | n | never engaged | % | Recon said | Match |
|---|---|---|---|---|---|
| All Part D | 1,416,883 | 332,718 | 23.48 | 23.48 | ✅ exact |
| Eligible | 1,317,858 | 254,254 | 19.29 | 19.29 | ✅ exact |
| MD/DO (slot 1, recon method) | 655,004 | 135,160 | 20.63 | 20.63 | ✅ exact |
| MD/DO (true primary taxonomy) | 696,647 | 146,459 | 21.02 | — | new, corrected |

Row count 1,416,883 matches recon Q2. Zero rows where `ever_engaged = never_engaged`.
`tot_clms` and `tot_drug_cst` are non-null on all 1,416,883 rows (consistent with recon Q8 —
these two measures are never suppressed).

**Caveat.** Every NPI-based engagement flag inherits the 15,235 blank-NPI supplement rows from
recon Flag 3: people who *were* engaged but cannot be joined. That is a one-directional bias
inflating never-engagement by at most 15,235 nationally (≤10.4% of the 146,459 MD/DO figure if
every one were an MD/DO Part D prescriber, which they are not). It cannot be fixed without
profile-ID recovery through the payment files.

---

## A2 — NPP observation-window artifact

### The requested test cannot be run on the data on disk

The test needs engagement restricted to PY2021-and-later. The Profile Supplement is cumulative
with no year column, so recency must come from the dated payment files, and **only PY2025 is on
disk.**

**To run it properly you need:** `OP_DTL_GNRL_PGYR2021`, `PGYR2022`, `PGYR2023`, `PGYR2024`
(General Payments detail, ~6–9 GB each). Strictly, the matching Research and Ownership detail
files for 2021–2025 as well, since a recipient engaged only through research would otherwise be
scored as unengaged in the windowed definition. General Payments alone would cover ~97% of
engaged NPIs (recon Q11) and is sufficient in practice.

### What I ran instead, clearly labelled

A **matched single-year window**: engagement = "received a General Payment in PY2025", applied
identically to both groups. This is *not* the requested PY2021+ test. It is a bound — it shows
what happens when both groups get the same, much shorter window.

```sql
CREATE TEMP VIEW py25 AS SELECT DISTINCT Covered_Recipient_NPI AS npi
  FROM 'work/op_general_py2025.parquet' WHERE trim(coalesce(Covered_Recipient_NPI,''))<>'';
SELECT grp, n, never_cum, round(100.0*never_cum/n,2) AS pct_never_cumulative,
       never_1yr, round(100.0*never_1yr/n,2) AS pct_never_py2025_only
FROM ( SELECT 'MD/DO' AS grp, count(*) AS n,
              count(*) FILTER (WHERE never_engaged) AS never_cum,
              count(*) FILTER (WHERE NOT engaged_py2025) AS never_1yr
       FROM pop WHERE is_mddo
       UNION ALL SELECT 'NPP', count(*), count(*) FILTER (WHERE never_engaged),
              count(*) FILTER (WHERE NOT engaged_py2025) FROM pop WHERE is_npp );
```

| Group | n | Never engaged (cumulative) | Never engaged (PY2025 only) |
|---|---|---|---|
| MD/DO | 696,647 | 146,459 — **21.02%** | 324,204 — 46.54% |
| NPP | 414,906 | 83,428 — **20.11%** | 179,502 — 43.26% |

### The hypothesis's premise does not hold

The hypothesis assumed NPP never-engagement is inflated *above* MD/DO by the short window. It
is not above it — it is **0.91 points below**, on the cumulative definition where MD/DOs enjoy
~13 program years against the NPPs' ~5. Under the matched one-year window MD/DO remains higher
(46.54% vs 43.26%).

Like-for-like is starker. NPPs practise overwhelmingly in primary care; MD/DO as a whole
includes hospital-based specialties with structurally low pharma contact. Restricting the
physician side to primary care:

| Group | n | Never engaged (cumulative) | Never engaged (PY2025 only) |
|---|---|---|---|
| MD/DO primary care (FP + IM + GP) | 251,745 | 64,561 — **25.65%** | 55.21% |
| NPP (all) | 414,906 | 83,428 — **20.11%** | 43.26% |

**Interpretation.** In roughly five years of eligibility, industry has engaged a *larger* share
of non-physician prescribers than it has engaged of comparable primary care physicians in
thirteen. The observation-window artifact is real and does bias against NPPs — which means the
true NPP-versus-physician engagement gap is **wider** than the 5.5 points shown. This is the
opposite sign from what the task anticipated, and it is a substantive finding rather than a
nuisance: NPPs are not the under-reached population, they are the *more*-reached one.

By NPP subtype:

| Subtype | n | Never engaged (cumulative) | PY2025 only |
|---|---|---|---|
| Nurse Practitioner | 274,508 | 19.22% | 42.36% |
| Physician Assistant | 135,104 | 21.91% | 45.06% |
| CNM / CRNA / other 367x | 3,033 | 21.04% | 45.99% |
| Clinical Nurse Specialist | 2,261 | 18.97% | 41.18% |

**Caveats.** The one-year column uses General Payments only, so a 2025 research-only or
ownership-only recipient is miscounted as unengaged in that column — recon Q11 puts this at
~2.6% of engaged NPIs, and it applies to both groups roughly equally. The cumulative column is
unaffected. The ~13-versus-~5 program-year claim is taken from the task document, not verified
against data, since the pre-2025 files are not on disk.

---

## A3 — Volume distribution ⭐

### Distribution, MD/DO, never vs ever engaged

```sql
SELECT CASE WHEN never_engaged THEN 'never engaged' ELSE 'ever engaged' END AS grp,
       count(*) AS n, min(tot_clms) AS min_clms,
       round(quantile_cont(tot_clms,0.10),0) AS p10, round(quantile_cont(tot_clms,0.25),0) AS p25,
       round(quantile_cont(tot_clms,0.50),0) AS median_clms, round(quantile_cont(tot_clms,0.75),0) AS p75,
       round(quantile_cont(tot_clms,0.90),0) AS p90, round(quantile_cont(tot_clms,0.99),0) AS p99,
       max(tot_clms) AS max_clms, round(avg(tot_clms),1) AS mean_clms
FROM 'work/analytic_population.parquet' WHERE is_mddo GROUP BY 1;
```

**Total claims:**

| Group | n | min | p10 | p25 | median | p75 | p90 | p99 | max | mean |
|---|---|---|---|---|---|---|---|---|---|---|
| Ever engaged | 550,188 | 11 | 33 | 108 | **439** | 1,971 | 5,729 | 17,301 | 537,707 | 1,943.6 |
| Never engaged | 146,459 | 11 | 20 | 49 | **166** | 565 | 2,936 | 10,096 | 146,403 | 934.1 |

**Total drug cost:**

| Group | n | p25 | median | p75 | p90 | p99 | mean |
|---|---|---|---|---|---|---|---|
| Ever engaged | 550,188 | $4,539 | **$42,663** | $367,498 | $968,406 | $4,038,591 | $358,700 |
| Never engaged | 146,459 | $1,762 | **$7,907** | $54,282 | $279,677 | $1,080,632 | $92,550 |

Never-engaged physicians are decisively lower-volume — median 166 claims against 439, and
median drug cost 5.4× lower. But the tail is substantial: p99 is 10,096 claims and the maximum
is 146,403. The population is not uniformly marginal.

(`min = 11` for both groups is the CMS suppression floor — Part D excludes prescribers with
fewer than 11 claims, so this file has no true low tail.)

### Never-engaged rate by volume decile

```sql
CREATE TEMP TABLE mddo AS
SELECT *, NTILE(10) OVER (ORDER BY tot_clms) AS clms_decile
FROM 'work/analytic_population.parquet' WHERE is_mddo;

SELECT clms_decile AS decile, count(*) AS n, min(tot_clms) AS clms_min, max(tot_clms) AS clms_max,
       count(*) FILTER (WHERE never_engaged) AS never_engaged,
       round(100.0*count(*) FILTER (WHERE never_engaged)/count(*),2) AS pct_never_engaged,
       sum(tot_clms) AS decile_total_clms, round(sum(tot_drug_cst)/1e9,3) AS decile_total_cost_bn
FROM mddo GROUP BY 1 ORDER BY 1;
```

| Decile | n | Claims range | Never engaged | % never | Decile claims | Decile cost |
|---|---|---|---|---|---|---|
| 1 | 69,665 | 11–28 | 22,656 | **32.52** | 1,270,164 | $0.24 B |
| 2 | 69,665 | 28–63 | 20,716 | 29.74 | 3,047,305 | $0.54 B |
| 3 | 69,665 | 63–120 | 19,208 | 27.57 | 6,219,463 | $1.14 B |
| 4 | 69,665 | 120–208 | 18,406 | 26.42 | 11,235,711 | $2.20 B |
| 5 | 69,665 | 208–348 | 16,858 | 24.20 | 18,970,141 | $4.28 B |
| 6 | 69,665 | 348–605 | 13,310 | 19.11 | 32,073,416 | $9.49 B |
| 7 | 69,665 | 605–1,161 | 9,831 | 14.11 | 58,980,136 | $23.61 B |
| 8 | 69,664 | 1,161–2,370 | 8,366 | **12.01** | 117,341,703 | $42.34 B |
| 9 | 69,664 | 2,370–5,194 | 9,563 | 13.73 | 249,202,275 | $49.48 B |
| 10 | 69,664 | 5,194–537,707 | 7,545 | **10.83** | 707,807,477 | $77.58 B |

A clean, near-monotonic gradient: 32.52% down to 10.83%, a 3× spread. Industry engagement
tracks prescribing volume, as expected.

**The decile 9 uptick (12.01% → 13.73%) is composition, not noise.** Specialty mix shifts
sharply at the top: the share of the decile that is Family Practice or Internal Medicine goes
30.2% (d7) → 34.0% (d8) → **54.3% (d9)** → **77.6% (d10)**. Primary care has a much higher
never-engaged rate (~25–26%) than the procedural specialties populating deciles 7–8, so as
primary care comes to dominate the top deciles it pulls the rate back up before sheer volume
pulls it down again in decile 10.

### The headline number

```sql
SELECT count(*) AS n_prescribers, sum(tot_clms) AS claims, sum(tot_drug_cst) AS cost
FROM mddo WHERE never_engaged AND clms_decile >= 9;
```

| | Value |
|---|---|
| Never-engaged MD/DOs in top two volume deciles | **17,108** |
| Claims | **97,886,665** |
| Drug cost | **$8.207 B** |
| Share of MD/DO claims | 8.12% |
| Share of MD/DO cost | 3.89% |
| Share of all Part D claims | 5.72% |
| Share of all Part D cost | 2.85% |
| Share of *never-engaged MD/DO* claims | **71.55%** |
| Share of *never-engaged MD/DO* cost | 60.50% |

Reference points: all never-engaged MD/DOs (146,459) write 136,807,144 claims / $13.56 B; all
MD/DOs write 1,206,147,791 claims / $210.9 B, which is 70.54% of Part D claims and 73.13% of
Part D cost.

**Verified:** zero of the 17,108 appear anywhere in the Profile Supplement, and zero appear in
the PY2025 General Payments file. Spot-checking five by NPI against raw Part D returns
plausible high-volume primary care physicians (e.g. an Iowa Family Practice prescriber with
7,718 claims / $679,456; an Oregon Internal Medicine prescriber with 6,022 claims / $451,661).

### Robustness — deciles by drug cost instead of claims

| Decile | Cost range | Never engaged | % never |
|---|---|---|---|
| 1 | $0–700 | 20,709 | 29.73 |
| 2 | $700–2,226 | 21,027 | 30.18 |
| 3 | $2,226–5,229 | 21,040 | 30.20 |
| 4 | $5,229–11,691 | 19,354 | 27.78 |
| 5 | $11,691–27,423 | 16,828 | 24.16 |
| 6 | $27,424–73,069 | 14,963 | 21.48 |
| 7 | $73,070–189,388 | 12,580 | 18.06 |
| 8 | $189,388–402,626 | 10,197 | 14.64 |
| 9 | $402,627–827,563 | 7,083 | 10.17 |
| 10 | $827,570–108,791,817 | 2,678 | **3.84** |

The cost gradient is much steeper and perfectly monotonic: 29.73% → 3.84%, nearly 8×, versus 3×
for claims. **Industry engagement tracks drug spend far more tightly than it tracks
prescription count** — which is what you would expect from a commercially rational targeting
operation, and it is a useful validation that the engagement flag is measuring something real.

Under the cost definition the top-two-decile never-engaged population is **9,761 physicians,
61,869,508 claims, $7.883 B**. The dollar figure barely moves ($8.21 B → $7.88 B) even though
the headcount falls 43%, which says the same dollars are being captured by a tighter group.

### Cost per claim — the unanticipated result

```sql
SELECT clms_decile AS decile,
  round(sum(tot_drug_cst) FILTER (WHERE never_engaged)
        / sum(tot_clms) FILTER (WHERE never_engaged),2) AS cost_per_claim_never,
  round(sum(tot_drug_cst) FILTER (WHERE NOT never_engaged)
        / sum(tot_clms) FILTER (WHERE NOT never_engaged),2) AS cost_per_claim_ever
FROM mddo GROUP BY 1 ORDER BY 1;
```

| Decile | Never engaged | Ever engaged | Ratio |
|---|---|---|---|
| 1 | $112.44 | $223.32 | 0.503 |
| 2 | $102.51 | $208.92 | 0.491 |
| 3 | $99.20 | $215.54 | 0.460 |
| 4 | $97.23 | $230.89 | 0.421 |
| 5 | $110.94 | $261.58 | 0.424 |
| 6 | $130.73 | $334.17 | 0.391 |
| 7 | $166.74 | $438.09 | 0.381 |
| 8 | $147.80 | $390.06 | 0.379 |
| 9 | $95.64 | $215.17 | 0.444 |
| 10 | $77.39 | $112.77 | 0.686 |

Never-engaged physicians prescribe at 38–69% of the per-claim drug cost of engaged physicians,
**in every decile without exception**. This is not a volume artifact — volume is held
approximately constant within each decile. It is a difference in what is being prescribed.

I am deliberately not calling this a brand-versus-generic effect, because Decision 2 removed
brand-share metrics for good reason (44% non-random suppression). Cost per claim is computed
from `Tot_Drug_Cst / Tot_Clms`, both of which are never suppressed, so the measure itself is
clean — but it cannot by itself distinguish "prescribes generics" from "prescribes cheaper
therapeutic classes." Separating those is a Phase C question.

---

## A4 — Specialty

MD/DO only, specialties with **n ≥ 500** (threshold stated as required; it retains 61 of 115
specialties, covering 99.51% of MD/DO prescribers). "High-volume" throughout means claims decile
≥ 9, i.e. ≥ 2,370 claims.

### Ranked by rate

Highest never-engagement:

| Specialty | n | Never engaged | % never | High-vol never | Median claims |
|---|---|---|---|---|---|
| Student in Organized Health Care Education/Training | 9,592 | 6,114 | 63.74 | 2 | 94 |
| Hospice and Palliative Care | 1,408 | 725 | 51.49 | 34 | 267 |
| Emergency Medicine | 55,489 | 26,194 | 47.21 | 83 | 145 |
| Pathology | 618 | 282 | 45.63 | 2 | 23 |
| Preventive Medicine | 1,090 | 497 | 45.60 | 5 | 43 |
| Psychiatry & Neurology | 15,996 | 6,785 | 42.42 | 57 | 91 |
| Neuropsychiatry | 2,663 | 1,081 | 40.59 | 9 | 83 |
| Family Medicine | 1,013 | 406 | 40.08 | 17 | 148 |
| **Geriatric Medicine** | 1,878 | 735 | **39.14** | **306** | **2,560** |
| Hospitalist | 20,057 | 7,078 | 35.29 | 98 | 233 |
| Diagnostic Radiology | 3,283 | 1,138 | 34.66 | 1 | 23 |
| Psychiatry | 23,311 | 7,194 | 30.86 | 535 | 497 |

Lowest never-engagement:

| Specialty | n | Never engaged | % never | Median claims |
|---|---|---|---|---|
| Cardiac Surgery | 626 | 2 | 0.32 | 62 |
| Clinical Cardiac Electrophysiology | 2,683 | 14 | 0.52 | 1,129 |
| Interventional Cardiology | 4,910 | 35 | 0.71 | 2,232 |
| Vascular Surgery | 3,451 | 29 | 0.84 | 137 |
| Thoracic Surgery | 1,597 | 15 | 0.94 | 43 |
| Neurosurgery | 3,686 | 54 | 1.47 | 78 |
| Colorectal Surgery | 1,653 | 26 | 1.57 | 145 |
| Advanced Heart Failure & Transplant Cardiology | 818 | 14 | 1.71 | 1,606 |
| Orthopedic Surgery | 20,521 | 363 | 1.77 | 212 |
| Hematology-Oncology | 9,054 | 215 | 2.37 | 761 |

### Ranked by count of high-volume never-engaged — the commercially relevant ordering

```sql
SELECT partd_specialty,
       count(*) FILTER (WHERE never_engaged AND clms_decile>=9) AS hivol_never,
       sum(tot_clms)     FILTER (WHERE never_engaged AND clms_decile>=9) AS hivol_never_claims,
       sum(tot_drug_cst) FILTER (WHERE never_engaged AND clms_decile>=9) AS hivol_never_cost
FROM mddo GROUP BY 1 ORDER BY hivol_never DESC;
```

| Specialty | High-vol never | Specialty n | % never (all) | Their claims | Their cost | % of all high-vol never |
|---|---|---|---|---|---|---|
| **Family Practice** | **8,291** | 115,717 | 25.01 | 46,449,145 | $3.548 B | **48.46** |
| **Internal Medicine** | **6,641** | 127,181 | 26.44 | 40,625,674 | $3.320 B | **38.82** |
| Psychiatry | 535 | 23,311 | 30.86 | 2,179,945 | $0.188 B | 3.13 |
| Geriatric Medicine | 306 | 1,878 | 39.14 | 1,956,472 | $0.147 B | 1.79 |
| General Practice | 241 | 8,847 | 22.64 | 1,484,269 | $0.080 B | 1.41 |
| Cardiology | 175 | 19,002 | 3.48 | 780,011 | $0.161 B | 1.02 |
| Hospitalist | 98 | 20,057 | 35.29 | 629,622 | $0.059 B | 0.57 |
| Emergency Medicine | 83 | 55,489 | 47.21 | 634,378 | $0.071 B | 0.49 |
| Endocrinology | 69 | 6,531 | 7.26 | 262,027 | $0.110 B | 0.40 |
| Ophthalmology | 62 | 19,063 | 5.69 | 217,914 | $0.016 B | 0.36 |
| Rheumatology | 62 | 5,128 | 7.00 | 220,228 | $0.176 B | 0.36 |
| Nurse Practitioner (MD/DO taxonomy) | 60 | 2,696 | 18.73 | 282,175 | $0.022 B | 0.35 |
| Psychiatry & Neurology | 57 | 15,996 | 42.42 | 205,884 | $0.021 B | 0.33 |
| Pediatric Medicine | 55 | 8,455 | 26.53 | 240,007 | $0.019 B | 0.32 |
| Neurology | 52 | 14,434 | 8.33 | 200,819 | $0.044 B | 0.30 |

**Family Practice and Internal Medicine together are 87.28% of all high-volume never-engaged
MD/DOs** (14,932 of 17,108) and $6.87 B of the $8.21 B. The rate ranking and the count ranking
tell almost opposite stories, exactly as the task anticipated: Emergency Medicine has the third
highest *rate* (47.21%) but contributes 83 high-volume prescribers, while Family Practice at
half that rate contributes 8,291.

### Structural versus behavioural, by specialty

Two signatures are clearly distinguishable in the table above.

**Structural — high rate, negligible volume.** Emergency Medicine (47.21%, median 145 claims),
Pathology (45.63%, median 23), Diagnostic Radiology (34.66%, median 23), Anesthesiology
(21.25%, median 53), Hospitalist (35.29%, median 233), Psychiatry & Neurology (42.42%, median
91). These are hospital-based or non-prescribing-facing specialties with little outpatient
retail pharmaceutical interest. Their high never-engagement is a statement about pharma's
commercial priorities, not about reachability, and their tiny high-volume counts confirm it.
They should probably be excluded from, or reported separately in, any commercial sizing.

**Behavioural — moderate rate, very large volume.** Family Practice (25.01%) and Internal
Medicine (26.44%). These are the highest-priority commercial targets in all of pharma, engaged
at scale for a decade, and roughly a quarter of them have still never been touched. This is
where the white-space story actually lives.

**One genuine anomaly — Geriatric Medicine.** 39.14% never engaged *and* a median of 2,560
claims, by far the highest median of any high-never-engagement specialty and above the 90th
percentile of the whole MD/DO population. 306 of its 1,878 physicians (16.3%) are high-volume
never-engaged — proportionally the densest pocket in the data. High-volume prescribers to the
oldest, most polypharmacy-exposed Medicare patients, and two in five have never received
anything. Small in absolute terms but I would flag it for Phase B: it fits neither the
structural nor the behavioural pattern cleanly and may reflect practice setting (nursing home
and long-term care employment) rather than either.

---

## A5 — Geography

### Billing state versus practice state — recon caveat resolved

Recon flagged that Part D `Prscrbr_State_Abrvtn` is a billing address. Checking it against
NPPES practice location for the MD/DO population:

```sql
SELECT count(*) AS n_with_both, count(*) FILTER (WHERE partd_state = nppes_state) AS agree,
       round(100.0*count(*) FILTER (WHERE partd_state=nppes_state)/count(*),2) AS pct_agree
FROM mddo WHERE partd_state IS NOT NULL AND nppes_state IS NOT NULL;
```

**98.21% agreement** (684,187 of 696,647). State-level figures are robust to the choice. All
figures below use the Part D field for consistency with reconnaissance.

### Never-engaged rate by state, MD/DO (n ≥ 500)

| State | MD/DO | Never eng. | % never | High-vol never | % never *among high-vol* |
|---|---|---|---|---|---|
| VT | 1,465 | 892 | **60.89** | 190 | **64.85** |
| MN | 13,680 | 6,213 | 45.42 | 1,330 | 56.07 |
| ME | 3,477 | 1,532 | 44.06 | 310 | 47.99 |
| WI | 12,772 | 4,882 | 38.22 | 1,056 | 38.82 |
| WA | 15,295 | 5,582 | 36.50 | 931 | 34.56 |
| OR | 8,981 | 3,269 | 36.40 | 553 | 33.47 |
| MA | 20,163 | 7,190 | 35.66 | 978 | 29.29 |
| NH | 3,321 | 1,095 | 32.97 | 196 | 32.29 |
| RI | 3,191 | 1,043 | 32.69 | 122 | 21.18 |
| AK | 1,425 | 464 | 32.56 | 28 | 18.79 |
| DC | 2,892 | 858 | 29.67 | 51 | 24.17 |
| NM | 3,494 | 997 | 28.53 | 66 | 10.89 |
| WY | 905 | 243 | 26.85 | 15 | 9.38 |
| CO | 12,018 | 3,155 | 26.25 | 448 | 24.16 |
| MT | 2,169 | 565 | 26.05 | 71 | 16.78 |
| HI | 2,948 | 751 | 25.47 | 97 | 18.44 |
| CA | 77,176 | 19,605 | 25.40 | 2,872 | 19.63 |
| IA | 5,858 | 1,480 | 25.26 | 246 | 17.63 |
| CT | 9,519 | 2,353 | 24.72 | 236 | 14.08 |
| NY | 51,083 | 12,281 | 24.04 | 922 | 10.16 |
| UT | 5,442 | 1,302 | 23.93 | 144 | 17.93 |
| ND | 1,546 | 369 | 23.87 | 39 | 14.13 |
| IL | 29,549 | 6,556 | 22.19 | 584 | 11.47 |
| MD | 13,017 | 2,883 | 22.15 | 302 | 14.38 |
| ID | 3,069 | 672 | 21.90 | 78 | 12.15 |
| VA | 16,106 | 3,464 | 21.51 | 405 | 13.77 |
| PA | 34,297 | 7,298 | 21.28 | 786 | 11.96 |
| MI | 24,642 | 5,087 | 20.64 | 533 | 10.75 |
| DE | 2,159 | 405 | 18.76 | 31 | 6.84 |
| SD | 1,731 | 318 | 18.37 | 25 | 6.48 |
| AZ | 13,266 | 2,408 | 18.15 | 146 | 6.21 |
| OH | 25,715 | 4,630 | 18.01 | 482 | 8.89 |
| WV | 3,739 | 632 | 16.90 | 56 | 6.74 |
| MO | 13,832 | 2,336 | 16.89 | 168 | 5.71 |
| NC | 20,423 | 3,392 | 16.61 | 387 | 9.17 |
| KS | 5,559 | 915 | 16.46 | 65 | 4.79 |
| AR | 5,260 | 773 | 14.70 | 42 | 2.98 |
| PR | 8,665 | 1,272 | 14.68 | 176 | 6.08 |
| NE | 3,887 | 566 | 14.56 | 48 | 5.50 |
| TN | 12,412 | 1,777 | 14.32 | 153 | 5.55 |
| IN | 12,447 | 1,777 | 14.28 | 143 | 4.70 |
| NV | 4,994 | 710 | 14.22 | 52 | 5.63 |
| OK | 7,040 | 965 | 13.71 | 83 | 5.01 |
| TX | 47,868 | 6,485 | 13.55 | 389 | 3.96 |
| SC | 10,674 | 1,433 | 13.43 | 66 | 2.97 |
| NJ | 19,804 | 2,528 | 12.77 | 184 | 4.46 |
| GA | 18,877 | 2,322 | 12.30 | 185 | 4.48 |
| KY | 8,508 | 1,018 | 11.97 | 64 | 3.24 |
| FL | 47,037 | 5,380 | 11.44 | 423 | 3.91 |
| LA | 9,474 | 938 | 9.90 | 37 | 1.66 |
| AL | 8,749 | 837 | 9.57 | 69 | 2.95 |
| MS | 4,570 | 332 | 7.26 | 18 | 1.64 |

Restricting to MD/DO sharpens the reconnaissance picture rather than changing it: the ordering
is nearly identical but the range widens at the bottom (MS 7.26% vs 9.80% all-prescriber) and
the spread is **8.4×** from VT to MS.

**The last column is the more striking result and it was not asked for.** Among only the
highest-volume MD/DOs — the physicians industry has the strongest commercial reason to reach —
never-engagement ranges from **64.85% in Vermont to 1.64% in Mississippi, a 40× spread.** In
Vermont and Minnesota, most of the highest-volume prescribers in the state have never received
anything. In the Gulf South, almost none. Whatever is driving the state pattern acts *more*
strongly on exactly the physicians industry most wants to reach, which is the signature of a
constraint on industry rather than a lack of industry interest.

Per Decision 3 I have not attached any legal classification to these states.

### Rurality — derivable from data on disk, no download needed

Part D carries `Prscrbr_RUCA` and `Prscrbr_RUCA_Desc` directly (recon Q2 noted this). No
external crosswalk is required. Collapsed using standard RUCA Categorization A on the integer
part of the code:

| Category | RUCA codes | n | Never engaged | % never | High-vol never |
|---|---|---|---|---|---|
| Metropolitan | 1–3 | 634,431 | 133,125 | 20.98 | 14,798 |
| Micropolitan | 4–6 | 40,746 | 7,798 | 19.14 | 1,132 |
| Small town | 7–9 | 14,899 | 3,656 | 24.54 | 796 |
| Rural | 10 | 5,336 | 1,449 | 27.16 | 341 |
| Unknown | 99 / null | 1,235 | 431 | 34.90 | 41 |

**Rurality barely matters.** The metropolitan-to-rural spread is 6.2 points (20.98% → 27.16%)
and it is not even monotonic — micropolitan is *lower* than metropolitan. Against a 53-point
state spread this is close to nothing, and the variance decomposition in A6 confirms it
formally. The intuitive "unreached because remote" story is not supported: 90.9% of
never-engaged MD/DOs are in metropolitan areas.

**Gap for the next phase.** RUCA gives commuting-based rurality only. County-level typology
(persistent poverty, health professional shortage areas) and any hospital-referral-region or
market-concentration measure would need external crosswalks that are not on disk. Not
downloaded, per the rules. Flagging as a Phase B input.

---

## A6 — Structural versus behavioural, first cut

Descriptive one-way variance decomposition. The outcome is the individual binary
never-engaged indicator across the 696,647 MD/DOs. For each candidate factor I compute the
between-group sum of squares against the total, i.e. η² — the share of individual-level
variance accounted for by knowing only that factor.

```sql
WITH g AS (SELECT avg(CASE WHEN never_engaged THEN 1.0 ELSE 0.0 END) AS gm, count(*) AS N FROM mddo),
f AS (SELECT 'state' AS factor, partd_state AS lvl, count(*) AS n,
             avg(CASE WHEN never_engaged THEN 1.0 ELSE 0.0 END) AS m FROM mddo GROUP BY 2
      UNION ALL SELECT 'specialty', partd_specialty, count(*), avg(...) FROM mddo GROUP BY 2
      UNION ALL SELECT 'volume_decile', clms_decile::VARCHAR, count(*), avg(...) FROM mddo GROUP BY 2
      UNION ALL SELECT 'rurality', ruca_cat, count(*), avg(...) FROM mddo GROUP BY 2
      UNION ALL SELECT 'state x specialty', partd_state||'|'||partd_specialty, count(*), avg(...) FROM mddo GROUP BY 2)
SELECT f.factor, count(*) AS n_levels,
       round(100.0*sum(f.n*(f.m-g.gm)*(f.m-g.gm))
             / (any_value(g.N)*any_value(g.gm)*(1-any_value(g.gm))),2) AS pct_variance_explained
FROM f CROSS JOIN g GROUP BY 1 ORDER BY pct_variance_explained DESC;
```

| Factor | Levels | % of individual variance explained |
|---|---|---|
| State × specialty | 3,966 | **18.70** |
| Specialty | 115 | **12.63** |
| State | 62 | **4.22** |
| Volume decile | 10 | 3.49 |
| Rurality | 5 | 0.07 |

**State alone accounts for 4.22% of individual-level variance; between-state differences are
therefore about 4% of the story and within-state differences about 96%.** Specialty accounts
for three times as much as state. Together they reach 18.70%, leaving **over 81% of the
variation unexplained by any structural variable available in Phase A.**

Holding specialty constant sharpens the state estimate. Within Family Practice and Internal
Medicine only — a population with homogeneous commercial relevance, 242,898 physicians,
25.75% never engaged overall:

| Factor | % variance explained |
|---|---|
| State, within FP + IM only | **7.79** |

Removing specialty confounding nearly doubles the apparent state effect (4.22% → 7.79%). That
is the cleanest available estimate of the structural state component, and it is the number I
would carry forward.

**Two honest cautions about reading these numbers.**

First, η² on a *binary individual-level* outcome has a low ceiling by construction. Most of the
residual is irreducible Bernoulli noise — whether any particular physician ever accepted a $14
lunch is close to a coin flip conditional on their environment, and no covariate can explain
that. A low η² does not mean state is unimportant; it means state does not determine individual
outcomes. Both of the following are true and not in tension: state explains 4% of individual
variance, *and* state-level rates range from 7.26% to 60.89%.

Second, this is a one-way decomposition with no adjustment. The state and specialty effects
overlap (states differ in specialty mix), which is why their individual η² values sum to more
than the joint 18.70% would suggest under independence.

**What this means for the framing.** The reframed question in Decision 4 asks how much
never-engagement is structural versus behavioural. The first-cut answer is that the structural
variables available in Phase A — state, specialty, rurality — account for **under a fifth** of
individual variation, and rurality contributes essentially none of it. If a substantial
structural component exists, it is not primarily geographic. The candidates that remain are
practice-level: employment by an integrated delivery network, academic medical centre
appointment, group size, and health-system conflict-of-interest policy. Those are precisely the
Phase B variables (`num_org_mem`, `org_pac_id`, hospital affiliation), and this decomposition is
the strongest evidence so far that Phase B is where the structural explanation will be found or
ruled out. Note also that the state effect is far larger among high-volume prescribers (A5's 40×
spread) than in the population as a whole, so a decomposition restricted to high-volume
physicians would likely attribute more to state than the 7.79% above.

---

## What surprised me

**1. NPPs are better-engaged than physicians, not worse.** A2 was framed as measuring an
artifact that inflates NPP never-engagement. The artifact is real but the sign is backwards:
NPPs (20.11%) are less never-engaged than MD/DOs (21.02%) and much less than primary care
MD/DOs (25.65%), despite five years of eligibility against thirteen. Industry moved onto
non-physician prescribers fast and effectively. If anything the untouched population skews
*physician*, which inverts a common assumption about who the hard-to-reach prescribers are.

**2. Never-engaged physicians prescribe at half the cost per claim — in every decile.** Ratio
0.38–0.69, no exceptions across ten deciles. This wasn't on the task list and it materially
changes how the headline should be sized: 8.12% of claims but 3.89% of cost. A claims-based
opportunity estimate is roughly double a spend-based one. It also suggests the white space is
partly self-selecting — physicians who prescribe cheaply may be the same physicians who decline
industry contact — which is a hypothesis Phase C could test directly through the food-and-
beverage channel signal.

**3. Rurality explains 0.07% of variance.** I expected the access story to have a geographic
component. It does not, at least not as commuting-based rurality: 90.9% of never-engaged MD/DOs
practise in metropolitan areas, and micropolitan physicians are *less* never-engaged than
metropolitan ones. Whatever "unreached" means here, it does not mean "far away."

**4. The state effect concentrates on exactly the physicians industry most wants.** The overall
state spread is 8.4×; among top-two-decile prescribers it is 40× (VT 64.85%, MS 1.64%). A
lack-of-commercial-interest explanation predicts the opposite — you would expect industry to
reach the highest-value targets everywhere, with state mattering only at the margins. Getting a
*stronger* state gradient at the top of the volume distribution is the signature of something
blocking access rather than something depressing demand for it. That is a specific, testable
claim for the phase that examines state law.

**5. Geriatric Medicine.** 39.14% never engaged with a median of 2,560 claims — high volume and
high white space simultaneously, which almost nothing else in the data manages. 16.3% of the
specialty are high-volume never-engaged, proportionally the densest pocket found. Small
(n = 1,878) but it looks like a genuine structural pocket, plausibly long-term-care employment,
and it is invisible in a rate-ranked or a count-ranked table alone.

**6. 14.5% of NPPES individuals have their primary taxonomy outside slot 1.** A quiet trap.
Using `Taxonomy Code_1` as "primary specialty" — which is the obvious reading and what
reconnaissance did — misses 41,643 MD/DO Part D prescribers, about 6% of the population. It
did not change any conclusion, but it would have silently biased every specialty-level figure.
Worth carrying forward as a known NPPES gotcha.

**7. 5,575 deactivated NPIs wrote Part D prescriptions in 2024.** Present in NPPES with a
deactivation date and every attribute field blank, yet each with ≥11 Part D claims (median 98,
5.7M claims total). Not a large enough population to affect anything, but it means NPPES
deactivation and CMS claims processing disagree, and any pipeline that inner-joins on a
populated NPPES attribute will drop them without noticing.

---

## Files produced

| Path | Rows | Size | Contents |
|---|---|---|---|
| `work/analytic_population.parquet` | 1,416,883 | 45 MB | One row per Part D 2024 NPI: identifiers, Part D volume, NPPES attributes, engagement flag, population flags |
| `work/nppes_slim.parquet` | 9,671,888 | 115 MB | NPPES reduced to the 13 fields this project uses, with corrected primary taxonomy |

Nothing was deleted; all source CSVs and the recon Parquet files are intact.

## Open items for Phase B

1. **A2 is unfinished.** Needs `OP_DTL_GNRL_PGYR2021`–`PGYR2024` to construct a true matched
   window. Everything else in Phase A is complete.
2. **Blank-NPI supplement rows (15,235)** remain an unresolved one-directional bias on every
   never-engaged figure. Recoverable via profile ID through the payment files if it matters.
3. **County typology / HPSA / market concentration** would require external crosswalks not on
   disk. Not downloaded.
4. **Practice-level variables are where the structural explanation must be tested** — A6 makes
   that case quantitatively rather than by assumption.
5. **Cost-per-claim** deserves decomposition into therapeutic mix versus generic substitution,
   which needs the drug-level detail in General Payments or a separate Part D drug file.
