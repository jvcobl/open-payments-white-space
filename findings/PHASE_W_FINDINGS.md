# Phase W — Research and Ownership Payment Integration

Generated 2026-08-02. Final data acquisition. Descriptive only.
Assumes `PHASE_R_FINDINGS.md` and `PHASE_V_FINDINGS.md`.

**Window: PY2021–PY2025** for all three payment categories. Baseline never-engaged remains
cumulative across all program years via the Profile Supplement.

---

## Verdict

### W1 — The supplement holds. Decisively. ⭐⭐

**Of 59,213 distinct MD/DO-and-other NPIs appearing anywhere in five years of research payments,
2 are absent from the Profile Supplement — 0.003%. Of 5,640 ownership NPIs, zero are absent.**

**Zero of the 146,459 baseline never-engaged MD/DOs have a research payment. Zero have an
ownership payment.**

The last unverified assumption in the project is now verified against data rather than
documentation. **Every population figure in the project stands unchanged.** "Absent from the
Profile Supplement" does mean "has received nothing of any reportable category."

### W3 — The 553 survive completely intact

**Zero of the 553 have a research payment. Zero have an ownership payment.** The count remains
**553** and the drug cost remains **$0.924 B**. No headline figure changes.

### W4 — The discriminant is essentially unchanged

Neither the predicted widening nor a collapse. Kaiser moves 0.656 → 0.685, gift-ban states
1.168 → 1.182. The separation narrows by 3% (0.512 → 0.497), which is noise at this resolution.
**The R2 discriminant was not reading research-relationship intensity.**

### W5 — But the organization-level result is substantially a state artifact ⭐

**This is the significant finding of Phase W and it requires splitting a Phase R conclusion in
two.**

| Group | n orgs | n physicians | Median discriminant, **national** | Median discriminant, **state-relative** |
|---|---|---|---|---|
| **Kaiser entities** | 8 | 16,958 | **0.713** | **0.727** |
| Orgs in low-restriction states | 179 | 56,176 | 0.978 | 0.976 |
| Orgs elsewhere | 580 | 194,131 | 0.969 | 0.984 |
| **Orgs in gift-ban states** | 53 | 20,876 | **1.130** | **0.994** |

**Scored against their own state's baseline, organizations in gift-ban states collapse to 0.994 —
indistinguishable from average. Kaiser does not move at all (0.713 → 0.727).**

The honest version is the one the task anticipated: **a contact-ban signature at organization
level and a gift-ban signature at state level — two findings with two evidence bases, not one
unified discriminant.**

**Only one figure in the project is superseded** (the adjusted national never-engaged rate,
64.67% → 63.65%). Everything else stands or is a framing change.

---

## Conversion and verification

All ten files converted with the established convention (`all_varchar=true`, all columns).
Headers identical across years within each family.

| File | Columns | Rows (CSV = Parquet) | CSV | Parquet |
|---|---|---|---|---|
| `op_rsrch_py2021` | 252 | 894,317 | 831 M | 26 M |
| `op_rsrch_py2022` | 252 | 1,011,616 | 912 M | 26 M |
| `op_rsrch_py2023` | 252 | 1,092,474 | 998 M | 27 M |
| `op_rsrch_py2024` | 252 | 817,215 | 751 M | 23 M |
| `op_rsrch_py2025` | 252 | 931,959 | 856 M | 23 M |
| `op_ownrshp_py2021` | 30 | 4,191 | 1.7 M | 200 K |
| `op_ownrshp_py2022` | 30 | 4,148 | 1.7 M | 200 K |
| `op_ownrshp_py2023` | 30 | 4,426 | 1.9 M | 212 K |
| `op_ownrshp_py2024` | 30 | 4,834 | 2.1 M | 219 K |
| `op_ownrshp_py2025` | 30 | 2,646 | 985 K | 150 K |

**All ten row counts match their source CSV exactly.** 4,747,581 research records; 20,245
ownership records. **Nothing deleted — see the question at the end of this document.**

### Schema note — the PI fields matter enormously

Research files carry `Covered_Recipient_NPI` **and** `Principal_Investigator_1..5_NPI`. Phase V
flagged that both must be used. That was correct and the margin is large:

| Role | Distinct NPIs |
|---|---|
| As covered recipient | 16,210 |
| **As principal investigator** | **54,119** |
| Either (deduplicated) | 59,213 |

