# Phase R — Revision on Cumulative History

Generated 2026-08-02. Descriptive only. Final analytical phase.

Assumes `PHASE_A_FINDINGS.md`, `PHASE_A_EXT_FINDINGS.md`, `PHASE_S_FINDINGS.md`, `PHASE_B_FINDINGS.md`.

**Observation window for all channel classification: PY2021–PY2025 (five program years, 71.2M
payment records).** The baseline never-engaged flag remains cumulative across *all* program years
via the Profile Supplement. Every figure below is labelled with its definition and window.

> **The 2013–2020 gap.** Open Payments begins in 2013; this phase has 2021 onward. 5.85% of
> ever-engaged MD/DOs (32,159) have no payment record in the five-year window and are most likely
> physicians engaged only in 2013–2020. They are held *engaged* under every adjusted definition
> here, which is the conservative choice. Obtaining those years is out of scope. This limitation
> applies to every cumulative claim in this document and is not repeated at each table.

---

## Headline

### R1 — the state collapse does **not** survive as Phase S described it. The magnitude compresses; the ordering does not.

| | Baseline | F&B-adj **1 year** (Phase S) | F&B-adj **5 years** (corrected) |
|---|---|---|---|
| Max / min ratio | 8.38× | 1.16× | **1.30×** |
| SD across states | 10.46 | 2.03 | **4.02** |
| Coefficient of variation | 0.462 | 0.033 | **0.061** |
| **Spearman ρ vs baseline ranking** | 1.000 | **0.121** | **0.845** |

**The dispersion collapse is real and replicates. The rank destruction was an artifact of the
one-year window.** Phase S reported ρ = 0.121 — "the rank ordering essentially dissolves." On
five years it is **0.845**: the same states sit at the top and bottom as under the baseline
definition. Maine, Vermont, Minnesota, Oregon and Washington remain the highest; Kentucky,
Tennessee, Louisiana, Georgia and Florida the lowest.

**Mississippi is the decisive case and Phase S got it backwards.** Phase S's marquee sentence —
*"Mississippi moves from the lowest never-engagement rate in the country (7.26%) to nearly the
highest (65.40%)"* — does not survive. On five years Mississippi lands at **62.30%, rank 40 of
52**, near the *bottom*, where the baseline definition also puts it (rank 52). The one-year
inversion happened because a Mississippi physician's single year of engagement is usually meals
only; give them five years and the non-meal relationship appears.

### R2 — the channel signatures **do** diverge, as predicted, and they discriminate cleanly.

Standardized to national specialty × volume-decile rates. The discriminant is the ratio of
non-F&B preservation to F&B preservation; 1.00 means a group's two channels are suppressed
equally.

| Group | n | F&B ratio | non-F&B ratio | **Discriminant** |
|---|---|---|---|---|
| **Kaiser / Permanente** | 16,980 | 0.541 | **0.355** | **0.656** |
| Low-restriction (MS, AL, TX) | 61,025 | 1.126 | 1.109 | 0.985 |
| All other states | 544,841 | 1.037 | 1.029 | 0.992 |
| Empirically similar (WA, OR, WI) | 35,226 | 0.763 | 0.837 | 1.098 |
| **Gift-ban states (VT, MN, ME, MA)** | 38,575 | 0.689 | **0.805** | **1.168** |

**Gift-ban states suppress the meal and relatively preserve the relationship (1.168). Kaiser
suppresses the relationship *more* than the meal (0.656). The two reference groups sit at
0.985 and 0.992 — essentially exactly 1.00.**

The **relationship-only** cell is the single clearest discriminator:

| Group | relationship-only | fully engaged |
|---|---|---|
| Gift-ban states (VT, MN, ME, MA) | **3.48%** | 20.69% |
| Empirically similar (WA, OR, WI) | 2.55% | 21.48% |
| All MD/DO national | 1.25% | 29.46% |
| **Kaiser / Permanente** | **1.18%** | **8.82%** |
| Low-restriction (MS, AL, TX) | 0.54% | 35.33% |

Vermont is 6.42% relationship-only against Mississippi's 0.15% — a **43× ratio**. Kaiser, despite
being *more* F&B-suppressed than the gift-ban states, sits at the national average on this axis
while its fully-engaged rate is a third of the national one.

**This means the channel signature can distinguish a measurement artifact from a real access
restriction**, which is the question Phase S said the data could not answer. A gift ban removes
the reportable meal and leaves the relationship partly intact; a contact ban removes both. Stated
explicitly, as the task required: **the predicted divergence appears.**

What it would take to validate the discriminant properly is set out in R2 below — it is currently
supported by one contact-ban organization family and four gift-ban states, which is a small
number of independent units, and it has not been tested against a documented policy inventory.

---

## R1 — The state counterfactual on five-year history

### Construction

```sql
-- five-year channel rollup already built as work/mddo_payments_5yr.parquet
(b.never_base OR (p5.npi IS NOT NULL AND p5.n_nonfnb=0)) AS never_fnb5
```

Identical logic to Phase S's S3 primary counterfactual, with the classification window widened
from PY2025 to PY2021–2025. Ever-engaged physicians with no payment in the window keep engaged
status — the conservative choice, unchanged from Phase S.

### National

| Definition | Never-engaged MD/DOs | % of 696,647 |
|---|---|---|
| Baseline (cumulative supplement) | 146,459 | 21.02 |
| F&B-adjusted, 1 year (Phase S) | 425,226 | 61.04 |
| **F&B-adjusted, 5 years** | **450,534** | **64.67** |

### Dispersion, 52 states/territories with n ≥ 500

| Measure | Baseline | 1-year | **5-year** |
|---|---|---|---|
| Max | 60.89 (VT) | 67.17 (VT) | **75.06 (ME)** |
| Min | 7.26 (MS) | 57.77 (MT) | **57.66 (KY)** |
| Max/min | 8.38× | 1.16× | **1.30×** |
| SD | 10.46 | 2.03 | **4.02** |
| CV | 0.462 | 0.033 | **0.061** |
| Spearman ρ vs baseline | 1.000 | 0.121 | **0.845** |

Relative dispersion falls 87% from baseline (CV 0.462 → 0.061) rather than the 93% Phase S
reported. **The compression is real. The reordering is not.**

### The anchor states

| State | n | Baseline | 1-year | **5-year** | Δ 5yr vs base | Rank base | Rank 1yr | **Rank 5yr** |
|---|---|---|---|---|---|---|---|---|
| ME | 3,477 | 44.06 | 63.27 | **75.06** | +31.00 | 3 | 10 | **1** |
| VT | 1,465 | 60.89 | 67.17 | **74.47** | +13.58 | 1 | 1 | **2** |
| PR | 8,665 | 14.68 | 58.06 | 73.65 | +58.97 | 38 | 50 | 3 |
| MN | 13,680 | 45.42 | 63.70 | 71.64 | +26.22 | 2 | 9 | 4 |
| OR | 8,981 | 36.40 | 62.10 | 70.72 | +34.32 | 6 | 17 | 5 |
| WA | 15,295 | 36.50 | 62.07 | 70.34 | +33.85 | 5 | 19 | 7 |
| WI | 12,772 | 38.22 | 61.76 | 69.11 | +30.89 | 4 | 22 | 12 |
| MA | 20,163 | 35.66 | 60.74 | 67.24 | +31.58 | 7 | 28 | 16 |
| … | | | | | | | | |
| **MS** | 4,570 | **7.26** | **65.40** | **62.30** | +55.03 | **52** | **2** | **40** |
| AL | 8,749 | 9.57 | 64.38 | 61.40 | +51.83 | 51 | 3 | 44 |
| TX | 47,868 | 13.55 | 60.91 | 60.64 | +47.09 | 44 | 27 | 47 |
| FL | 47,037 | 11.44 | 59.50 | 60.63 | +49.19 | 49 | 44 | 48 |
| GA | 18,877 | 12.30 | 60.95 | 60.40 | +49.19 | 47 | 26 | 49 |
| LA | 9,474 | 9.90 | 62.42 | 60.39 | +50.49 | 50 | 15 | 50 |
| TN | 12,412 | 14.32 | 60.37 | 58.95 | +44.63 | 40 | 32 | 51 |
| KY | 8,508 | 11.97 | 60.32 | **57.66** | +45.69 | 48 | 34 | **52** |

**Vermont and Maine at the top; Kentucky, Tennessee and Louisiana at the bottom — the same
ordering the baseline gives.** The one-year column ranked Mississippi 2nd and Alabama 3rd, which
is now visibly an artifact.

Puerto Rico is the one large mover the baseline does not anticipate (rank 38 → 3). Its engaged
physicians are overwhelmingly meal-only even across five years; worth a line in any writeup but
it does not affect the mainland pattern.

### R1 verdict

**Does the 8.38× → 1.16× collapse survive?** Partly, and the part that fails is the part Phase S
led with.

- **Magnitude: survives, weakened.** 8.38× → 1.30× (not 1.16×). CV 0.462 → 0.061 (not 0.033).
  Every state still lands in a 17.4-point band.
- **Rank ordering: does not survive.** ρ = 0.845, not 0.121. The state ordering is substantially
  preserved.

**This differs materially from what Phase S reported and supersedes it.** The corrected reading:
food and beverage accounts for most of the *magnitude* of the state gradient but not for its
*direction*. States that look unengaged on the baseline measure really are less engaged, on a
compressed scale, once channel is controlled with an adequate window.

---

## R2 — The channel signature test ⭐⭐

### Four-cell classification, PY2021–2025

```sql
CASE WHEN n_fnb5>0 AND n_nonfnb5>0 THEN '1 fully engaged'
     WHEN n_fnb5>0 AND n_nonfnb5=0 THEN '2 meal-only'
     WHEN n_fnb5=0 AND n_nonfnb5>0 THEN '3 relationship-only'
     ELSE '4 no record' END AS cell4
```

National, all 696,647 MD/DOs:

| Cell | n | % |
|---|---|---|
| Fully engaged (both channels) | 205,244 | 29.46 |
| Meal-only | 304,109 | 43.65 |
| **Relationship-only** | **8,715** | **1.25** |
| No record in window | 178,579 | 25.63 |

Relationship-only is a rare cell nationally — which is what makes it a usable discriminant.

### By state group

| Group | n | fully engaged | meal-only | **relationship-only** | no record | any F&B | any non-F&B |
|---|---|---|---|---|---|---|---|
| Gift-ban (VT, MN, ME, MA) | 38,785 | 20.69 | 28.96 | **3.48** | 46.87 | 49.65 | 24.17 |
| Empirically similar (WA, OR, WI) | 37,048 | 21.48 | 32.94 | **2.55** | 43.03 | 54.42 | 24.03 |
| Other | 559,627 | 29.96 | 44.87 | 1.09 | 24.09 | 74.82 | 31.05 |
| Low-restriction (MS, AL, TX) | 61,187 | 35.33 | 48.37 | **0.54** | 15.77 | 83.70 | 35.86 |