**Using only the covered-recipient field would have missed roughly 70% of the physicians with a
research relationship**, because the covered recipient on a research payment is typically the
teaching hospital or research institution, with the physician named as PI. Every figure below
uses the union of all six NPI fields.

Ownership files use `Physician_NPI` and `Total_Amount_Invested_USDollars`.

---

## W1 — The supplement comprehensiveness test ⭐⭐

```sql
CREATE TEMP TABLE rsrch_npi AS
SELECT DISTINCT npi, role FROM (
  SELECT trim(Covered_Recipient_NPI) AS npi, 'covered_recipient' AS role FROM read_parquet('work/op_rsrch_py202*.parquet')
  UNION ALL SELECT trim(Principal_Investigator_1_NPI), 'PI' FROM read_parquet('work/op_rsrch_py202*.parquet')
  UNION ALL ... slots 2..5 ...
) WHERE length(coalesce(npi,''))=10;

SELECT count(*) AS npis, count(*) FILTER (WHERE s.npi IS NULL) AS absent_from_supplement
FROM rsrch_any r LEFT JOIN sup s ON r.npi=s.npi;
```

| Source | Distinct NPIs | Absent from supplement | % absent |
|---|---|---|---|
| Research, any role | 59,213 | **2** | **0.003** |
| — as covered recipient | 16,210 | 1 | 0.006 |
| — as principal investigator | 54,119 | 1 | 0.002 |
| **Ownership** | 5,640 | **0** | **0.000** |

Set alongside what Phase R established for general payments (0 of 770,465 in PY2021; 5, 1 and 6
of ~900,000 in 2022–2024), **the Profile Supplement is now verified comprehensive across all
three Open Payments categories.**

### The population question

```sql
SELECT count(*) FILTER (WHERE b.never_base) AS never_base,
       count(*) FILTER (WHERE b.never_base AND r.npi IS NOT NULL) AS never_base_with_research,
       count(*) FILTER (WHERE b.never_base AND o.npi IS NOT NULL) AS never_base_with_ownership
FROM 'work/phase_r_base.parquet' b LEFT JOIN rsrch_any r ON b.npi=r.npi LEFT JOIN own_npi o ON b.npi=o.npi;
```

| | n |
|---|---|
| MD/DO Part D prescribers | 696,647 |
| With ≥1 research payment (any role, PY2021–25) | 41,524 (5.96%) |
| With ≥1 ownership interest | 4,134 (0.59%) |
| Baseline never-engaged | 146,459 |
| **— of which with research** | **0** |
| **— of which with ownership** | **0** |

**Zero and zero.** The result falls squarely in the task's first branch: *"Zero or near-zero →
the supplement is confirmed comprehensive across payment categories, and the population counts
throughout the project stand. This closes the last unverified assumption."*

**It is closed.** Phase V's caveat — that the baseline flag's research-safety rested on CMS
documentation rather than on data — can be removed from the writeup.

### Where research does land

| Prior cell (R2, general only) | With research | Moves to |
|---|---|---|
| Meal-only | 7,145 | Fully engaged |
| No record in window | 1,840 | Relationship-only |
| Baseline never-engaged | **0** | — |

The 1,840 come entirely from the 32,159 ever-engaged-but-unclassifiable that Phase V bounded —
**5.7% of them, against Phase V's stated worst case of 100%.** Phase V's reasoning (that the
group looked like lapsed low-intensity payment recipients rather than active investigators, being
lower-volume and not concentrated in large organizations) is confirmed.

---

## W2 — Channel classification recomputed

### (a) Four-cell, comparable to R2

Research folded into the non-F&B axis:

| Cell | R2 (general only) | % | **W (with research)** | **%** | Δ |
|---|---|---|---|---|---|
| Fully engaged | 205,244 | 29.46 | **212,389** | **30.49** | +7,145 |
| Meal-only | 304,109 | 43.65 | **296,964** | **42.63** | −7,145 |
| Relationship-only | 8,715 | 1.25 | **10,555** | **1.52** | +1,840 |
| No record in window | 178,579 | 25.63 | **176,739** | **25.37** | −1,840 |

**The distribution barely moves — no cell shifts by more than 1.03 points.** Research is a
substantive relationship but a numerically rare one at population scale.

### (b) Three-axis

F&B / non-F&B general / research as separate axes:

| Pattern | n | % | Meaning |
|---|---|---|---|
| `F--` | 296,964 | 42.63 | Meal only |
| `---` | 176,739 | 25.37 | No record |
| `FG-` | 173,718 | 24.94 | Meal + general |
| `FGR` | 31,526 | 4.53 | Meal + general + research |
| `-G-` | 7,702 | 1.11 | General only, no meal |
| `F-R` | 7,145 | 1.03 | Meal + research, no other general |
| **`--R`** | **1,840** | **0.26** | **Research only** |
| `-GR` | 1,013 | 0.15 | General + research, no meal |

**Only 1,840 MD/DOs (0.26%) are research-only.** Where they sit:

| Specialty | n | | State | n |
|---|---|---|---|---|
| Internal Medicine | 271 | | CA | 170 |
| Neurology | 187 | | FL | 155 |
| Family Practice | 140 | | NY | 141 |
| Infectious Disease | 124 | | MA | 135 |
| Emergency Medicine | 104 | | MN | 99 |
| Hematology-Oncology | 80 | | PA | 97 |
| Pediatric Medicine | 76 | | TX | 91 |
| Medical Oncology | 68 | | MI | 70 |

Trial-intensive specialties (Neurology, Infectious Disease, the two Oncology categories) are
heavily over-represented relative to their share of the population, which is the expected
pattern and a reassurance that the linkage is working.

### The research dollar scale — worth one line

| | Value |
|---|---|
| Research dollars, PY2021–25, MD/DOs | **$32.95 B** |
| MD/DOs with any research | 41,524 |
| **Median per physician (if any)** | **$88,238** |

Against a median *general* payment footprint of $705 over the same five years, research is two
orders of magnitude larger per physician. **These dollars overwhelmingly fund institutional trial
work rather than accruing to the physician personally**, and the figure should never be presented
as physician compensation. It is reported here only to make the point that research and general
payments are not commensurable quantities and should not be summed into a single "total industry
payment" measure anywhere in the writeup.

---

## W3 — Does the 553 survive?

```sql
SELECT count(*) AS n553, count(*) FILTER (WHERE r.npi IS NOT NULL) AS with_research,
       count(*) FILTER (WHERE o.npi IS NOT NULL) AS with_ownership
FROM 'work/phase_r_base.parquet' b
LEFT JOIN rsrch_any r ON b.npi=r.npi LEFT JOIN own_npi o ON b.npi=o.npi
WHERE b.never_base AND b.clms_decile>=9 AND b.cpc_decile>=9;
-- 553 | 0 | 0
```

| | Before W | After W |
|---|---|---|
| Selection-robust physicians | 553 | **553** |
| Drug cost | $0.924 B | **$0.924 B** |
| Removed for research | — | **0** |
| Removed for ownership | — | **0** |

**No change.** The 553 are now verified against all three Open Payments categories across five
program years — general (71.2M records), research (4.75M records), ownership (20,245 records) —
and appear in none of them, in addition to being absent from the cumulative Profile Supplement.

This is the most heavily verified figure in the project. The Phase R headline stands.

---

## W4 — Does the discriminant change?

Standardized to national specialty × volume-decile rates, with research folded into the non-F&B
axis:

| Group | n | F&B ratio | **Discriminant R2** (general only) | **Discriminant W** (with research) | Δ |
|---|---|---|---|---|---|
| **Kaiser / Permanente** | 16,980 | 0.541 | **0.656** | **0.685** | +0.029 |
| Low-restriction (MS, AL, TX) | 61,025 | 1.126 | 0.985 | 0.984 | −0.001 |
| Other | 544,841 | 1.037 | 0.992 | 0.991 | −0.001 |
| Empirically similar (WA, OR, WI) | 35,226 | 0.763 | 1.098 | 1.106 | +0.009 |
| **Gift-ban (VT, MN, ME, MA)** | 38,575 | 0.689 | **1.168** | **1.182** | +0.015 |
| Non-Kaiser org 1,000+ | 149,127 | 0.937 | — | 1.064 | — |

**The prediction was not confirmed, and neither was the failure mode.** The task predicted
research-intensive academic centers would move up, widening the separation from Kaiser. Both
groups moved up slightly, and **Kaiser moved up marginally more** (+0.029 vs +0.015), so the
gap narrows from 0.512 to 0.497 — a 3% change, which is noise.