Per state, ordered by F&B reach:

| State | n | any F&B | any non-F&B | **rel-only** | fully | no record |
|---|---|---|---|---|---|---|
| VT | 1,465 | 24.64 | 17.47 | **6.42** | 11.06 | 68.94 |
| MN | 13,680 | 45.31 | 22.72 | 3.63 | 19.09 | 51.06 |
| ME | 3,477 | 46.71 | 18.23 | 2.53 | 15.70 | 50.76 |
| WI | 12,772 | 52.33 | 24.90 | 3.46 | 21.44 | 44.21 |
| MA | 20,163 | 54.92 | 26.67 | 3.33 | 23.34 | 41.75 |
| WA | 15,295 | 55.25 | 23.62 | 2.22 | 21.41 | 42.53 |
| OR | 8,981 | 55.97 | 23.47 | 1.81 | 21.66 | 42.21 |
| NH | 3,321 | 57.90 | 24.57 | 2.83 | 21.74 | 39.27 |
| TN | 12,412 | 81.12 | 37.38 | 0.89 | 36.48 | 17.99 |
| TX | 47,868 | 82.52 | 36.00 | 0.57 | 35.42 | 16.90 |
| KY | 8,508 | 83.22 | 38.33 | 0.82 | 37.51 | 15.96 |
| GA | 18,877 | 83.57 | 36.18 | 0.71 | 35.47 | 15.72 |
| FL | 47,037 | 84.12 | 35.48 | 0.55 | 34.93 | 15.33 |
| AL | 8,749 | 86.78 | 35.49 | 0.55 | 34.94 | 12.68 |
| LA | 9,474 | 87.02 | 36.76 | 0.24 | 36.52 | 12.74 |
| MS | 4,570 | 90.07 | 35.19 | **0.15** | 35.03 | 9.78 |

**Vermont 6.42% relationship-only against Mississippi 0.15% — 43×.** Note this is a *ratio of
compositions*, not of absolute reach: Vermont's non-F&B reach (17.47%) is still below
Mississippi's (35.19%). Gift-ban states receive less of everything; what distinguishes them is
that the meal falls further than the relationship.

### Kaiser / Permanente

| Group | n | fully engaged | meal-only | relationship-only | no record | any F&B | any non-F&B |
|---|---|---|---|---|---|---|---|
| **Kaiser / Permanente** | 16,980 | **8.82** | 31.27 | **1.18** | **58.73** | 40.09 | **9.99** |
| Non-Kaiser org 1,000+ | 149,127 | 32.39 | 38.73 | 2.17 | 26.71 | 71.11 | 34.56 |
| All MD/DO national | 696,647 | 29.46 | 43.65 | 1.25 | 25.63 | 73.11 | 30.71 |

By entity (≥100 prescribers):

| Organization | n | any F&B | any non-F&B | rel-only | fully |
|---|---|---|---|---|---|
| PERMANENTE MEDICAL GROUP INC | 6,057 | 37.76 | 9.01 | 1.29 | 7.73 |
| SOUTHERN CALIFORNIA PERMANENTE MEDICAL GROUP | 5,964 | 45.81 | 11.33 | 1.14 | 10.19 |
| KAISER FOUNDATION HEALTH PLAN, MID-ATLANTIC | 1,368 | 30.70 | 5.63 | 0.88 | 4.75 |
| KAISER FOUNDATION HEALTH PLAN OF THE NORTHWEST | 1,049 | 32.89 | 9.72 | 1.14 | 8.58 |
| COLORADO PERMANENTE MEDICAL GROUP PC | 811 | 38.22 | 11.47 | 0.86 | 10.60 |
| KAISER FOUNDATION HEALTH PLAN OF WASHINGTON | 796 | 34.55 | 10.93 | 1.38 | 9.55 |
| THE SOUTHEAST PERMANENTE MEDICAL GROUP | 482 | 46.68 | 10.37 | 1.04 | 9.34 |
| HAWAII PERMANENTE MEDICAL GROUP INC | 431 | 45.71 | 13.46 | 1.39 | 12.06 |

**Every Kaiser entity shows the same signature in every state it operates**, including Georgia
and Hawaii. Non-F&B reach of 5.6–13.5% against a 30.71% national rate.

### The discriminant among highly F&B-suppressed organizations

Restricting to organizations with ≥100 MD/DO prescribers whose standardized F&B ratio is below
0.55 — i.e. holding "this organization suppresses meals" roughly constant — and ranking by the
discriminant:

| Organization | n | State | ratio F&B | ratio non-F&B | **Discriminant** | rel-only |
|---|---|---|---|---|---|---|
| THE GENERAL HOSPITAL CORPORATION | 286 | MA | 0.436 | 0.824 | **1.889** | 6.29 |
| FAIRVIEW CLINICS | 309 | MN | 0.316 | 0.544 | 1.722 | 4.53 |
| UNIVERSITY OF VERMONT MEDICAL CENTER | 532 | VT | 0.406 | 0.669 | 1.648 | 6.95 |
| OSU GENERAL INTERNAL MEDICINE LLC | 149 | OH | 0.441 | 0.693 | 1.573 | 4.70 |
| HEALTHPOINT | 108 | WA | 0.307 | 0.461 | 1.501 | 1.85 |
| MAYO CLINIC HEALTH SYSTEM–SE MINNESOTA | 165 | MN | 0.502 | 0.732 | 1.458 | 5.45 |
| HENNEPIN HEALTHCARE SYSTEM INC | 375 | MN | 0.547 | 0.795 | 1.454 | 5.87 |
| EVANS MEDICAL FOUNDATION INC | 332 | MA | 0.511 | 0.739 | 1.448 | 5.12 |
| ALLINA HEALTH SYSTEM | 1,513 | MN | 0.540 | 0.753 | 1.394 | 2.51 |
| DUKE UNIVERSITY HEALTH SYSTEM | 198 | NC | 0.545 | 0.712 | 1.307 | 4.55 |
| … | | | | | | |
| MASS GENERAL BRIGHAM SUBURBAN MA | 206 | MA | 0.498 | 0.435 | 0.872 | 1.94 |
| **KAISER FOUNDATION HEALTH PLAN OF WASHINGTON** | 796 | WA | 0.489 | 0.426 | **0.872** | 1.38 |
| **COLORADO PERMANENTE MEDICAL GROUP PC** | 811 | CO | 0.497 | 0.365 | **0.735** | 0.86 |
| **KAISER FOUNDATION HEALTH PLAN OF THE NORTHWEST** | 1,049 | OR | 0.443 | 0.340 | **0.768** | 1.14 |
| **KAISER FOUNDATION HEALTH PLAN, MID-ATLANTIC** | 1,368 | VA | 0.423 | 0.215 | **0.507** | 0.88 |

**Among organizations that suppress meals to a similar degree, the discriminant separates Kaiser
from academic and integrated systems cleanly.** Every Kaiser entity is below 0.9; the
restriction-state academic centers run 1.3–1.9.

### R2 verdict

**The predicted divergence appears.** Gift-ban states show the "relationship intact, meal
illegal" signature (discriminant 1.168, relationship-only elevated 6.4× over low-restriction
states). Kaiser shows the "no rep in the building" signature (discriminant 0.656, both axes
suppressed, relationship-only at the national average while fully-engaged is a third of it).
Reference groups sit at 0.985 and 0.992.

**What this licenses:** the channel signature can distinguish, at group level, a jurisdiction
where the *record* of contact is suppressed from an organization where the *contact itself* is
suppressed. Phase S concluded this distinction was invisible in the data; with a five-year window
and the two-axis classification it is visible.

**What it does not license:** individual-level inference. A single physician with no F&B and no
non-F&B record cannot be assigned to a mechanism.

**What would validate it properly:**

1. **More independent contact-ban units.** The contact-ban side rests almost entirely on one
   organization family. Other closed-panel or documented no-rep systems (Geisinger, Group Health
   successors, VA-affiliated groups, academic centers with published vendor-credentialing bans)
   would need to be identified from a policy source and tested blind.
2. **A documented policy inventory** — state statutes with effective dates, and organizational
   rep-access policies with dates. Phase S already showed the empirical grouping and the named
   legal grouping disagree (West Virginia). No legal classification is applied anywhere here; the
   groupings above are empirical or by organization name only.
3. **A pre/post test.** A state adopting or repealing a gift ban, or a system adopting a rep ban,
   should move the discriminant in a predictable direction. Five years of data supports this and
   it was not run — it is the strongest available validation and is noted as a limitation.
4. **Out-of-sample thresholding.** No cut point is proposed here. The discriminant is reported as
   a continuous measure; treating it as a classifier would require calibration against labelled
   units, which do not exist in this project.

---

## R3 — Phase B recomputed on five-year classification

### B4 — organizational clustering

Poisson-binomial variance inflation, `Σ(kᵢ−eᵢ)²/Σvᵢ`, equal to 1.0 under independence. 3,290
organizations with ≥20 MD/DO Part D prescribers.

| Null model | Baseline | F&B-adj **1yr** (Phase B) | F&B-adj **5yr** |
|---|---|---|---|
| Specialty × volume | 190.4 | 9.7 | **32.4** |
| Specialty × volume × state | **128.1** | **7.6** | **26.9** |

**Clustering under the corrected definition is 26.9×, not 7.6×.** Phase B reported that adjusted
clustering "attenuates by 94%"; the correct figure is **79%**. Organizational clustering is
substantially more robust to the channel control than one year of data suggested.

### B6 — out-of-sample variance decomposition

> ⚠️ **This corrects a coding error in Phase B, not only a window change.** Phase B's scoring
> assigned a floor value of 0.001 to 11,110 held-out physicians whose specialty × state ×
> rurality × volume cell was absent from the training half, because DuckDB's `greatest()` skips
> NULL arguments. Those rows were excluded from the no-organization model but scored — at a
> near-zero probability — in the with-organization model, which penalised organization
> artificially. A full fallback chain (l3 → l2 → l1 → grand mean) fixes it; null predictions are
> now zero. **Phase B's statement that organization "degrades out-of-sample accuracy" under the
> adjusted definition was an artifact and is withdrawn.**

Split-half, empirical-Bayes shrunk (m = 10), organization as an additive shrunk residual offset.
n = 349,208 held out.

| Model | Baseline | F&B-adj 1yr | **F&B-adj 5yr** |
|---|---|---|---|
| Specialty | 12.63% | 2.93% | **19.47%** |
| + state + rurality + volume | 19.53% | 3.16% | 21.21% |
| + group size + facility count | 20.98% | 2.71% | 21.26% |
| + organization | **23.30%** | **3.54%** | **21.91%** |
| **Residual unexplained** | **76.70%** | **96.46%** | **78.09%** |

Corrected incremental contributions:

| | Baseline | F&B-adj 5yr |
|---|---|---|
| Group size + facility | +1.45 pts | +0.05 pts |
| Organization beyond all | +2.32 pts | +0.65 pts |
| **Phase B total** | **+2.77 pts** | **+0.70 pts** |

Organization-level rates are **highly reproducible** across independent halves — split-half
correlation r = 0.928 (baseline), **r = 0.897 (5-year adjusted)**, r = 0.700 (1-year), over 1,408
organizations with ≥25 physicians in each half. The clustering is real; it is simply concentrated
in a minority of organizations, exactly as Phase B's reconciliation showed.

**The headline B6 conclusion is unchanged and now holds under all three definitions: the residual
stays above 75%.** Non-engagement is not predictable from observable public characteristics.
Note that specialty explains **19.47%** under the five-year adjusted definition against 2.93%
under the one-year version — the corrected outcome is far more structured, which is itself
evidence the one-year definition was mostly noise.

### Kaiser

| Definition | Kaiser (n = 16,980) | National | Ratio |
|---|---|---|---|
| Baseline | 51.2% | 21.02% | 2.44× |
| F&B-adjusted 1yr | 67.3% | 61.04% | 1.10× |
| **F&B-adjusted 5yr** | **82.5%** | **64.67%** | **1.28×** |

The Kaiser effect survives the corrected channel control, where under the one-year version it had
nearly vanished.

### Group size — is it still a pure meal-channel artifact?

Standardized to specialty × volume decile:

| Group-size band | Baseline | F&B-adj 1yr | **F&B-adj 5yr** | any F&B (5yr) | any non-F&B (5yr) |
|---|---|---|---|---|---|
| Not in DAC | 23.79 | 52.89 | 70.50 | 68.49 | 23.33 |
| Solo | 17.45 | 63.07 | 64.47 | 77.35 | 31.27 |
| 2–9 | **9.46** | 64.01 | **57.66** | 86.62 | 39.05 |
| 10–49 | 14.32 | 62.90 | 62.21 | 81.60 | 34.36 |
| 50–199 | 16.35 | 62.40 | 63.77 | 79.12 | 32.60 |
| 200–999 | 18.67 | 61.08 | 64.53 | 75.95 | 31.29 |
| **1,000+** | **27.68** | 60.36 | **66.59** | 65.73 | 28.67 |
| **Spread** | **2.93×** | 1.06× (reversed) | **1.15×** (same direction) | 1.32× | 1.36× |

**No — and this reverses a Phase B conclusion.** Under the one-year definition the gradient
inverted (64.01 → 60.36), which Phase B read as proof the group-size effect was purely a meal
artifact. On five years the gradient runs in the **same direction as baseline** (57.66 → 66.59),
attenuated to 1.15× but not reversed.

Equally important: **non-F&B reach now declines with group size too** (39.05% → 28.67%, 1.36×),
where the one-year data showed it flat and non-monotonic. The two channels fall together — 1.32×
and 1.36× — which is the *contact-ban* signature from R2, not the gift-ban one.

**Interpreted in light of R2:** large organizations do not merely suppress the recorded meal.
They suppress representative contact, and both channels fall roughly proportionally. Phase B's
"restricting rep access removes the sandwich, not the relationship" is wrong for organizations —
it is right for gift-ban *states*, and the two mechanisms are genuinely different. This is the
single most useful correction Phase R makes to Phase B.

---

## R4 — The selection-robust group recomputed

### The 553 are unchanged and now more strongly verified

The 553 are defined on the baseline flag, which does not change. But the verification does:

```sql
SELECT count(*) AS n553, count(*) FILTER (WHERE paid_5yr) AS with_any_5yr_payment,
       count(*) FILTER (WHERE cell4='4 no record') AS no_record
FROM 'work/phase_r_base.parquet' WHERE never_base AND clms_decile>=9 AND cpc_decile>=9;
-- 553 | 0 | 553
```

**Zero of the 553 have any payment record across all five program years.** The Extension verified
this against PY2025 alone; it now holds against 71.2M records over five years. The
selection-robust group is genuinely never-engaged on every measure available.

### Threshold sensitivity, both definitions

| Threshold (both axes) | Baseline n | Baseline $ | 5yr-adjusted n | 5yr-adjusted $ |
|---|---|---|---|---|
| ≥ 8 (top 30%) | 3,896 | $3.017 B | 28,968 | $26.07 B |
| ≥ 9 (top 20%) | **553** | **$0.924 B** | **6,175** | **$9.878 B** |
| ≥ 10 (top 10%) | 11 | $0.041 B | 219 | $1.009 B |

**The baseline range stands exactly as the Extension reported it: 553–3,896 physicians,
$0.9–3.0 B.** Under the five-year adjusted definition the equivalent range is **6,175–28,968
physicians, $9.9–26.1 B** — an order of magnitude larger, because the adjusted definition
reclassifies meal-only engagement as non-engagement.

Both are defensible and they answer different questions. The baseline figure is "never received
anything, ever." The adjusted figure is "never had a substantive industry relationship in five
years." **Any writeup must state which it is using**; they differ by roughly 11× in physicians
and 11× in dollars.

### Specialty composition of the adjusted target cell (≥9, 5-year)