Phase V's stated expectation that including research would widen the separation was therefore
**mildly wrong in direction and negligible in magnitude**. I am recording that rather than
quietly dropping it.

**What matters is the null result: the R2 discriminant was not substantially reading
research-relationship intensity.** Both reference groups stay pinned at 0.984 and 0.991. The
signature is robust to the inclusion of the payment category most likely to have distorted it.

---

## W5 — The organization/state confound ⭐

Each organization's discriminant computed two ways: against the **national** specialty × volume
expectation (as in Phase R), and against a **state-relative** specialty × volume × state
expectation.

### Group medians, organizations with ≥100 MD/DO prescribers

| Group | n orgs | n physicians | Median, national | **Median, state-relative** | Δ |
|---|---|---|---|---|---|
| **Kaiser entities** | 8 | 16,958 | 0.713 | **0.727** | **+0.014** |
| Orgs in low-restriction states | 179 | 56,176 | 0.978 | 0.976 | −0.002 |
| Orgs elsewhere | 580 | 194,131 | 0.969 | 0.984 | +0.015 |
| **Orgs in gift-ban states** | 53 | 20,876 | **1.130** | **0.994** | **−0.136** |

**Organizations in gift-ban states collapse to 0.994 — average — once scored against their own
state. Kaiser does not move.**

### Kaiser entity by entity

| Organization | n | State | Discriminant, national | **Discriminant, state-relative** |
|---|---|---|---|---|
| PERMANENTE MEDICAL GROUP INC | 6,057 | CA | 0.661 | **0.661** |
| SOUTHERN CALIFORNIA PERMANENTE MEDICAL GROUP | 5,964 | CA | 0.686 | **0.694** |
| KAISER FOUNDATION HEALTH PLAN, MID-ATLANTIC | 1,368 | MD | 0.559 | **0.557** |
| KAISER FOUNDATION HEALTH PLAN OF THE NORTHWEST | 1,049 | OR | 0.806 | **0.785** |
| COLORADO PERMANENTE MEDICAL GROUP PC | 811 | CO | 0.740 | **0.760** |
| KAISER FOUNDATION HEALTH PLAN OF WASHINGTON | 796 | WA | 0.874 | **0.792** |
| **THE SOUTHEAST PERMANENTE MEDICAL GROUP** | 482 | **GA** | 0.591 | **0.601** |
| **HAWAII PERMANENTE MEDICAL GROUP INC** | 431 | **HI** | 0.742 | **0.794** |

**All eight hold. The signature is invariant to state-relative scoring**, including in Georgia —
a low-restriction state where the local baseline is high engagement — and Hawaii. Southeast
Permanente at 0.601 against its own state's expectation is the single cleanest piece of evidence
in the project that this is an organizational property.

### The formerly high-discriminant organizations

| Organization | n | State | National | **State-relative** | Δ |
|---|---|---|---|---|---|
| THE GENERAL HOSPITAL CORPORATION | 286 | MA | 2.059 | **1.664** | −0.395 |
| UNIVERSITY OF VERMONT MEDICAL CENTER | 532 | VT | 1.888 | **1.212** | **−0.677** |
| FAIRVIEW CLINICS | 309 | MN | 1.759 | 1.864 | +0.105 |
| OSU GENERAL INTERNAL MEDICINE LLC | 149 | OH | 1.672 | 1.657 | −0.015 |
| EVANS MEDICAL FOUNDATION INC | 332 | MA | 1.610 | 1.277 | −0.333 |
| MAYO CLINIC HEALTH SYSTEM–SE MINNESOTA | 165 | MN | 1.506 | 1.320 | −0.186 |
| HENNEPIN HEALTHCARE SYSTEM INC | 375 | MN | 1.471 | 1.136 | −0.335 |
| EMERGENCY PHYSICIANS PROFESSIONAL ASSN | 193 | MN | 1.462 | **0.656** | **−0.806** |
| REGENTS OF THE UNIVERSITY OF CALIFORNIA | 172 | CA | 1.442 | 1.373 | −0.068 |
| ALLINA HEALTH SYSTEM | 1,513 | MN | 1.396 | 1.123 | −0.273 |
| CENTRAL VERMONT MEDICAL CENTER | 110 | VT | 1.334 | **0.664** | **−0.671** |
| GROUP HEALTH PLAN INC | 749 | MN | 1.172 | **0.993** | −0.179 |
| PARK NICOLLET CLINIC | 725 | MN | 1.119 | **1.017** | −0.102 |
| CAMBRIDGE PUBLIC HEALTH COMMISSION | 301 | MA | 1.117 | **0.962** | −0.156 |