| Specialty | in the 553 | in 5yr cell | Their drug cost |
|---|---|---|---|
| Cardiology | 97 | 1,802 | $2,146.1 M |
| Endocrinology | 67 | 827 | $1,510.9 M |
| Internal Medicine | 122 | 704 | $1,261.0 M |
| Neurology | 26 | 432 | $602.9 M |
| **Rheumatology** | **60** | **347** | **$1,077.8 M** |
| Family Practice | 57 | 321 | $510.0 M |
| Pulmonary Disease | 15 | 290 | $469.1 M |
| Psychiatry | 43 | 255 | $263.8 M |
| Ophthalmology | 1 | 249 | $303.2 M |
| Interventional Cardiology | 3 | 218 | $238.6 M |

**The Extension's central qualitative finding strengthens.** Cardiology, Endocrinology and
Rheumatology dominate under both definitions; the adjusted cell is 29.2% those three specialties
by count and carries $4.73 B. The "selection-robust white space is a specialist story, not a
primary-care story" conclusion holds and is no longer resting on 553 observations.

### The rheumatologists

| Definition | n | Drug cost | Distinct organizations |
|---|---|---|---|
| Baseline 553 | 60 | $174.7 M | 44 |
| 5-year adjusted cell | 347 | $1,077.8 M | 209 |

**The dispersion finding is unchanged and now much better powered.** 347 physicians across 209
organizations — a mean of 1.66 each, essentially the same ratio as 60 across 44 (1.36). Phase B's
conclusion stands: **these physicians are institutional in type but not concentrated in
identifiable organizations.** As a commercial target they remain hundreds of separate accounts.

---

## R5 — Consolidated numbers table

Every headline figure in the project, corrected to five-year history. **Definition and window are
part of the number — none of these should be quoted without them.**

### Population and denominators

| # | Figure | Value | Definition | Window | Source | Caveat |
|---|---|---|---|---|---|---|
| 1 | All Part D 2024 prescribers | 1,416,883 | — | 2024 | Phase A | — |
| 2 | Never-engaged, all prescribers | 332,718 (23.48%) | Baseline | Cumulative | Phase A | — |
| 3 | **MD/DO Part D prescribers** | **696,647** | — | 2024 | Phase A | Uses true primary taxonomy, not slot 1 |
| 4 | **MD/DO never engaged** | **146,459 (21.02%)** | Baseline | Cumulative | Phase A | 15,235 blank-NPI supplement rows inflate this one-directionally |
| 5 | **MD/DO never engaged** | **450,534 (64.67%)** | **F&B-adj** | **PY2021–25** | **R1** | Upper bound; 2013–2020 unobserved |
| 6 | MD/DO with ≥1 payment | 518,068 | — | PY2021–25 | R-ingest | — |
| 7 | Ever-engaged unclassifiable | 32,159 (5.85%) | — | PY2021–25 | R-ingest | Was 32.31% on one year |

### The white space

| # | Figure | Value | Definition | Window | Source | Caveat |
|---|---|---|---|---|---|---|
| 8 | **High-volume never-engaged** | **17,108** | Baseline | Cumulative | Phase A | Volume decile ≥9 |
| 9 | Their claims / cost | 97.9 M / **$8.21 B** | Baseline | Cumulative | Phase A | 8.12% of claims but 3.89% of cost |
| 10 | **Selection-robust group (≥9)** | **553 / $0.924 B** | Baseline | Cumulative | Ext. | **Zero have any payment in PY2021–25** (R4) |
| 11 | Selection-robust range | 553–3,896 / $0.9–3.0 B | Baseline | Cumulative | Ext. | Threshold-sensitive; always state the cut |
| 12 | Adjusted equivalent (≥9) | 6,175 / $9.878 B | F&B-adj | PY2021–25 | R4 | ~11× the baseline figure — do not mix |
| 13 | Adjusted range | 6,175–28,968 / $9.9–26.1 B | F&B-adj | PY2021–25 | R4 | — |

### Channel

| # | Figure | Value | Definition | Window | Source | Caveat |
|---|---|---|---|---|---|---|
| 14 | **F&B-only among paid MD/DOs** | **58.7%** (304,109) | — | PY2021–25 | R-ingest | **Was 74.86% on one year — superseded** |
| 15 | Median engaged footprint | 16 records / $705 / 4 of 5 years | — | PY2021–25 | R-ingest | Was 7 records / $293.53 on one year |
| 16 | Fully engaged | 29.46% | Two-axis | PY2021–25 | R2 | — |
| 17 | Meal-only | 43.65% | Two-axis | PY2021–25 | R2 | — |
| 18 | **Relationship-only** | **1.25%** | Two-axis | PY2021–25 | R2 | The discriminant cell; rare by construction |
| 19 | No record | 25.63% | Two-axis | PY2021–25 | R2 | Includes pre-2021-only engagement |

### Structure