**The Vermont and Minnesota organizations were largely measuring Vermont and Minnesota.**
University of Vermont Medical Center falls from 1.888 to 1.212; Central Vermont from 1.334 to
0.664 — *below* average for its state. Group Health Plan, Park Nicollet and Cambridge Public
Health all land at ~1.0.

A minority genuinely survive: Mass General (1.664), Fairview Clinics (1.864), OSU (1.657),
University of Rochester (1.352), Duke (1.224), HealthPoint (1.385). These are organizations whose
channel mix differs from their own state's norm.

### W5 verdict — and the required reframing

**The Phase R organization-level discriminant result was substantially a state artifact on the
high side, and is not on the low side.** Stated as the task required:

- **At state level**, the gift-ban signature is real: F&B suppressed, relationship relatively
  preserved, discriminant 1.182. Evidence base: 52 states, four named gift-ban states, a clean
  reference group at 0.984.
- **At organization level**, the contact-ban signature is real and *independent of state*:
  discriminant 0.727 state-relative, holding across eight entities in seven states including
  low-restriction ones. Evidence base: one organization family.
- **The high-discriminant organization list from Phase R does not constitute independent
  evidence.** Those organizations mostly inherit their state's signature. Individual survivors
  (Mass General, Fairview, OSU, Rochester, Duke) are suggestive but are a handful of units with
  no policy data attached.

**These are two findings with two evidence bases, not one unified discriminant.** Phase R
presented them as a single continuous measure ranging from Kaiser to academic centers; that
presentation overstates the organization-level evidence and must be split.

---

## Corrected figures

| Figure | Phase R value | **Corrected** | Reason |
|---|---|---|---|
| **National never-engaged, adjusted** | 450,534 (**64.67%**) | **443,389 (63.65%)** | 7,145 meal-only physicians have research payments and are engaged |
| Fully engaged (four-cell) | 205,244 (29.46%) | 212,389 (30.49%) | Research folded into non-F&B |
| Meal-only | 304,109 (43.65%) | 296,964 (42.63%) | " |
| Relationship-only | 8,715 (1.25%) | 10,555 (1.52%) | " |
| No record in window | 178,579 (25.63%) | 176,739 (25.37%) | " |
| Gift-ban discriminant | 1.168 | 1.182 | Research included |
| Kaiser discriminant | 0.656 | 0.685 | " |

**Framing corrections (no number changes):**

| Item | Change |
|---|---|
| Phase V's caveat that baseline research-safety "rests on documentation, not data" | **Remove.** Verified in W1. |
| Phase V's expectation that research would widen the R2 separation | **Withdraw.** It narrowed it by 3%. |
| Phase R's organization-level discriminant table | **Must be presented state-relative.** The high side is largely a state artifact. |
| Phase R's framing of one continuous discriminant | **Split into two findings** — state-level gift-ban, organization-level contact-ban. |

**Unchanged:** the 553 and $0.924 B; the 17,108 and $8.21 B; 146,459 and 21.02%; the variance
decomposition; the clustering VIFs; the state ordering and Spearman ρ = 0.845; every Phase A and
Extension figure.

---

## Final numbers — supersedes Phase R's R5 table

**Definition and window are part of every number.**

### Population and denominators

| # | Figure | Value | Definition | Window | Caveat |
|---|---|---|---|---|---|
| 1 | All Part D 2024 prescribers | 1,416,883 | — | 2024 | — |
| 2 | **MD/DO Part D prescribers** | **696,647** | — | 2024 | True primary taxonomy, not slot 1 |
| 3 | **MD/DO never engaged** | **146,459 (21.02%)** | Baseline | Cumulative, **all categories** | **W1-verified**; 15,235 blank-NPI rows inflate one-directionally |
| 4 | **MD/DO never engaged, adjusted** | **443,389 (63.65%)** | F&B-adj + research | PY2021–25 | **Corrected from 64.67%**; upper bound; 2013–20 unobserved |
| 5 | MD/DO with ≥1 general payment | 518,068 | — | PY2021–25 | — |
| 6 | MD/DO with ≥1 research payment | 41,524 (5.96%) | Any of 6 NPI fields | PY2021–25 | 70% found only via PI fields |
| 7 | MD/DO with ownership interest | 4,134 (0.59%) | — | PY2021–25 | — |
| 8 | Ever-engaged unclassifiable by channel | 32,159 (5.85%) | — | PY2021–25 | Pre-2021 engagement |