| # | Figure | Value | Definition | Window | Source | Caveat |
|---|---|---|---|---|---|---|
| 20 | **State spread** | **8.38×** | Baseline | Cumulative | Phase A | VT 60.89% → MS 7.26% |
| 21 | **State spread, adjusted** | **1.30×** | F&B-adj | PY2021–25 | R1 | **Was 1.16× — superseded** |
| 22 | **Spearman ρ, base vs adjusted** | **0.845** | — | PY2021–25 | R1 | **Was 0.121 — superseded; ordering survives** |
| 23 | Specialty variance explained | 12.63% / 19.47% | Base / F&B-adj | — | R3 | Out-of-sample |
| 24 | State variance explained | 4.22% | Baseline | Cumulative | Phase A | 7.79% within FP+IM |
| 25 | Rurality variance explained | 0.07% | Baseline | Cumulative | Phase A | Effectively zero |
| 26 | **Org clustering VIF** | **128.1** | Baseline | Cumulative | Phase B | vs specialty × volume × state null |
| 27 | **Org clustering VIF, adjusted** | **26.9** | F&B-adj | PY2021–25 | R3 | **Was 7.6 — superseded** |
| 28 | Org split-half reliability | r = 0.897 | F&B-adj | PY2021–25 | R3 | Clustering is reproducible, not noise |
| 29 | **Residual unexplained** | **76.70% / 78.09%** | Base / F&B-adj | — | R3 | **Was 77.76% / ~100% — superseded** |
| 30 | Group-size gradient | 2.93× / **1.15×** | Base / F&B-adj | — | R3 | **Direction survives — Phase B said it reversed** |
| 31 | Facility-count gradient | 1.75× (inverse) | Baseline | Cumulative | Phase B | Opposite direction to group size |
| 32 | **Kaiser never-engaged** | **51.2% / 82.5%** | Base / F&B-adj | — | R3 | vs 21.02% / 64.67% national |
| 33 | **Channel discriminant, gift-ban states** | **1.168** | Two-axis | PY2021–25 | R2 | Relationship preserved vs meal |
| 34 | **Channel discriminant, Kaiser** | **0.656** | Two-axis | PY2021–25 | R2 | Relationship suppressed more than meal |
| 35 | Relationship-only, VT vs MS | 6.42% vs 0.15% | Two-axis | PY2021–25 | R2 | 43× |

### Validity anchors

| # | Figure | Value | Source | Note |
|---|---|---|---|---|
| 36 | **Physicians paid 2021 absent from supplement** | **0 of 770,465** | R-ingest | Confirms the cumulative logic the project rests on |
| 37 | Same, 2022 / 2023 / 2024 | 5 / 1 / 6 | R-ingest | Out of ~900,000 each |
| 38 | Same, 2025 | 432 (0.042%) | R-ingest | Known snapshot-currency artifact |
| 39 | Part D / NPPES state agreement | 98.21% | Phase A | State figures robust to field choice |
| 40 | DAC coverage of MD/DOs | 79.96% | Phase B | Standardized residual confound 4.07 pts |

---

## What surprised me

**1. The Phase S headline was an artifact of the window, and the specific sentence that made it
memorable is the one that broke.** "Mississippi moves from the lowest never-engagement rate in
the country to nearly the highest" was the most quotable line in the project. On five years
Mississippi sits at rank 40 of 52 — near the bottom, where it started. A one-year window
systematically misclassifies high-engagement states, because in any single year most of their
physicians happen to receive only meals. The dispersion collapse replicated; the inversion did
not. **I would not have caught this without the additional years, and it is a caution about
every "the effect disappears under control X" result computed on a short window.**

**2. The discriminant worked, and worked cleanly, which I did not expect.** I expected a
directional hint. Getting gift-ban states at 1.168, Kaiser at 0.656, and both reference groups at
0.985 and 0.992 — essentially exactly 1.00 — is a sharper separation than a two-axis count of
payment categories has any right to produce. That the two reference groups landed on 1.00
independently is what makes me believe the 1.168 and 0.656 rather than treat them as noise.

**3. Phase B's group-size conclusion was wrong in an interesting direction.** I wrote in Phase B
that large organizations "suppress the recorded meal, not the relationship," on the strength of
non-F&B reach being flat across group size. With five years, non-F&B reach falls 1.36× against
F&B's 1.32× — they fall *together*. Large organizations behave like Kaiser, not like Vermont.
The correction makes the Phase B story stronger and simpler, not weaker: practice structure
restricts contact, and state law restricts gifts, and those are different things.

**4. A NULL-handling detail changed a stated conclusion.** Phase B reported that organization
*degrades* out-of-sample accuracy under the adjusted definition (−0.77%). That was 11,110
held-out physicians being scored at p = 0.001 because `greatest()` skips NULLs in DuckDB. The
corrected figure is +0.83%. The finding it supported — "organization adds nothing once the
channel is controlled" — was an artifact. **The split-half reliability of r = 0.897 should have
made me suspicious of it at the time; a strong, reproducible group effect that contributes
negative predictive value is a contradiction, and I reported it instead of resolving it.**

**5. Zero of the 553 appear anywhere in five years of payments.** 71.2 million records, 553
physicians prescribing $924 M, not one appearance. I expected a handful of matches from data
drift alone. The selection-robust group is cleaner than the Extension could establish.

**6. The residual did not move.** Across every correction in this phase — a better window, a
fixed scoring bug, a more structured outcome variable — out-of-sample explanatory power went from
22.24% to 23.30% under baseline and sits at 21.91% under the corrected adjusted definition. **The
single most durable finding in the project is the one that says the population is not
predictable.** Specialty went from explaining 2.93% to 19.47% of the adjusted outcome and the
total barely moved, because the added structure was already captured elsewhere.

---

## Superseded — do not quote these

Every figure below appears in an earlier findings document and should not be carried into the
writeup.

### From `PHASE_S_FINDINGS.md`

| Superseded figure | Was | Now | Where |
|---|---|---|---|
| **State spread after channel control** | **1.16×** | **1.30×** | R1 |
| **Spearman ρ, baseline vs counterfactual** | **0.121** | **0.845** | R1 |
| **SD across states, counterfactual** | 2.03 | 4.02 | R1 |
| **CV across states, counterfactual** | 0.033 | 0.061 | R1 |
| National F&B-adjusted never-engagement | 61.04% | 64.67% | R1 |
| F&B-only share of engaged | 74.86% | 58.7% | R-ingest |
| Median engaged footprint | 7 records / $293.53 | 16 records / $705 | R-ingest |
| Mississippi counterfactual | 65.40% (rank 2) | 62.30% (rank 40) | R1 |
| Vermont counterfactual | 67.17% | 74.47% | R1 |
| Unclassifiable ever-engaged | 32.3% | 5.85% | R-ingest |