### The white space

| # | Figure | Value | Definition | Window | Caveat |
|---|---|---|---|---|---|
| 9 | **High-volume never-engaged** | **17,108** | Baseline | Cumulative | Volume decile ≥9 |
| 10 | Their claims / cost | 97.9 M / **$8.21 B** | Baseline | Cumulative | 8.12% of claims, 3.89% of cost |
| 11 | **Selection-robust group (≥9)** | **553 / $0.924 B** | Baseline | Cumulative | **Zero in general, research or ownership, PY2021–25** |
| 12 | Selection-robust range | 553–3,896 / $0.9–3.0 B | Baseline | Cumulative | Always state the threshold |
| 13 | Adjusted equivalent (≥9) | 6,175 / $9.878 B | F&B-adj | PY2021–25 | ~11× the baseline figure — never mix |

### Channel

| # | Figure | Value | Definition | Window | Caveat |
|---|---|---|---|---|---|
| 14 | F&B-only among paid MD/DOs | 58.7% | General only | PY2021–25 | Was 74.86% on one year |
| 15 | Median general-payment footprint | 16 records / $705 / 4 of 5 yrs | — | PY2021–25 | — |
| 16 | **Fully engaged** | **212,389 (30.49%)** | Three categories | PY2021–25 | Corrected |
| 17 | **Meal-only** | **296,964 (42.63%)** | Three categories | PY2021–25 | Corrected |
| 18 | **Relationship-only** | **10,555 (1.52%)** | Three categories | PY2021–25 | Corrected |
| 19 | **No record** | **176,739 (25.37%)** | Three categories | PY2021–25 | Corrected |
| 20 | **Research-only** | **1,840 (0.26%)** | Three-axis | PY2021–25 | New |
| 21 | Research dollars, MD/DO | $32.95 B; median $88,238 | — | PY2021–25 | **Institutional trial funding, not physician income** |

### Structure

| # | Figure | Value | Definition | Caveat |
|---|---|---|---|---|
| 22 | State spread | 8.38× | Baseline | VT 60.89% → MS 7.26% |
| 23 | State spread, adjusted | 1.30× | F&B-adj 5yr | — |
| 24 | **Spearman ρ, base vs adjusted** | **0.845** | — | Ordering survives; Phase S's 0.121 superseded |
| 25 | Specialty variance explained | 12.63% / 19.47% | Base / adj | Out-of-sample |
| 26 | State variance explained | 4.22% | Baseline | 7.79% within FP+IM |
| 27 | Rurality variance explained | 0.07% | Baseline | Effectively zero |
| 28 | Org clustering VIF | 128.1 / 26.9 | Base / adj | vs specialty × volume × state |
| 29 | Org split-half reliability | r = 0.897 | Adjusted | Clustering reproducible |
| 30 | **Residual unexplained** | **76.70% / 78.09%** | Base / adj | The most durable finding |
| 31 | Group-size gradient | 2.93× / 1.15× | Base / adj | Direction survives |
| 32 | Kaiser never-engaged | 51.2% / 82.5% | Base / adj | vs 21.02% / 64.67% national |
| 33 | **Gift-ban discriminant, state level** | **1.182** | Three categories | 52-state reference at 0.984 |
| 34 | **Kaiser discriminant, state-relative** | **0.727** | Three categories | **Holds in all 8 entities, 7 states** |
| 35 | **Gift-ban-state orgs, state-relative** | **0.994** | Three categories | **Collapses — state artifact** |
| 36 | Relationship-only, VT vs MS | 6.42% vs 0.15% | General only | 43× |

### Validity anchors