**Withdrawn claims:**

- *"Mississippi moves from the lowest never-engagement rate in the country to nearly the
  highest."* **False on five years.** It moves from rank 52 to rank 40.
- *"The rank ordering essentially dissolves."* **False.** ρ = 0.845.
- *"The state effect in this project is, to a first approximation, a meal-channel effect."*
  **Half right.** The *magnitude* is largely meal-channel; the *ordering* is not.
- *S5's conclusion that F&B absence "cannot be distinguished from legal restriction" in
  restriction states.* **Superseded by R2** — the two-axis signature distinguishes them at group
  level.

### From `PHASE_B_FINDINGS.md`

| Superseded figure | Was | Now | Where |
|---|---|---|---|
| **Org clustering VIF, F&B-adjusted** | **7.6** | **26.9** | R3 |
| Org clustering attenuation under adjustment | 94% | 79% | R3 |
| Out-of-sample, baseline, + organization | 22.24% | 23.30% | R3 |
| Out-of-sample residual, baseline | 77.76% | 76.70% | R3 |
| **Out-of-sample, F&B-adj, + organization** | **−0.77%** | **+3.54%** (1yr) / **+21.91%** (5yr) | R3 |
| Phase B total contribution, baseline | +2.74 pts | +2.77 pts | R3 |
| Kaiser, F&B-adjusted | 67.3% | 82.5% | R3 |
| Group-size gradient, adjusted | 1.06× **reversed** | 1.15× **same direction** | R3 |

**Withdrawn claims:**

- *"Under the F&B-adjusted definition nothing predicts anything… organization actually degrades
  out-of-sample accuracy."* **Artifact of a NULL-handling bug.** Organization adds +0.65 pts
  under the corrected definition, and specialty alone explains 19.47%.
- *"F&B reach falls sharply with group size while non-F&B reach barely moves."* **True on one
  year, false on five.** Both fall, 1.32× and 1.36×.
- *"Large organizations suppress the meal channel… while their physicians retain substantive
  industry relationships at an undiminished rate."* **Withdrawn.** Non-F&B reach falls from
  39.05% to 28.67% across group size.
- *Reinterpretation §3, "the F&B channel is the dominant axis of variation in the entire
  engagement measure."* **Overstated.** It dominates one year of data; over five it is one of two
  axes, and the second one carries the organizational signal.

### From `PHASE_A_FINDINGS.md` and `PHASE_A_EXT_FINDINGS.md`

No figure is superseded. Two are **strengthened**:

- The 553 — *"zero appear in the Profile Supplement, and zero in PY2025 General Payments"* now
  extends to **zero in PY2021–2025**, 71.2M records.
- Phase A's open item 1, *"A2 is unfinished — needs PGYR2021–PGYR2024"* — those files are now
  converted and on disk (`work/op_general_py2021..2024.parquet`). **A2's matched-window test was
  not run in this phase** and is noted as a limitation below rather than a proposed phase.

---

## Limitations

- **2013–2020 is unobserved.** 5.85% of ever-engaged MD/DOs (32,159) cannot be channel-classified
  and are held engaged. Every adjusted figure is therefore an upper bound on non-engagement, and
  the "no record" cell in R2 includes physicians engaged only before 2021.
- **R2's discriminant rests on few independent units** — one organization family on the
  contact-ban side, four states on the gift-ban side. No pre/post test was run despite five years
  of data supporting one. No policy inventory was used and no legal classification is applied.
- **The discriminant is descriptive, not a classifier.** No threshold is proposed or validated.
- **DAC coverage is 79.96% and non-random**, with a standardized residual confound of 4.07 points
  under baseline (Phase B B1). All organization and group-size results inherit this.
- **A2's matched observation-window test is still not run.** The files now exist; the test does
  not. Per this phase's rules it is recorded here as an unresolved item, not proposed as further
  work.
- **Selection versus treatment is not addressed and cannot be** with cross-sectional data.
- **The 15,235 blank-NPI supplement rows** continue to bias every never-engaged figure in one
  direction.
- **Research and ownership payment files are not on disk** — General Payments covers ~97% of
  engaged NPIs (recon Q11).
- **Descriptive only.** Physicians select into organizations and into states; nothing here
  supports a causal reading.

---

## Files

| Path | Rows | Contents |
|---|---|---|
| `work/op_general_py2021.parquet` | 11,558,469 | PY2021 General Payments, all 91 columns |
| `work/op_general_py2022.parquet` | 13,322,266 | PY2022 |
| `work/op_general_py2023.parquet` | 14,734,121 | PY2023 |
| `work/op_general_py2024.parquet` | 15,498,687 | PY2024 |
| `work/mddo_payments_5yr.parquet` | 518,068 | One row per MD/DO with ≥1 PY2021–25 payment: record and dollar counts, F&B / non-F&B split, years paid, first/last year |
| `work/phase_r_base.parquet` | 696,647 | Phase B base plus five-year channel history, the corrected `never_fnb5` flag, and the R2 four-cell classification |

All four converted files were verified row-for-row against their source CSVs before those CSVs
were deleted at the user's explicit instruction. Each contains exactly one program year with
99.6–99.7% well-formed NPIs. Everything in `~/whitespace` is intact.