| # | Figure | Value | Note |
|---|---|---|---|
| 37 | Research NPIs absent from supplement | **2 of 59,213 (0.003%)** | **Supplement verified all-category** |
| 38 | Ownership NPIs absent from supplement | **0 of 5,640** | " |
| 39 | Physicians paid 2021 (general) absent | 0 of 770,465 | Phase R |
| 40 | Median annual payment, 2021→2025 | $222 → $294 | vs published $201 (2015) |
| 41 | Single-year engagement, office-based | 63.50% | vs published ~two-thirds |
| 42 | Part D / NPPES state agreement | 98.21% | — |
| 43 | DAC coverage of MD/DOs | 79.96% | Residual confound 4.07 pts |

### Standing limitations

1. **Drug samples and detailing are never reportable.** "Never engaged" must be worded
   **"never received a reported industry payment."** This cannot be closed with more data.
2. **2013–2020 unobserved** — 5.85% unclassifiable by channel.
3. **The organization-level contact-ban signature rests on one organization family.**
4. **No policy inventory**; no legal classification is applied anywhere.
5. **Phase A's A2 matched-window test** remains unrun although the files now exist.
6. **Descriptive only.** Physicians select into organizations and states.

---

## What surprised me

**1. Zero. Not "near-zero" — zero.** 146,459 baseline never-engaged physicians, 4.75 million
research records, 20,245 ownership records, and not one intersection. I expected a handful from
data drift alone, as I did with the 553. The Profile Supplement is a cleaner instrument than the
project has been treating it as, and the central logic — absent from the supplement means never
engaged — is now verified rather than assumed.

**2. The principal-investigator fields were 70% of the research population.** 54,119 physicians
appear as PIs against 16,210 as covered recipients. Had I used only `Covered_Recipient_NPI` — the
obvious field, and the one that matches the general-payments schema — W1 would have tested
roughly a quarter of the relevant population and still returned "zero," and I would have reported
a much weaker result as though it were decisive. Phase V flagging both fields turned out to
matter more than anything else in the file handling.

**3. W5 undercut a Phase R result I had presented as a single finding.** The ten
highest-discriminant organizations were, mostly, ten organizations in Vermont, Minnesota and
Massachusetts. Scored against their own states they collapse to 0.994. Kaiser doesn't move at
all. **I had reported a continuous organizational spectrum; what exists is one organizational
result and one geographic result that happened to be measured on the same scale.** The Phase R
table is not wrong arithmetically, but it invited exactly the wrong reading, and I wrote it.

**4. Southeast Permanente in Georgia at 0.601 state-relative.** Georgia's baseline is high
engagement, so a state-relative score should be the hardest test Kaiser faces, and it is the
second-strongest Kaiser result in the set. One organization carrying its own signature into the
state least like it, twice (Phase R found the same for never-engagement rate), is worth more than
the two California entities with forty times the sample.

**5. Research is 100× larger per physician and changes almost nothing.** $32.95 B, median
$88,238 per physician with any research, against a $705 median general-payment footprint — and
folding it in moves no channel cell by more than 1.03 points and the discriminant by 0.03. The
two payment systems barely overlap in population. It is a useful reminder that dollar magnitude
and population reach are unrelated axes, and this project is about reach.

**6. My own Phase V prediction was wrong.** I reasoned that research would lift academic centers
more than Kaiser and widen the separation. Kaiser gained more (+0.029 vs +0.015). The magnitude
is negligible so nothing turns on it, but the direction was backwards, and I had stated it with
more confidence than a piece of untested reasoning deserved.

---

## Question before proceeding — deletion

Per the rules I have **not deleted anything**. The ten source CSVs are verified row-for-row
against their Parquet equivalents and are safe to remove:

| Files | Disk |
|---|---|
| `OP_DTL_RSRCH_PGYR2021..2025_*.csv` | 4.3 GB |
| `OP_DTL_OWNRSHP_PGYR2021..2025_*.csv` | 8.4 MB |
| **Total reclaimable** | **~4.3 GB** |

Also still on disk from earlier phases: `OP_DTL_GNRL_PGYR2025_*.csv` (8.6 GB), likewise verified.

**Say the word and I will delete them.** Nothing has been removed without explicit instruction.

## Files produced

| Path | Rows | Contents |
|---|---|---|
| `work/op_rsrch_py2021..2025.parquet` | 4,747,581 | Research payments, all 252 columns |
| `work/op_ownrshp_py2021..2025.parquet` | 20,245 | Ownership/investment, all 30 columns |
| `work/phase_w_base.parquet` | 696,647 | Phase R base plus research and ownership flags, dollars and years; four-cell classification with research folded in; three-axis classification |
