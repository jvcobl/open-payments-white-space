# Phase A Extension — Cost-Per-Claim Segmentation

Generated 2026-08-02. Descriptive only. Continuation of `PHASE_A_FINDINGS.md`.

**Output choice:** written as a separate file rather than appended, because E1 materially
qualifies a claim made in Phase A and I would rather that correction be visible as its own
document than buried in a section append. Phase A is left unedited; the correction is stated
below and should be read alongside it.

---

## Headline

**E3 target cell — high volume AND high cost per claim AND never engaged:**

| | Value |
|---|---|
| Prescribers | **553** |
| Claims | 2,408,917 |
| Drug cost | **$0.924 B** |
| Share of MD/DO claims | 0.200% |
| Share of MD/DO drug cost | 0.438% |
| Share of the 17,108 high-volume never-engaged | 3.23% |
| Share of all never-engaged MD/DO drug cost | 6.81% |

**This is small, and I am reporting it plainly as the task asked.** Of the 17,108 high-volume
never-engaged MD/DOs that Phase A headlined, only **553 — 3.2%** also prescribe at a high cost
per claim. The other 96.8% are high-volume *generic* prescribers, which is exactly what the
selection story predicts.

It is also **highly threshold-sensitive**: 3,896 at decile ≥8, 553 at ≥9, and **11** at ≥10.
The group does not survive a stricter cut in any meaningful form.

**E1 verdict — predominantly composition, but not entirely.** The pooled cost-per-claim gap
(never-engaged at 0.537× engaged) falls to **0.858× after standardizing for specialty mix**.
Roughly **69% of the Phase A gap is specialty composition**; a genuine within-specialty
difference of about 14% remains. It reverses direction in 14 of 54 specialties.

### ⚠️ This corrects an interpretation in Phase A

Phase A reported the cost-per-claim gap held "in every decile without exception" and concluded:
*"This is not a volume artifact — volume is held approximately constant within each decile. It
is a difference in what is being prescribed."*

The first sentence is correct. **The conclusion drawn from it was too strong.** Volume deciles
hold volume constant; they do not hold *specialty* constant. Once specialty is controlled, most
of the gap disappears. The correct statement is that the pooled gap is mostly a composition
effect — never-engaged physicians are concentrated in low-cost-per-claim specialties — with a
real but much smaller behavioural residual on top.

The Phase A sizing implication is unchanged and still holds: 8.12% of claims versus 3.89% of
cost is an arithmetic fact about the population as it exists, and a claims-based commercial
estimate still overstates a spend-based one by ~2×. What changes is the *explanation*, not the
adjustment.

### What this data cannot do

It cannot distinguish **selection** (industry screened out generic prescribers) from
**treatment** (engagement causes brand prescribing). Nothing below should be read as evidence
for either. A cross-sectional association between engagement status and prescribing mix is
consistent with both, and with reverse causation and confounding besides. Per the task, I have
not attempted to separate them.

---

## E1 — The specialty-composition control ⭐

### Denominator check first

```sql
SELECT count(*) AS n, min(tot_clms) AS min_clms,
       count(*) FILTER (WHERE tot_clms IS NULL OR tot_clms=0) AS bad_denom,
       count(*) FILTER (WHERE tot_drug_cst=0) AS zero_cost
FROM mddo;
-- 696,647 | 11 | 0 | 26
```

Cost per claim is `tot_drug_cst / tot_clms`. Both fields are unsuppressed for all 696,647
MD/DOs (Phase A / recon Q8), and `Tot_Clms` has a hard floor of 11 because CMS excludes
prescribers below that. **There is no denominator problem**: zero null or zero-valued
denominators. 26 physicians have exactly $0 drug cost, giving a legitimate cost per claim of 0;
they are retained.

### The pooled gap, three ways

```sql
SELECT round(sum(tot_drug_cst) FILTER (WHERE never_engaged)/sum(tot_clms) FILTER (WHERE never_engaged),2) AS never,
       round(sum(tot_drug_cst) FILTER (WHERE NOT never_engaged)/sum(tot_clms) FILTER (WHERE NOT never_engaged),2) AS ever
FROM mddo;
```

| Measure | Never engaged | Ever engaged | Ratio |
|---|---|---|---|
| Aggregate (Σcost / Σclaims) | $99.08 | $184.56 | **0.537** |
| Median of individual cost/claim | $53.55 | $81.99 | 0.653 |
| Mean of individual cost/claim | $112.43 | $267.56 | 0.420 |

The three disagree substantially, which matters. The mean is dragged by a small number of
extreme specialty-drug prescribers (max cost per claim is $158,313); the median is the most
robust individual-level statistic and shows the *smallest* gap. Phase A's "roughly half" came
from the aggregate ratio. The honest range for the pooled gap is **0.42–0.65 depending on the
statistic chosen**, and the median figure of 0.653 is the one I would quote.

### Within-specialty comparison

Specialties with n ≥ 500 and ≥ 30 never-engaged (54 specialties):

```sql
SELECT count(*) AS n_specialties,
  count(*) FILTER (WHERE agg_never < agg_ever) AS agg_gap_same_direction,
  count(*) FILTER (WHERE med_never < med_ever) AS median_gap_same_direction,
  round(median(agg_never/agg_ever),3) AS median_of_agg_ratios,
  round(min(med_never/med_ever),3) AS min_ratio, round(max(med_never/med_ever),3) AS max_ratio
FROM spec;
```

| Result | Value |
|---|---|
| Specialties tested | 54 |
| Gap in the same direction (aggregate) | **40 of 54 (74.1%)** |
| Gap in the same direction (median) | 37 of 54 (68.5%) |
| Median within-specialty ratio (aggregate) | **0.822** |
| Median within-specialty ratio (median) | 0.834 |
| Range of within-specialty ratios | 0.352 to **2.402** |

**The gap reverses in 14 of 54 specialties.** Phase A's "without exception" framing was true
across volume deciles but is not true across specialties.

Largest specialties:

| Specialty | n | n never | Median cost/claim, never | ever | Ratio |
|---|---|---|---|---|---|
| Internal Medicine | 127,181 | 33,622 | $73.70 | $87.81 | 0.839 |
| Family Practice | 115,717 | 28,936 | $68.72 | $82.98 | 0.828 |
| Emergency Medicine | 55,489 | 26,194 | $17.21 | $16.46 | **1.046** |
| Obstetrics & Gynecology | 33,058 | 3,622 | $60.93 | $71.77 | 0.849 |
| Psychiatry | 23,311 | 7,194 | $50.93 | $82.25 | 0.619 |
| General Surgery | 21,382 | 1,593 | $18.90 | $16.11 | **1.174** |
| Orthopedic Surgery | 20,521 | 363 | $10.42 | $9.80 | **1.064** |
| Hospitalist | 20,057 | 7,078 | $69.83 | $66.25 | **1.054** |
| Ophthalmology | 19,063 | 1,085 | $54.03 | $89.17 | 0.606 |
| Cardiology | 19,002 | 661 | $187.08 | $183.55 | **1.019** |
| Psychiatry & Neurology | 15,996 | 6,785 | $41.83 | $68.35 | 0.612 |
| Neurology | 14,434 | 1,202 | $141.02 | $274.14 | **0.514** |
| Gastroenterology | 14,350 | 611 | $253.13 | $321.74 | 0.787 |
| Dermatology | 14,070 | 1,004 | $151.32 | $281.80 | **0.537** |
| Urology | 10,771 | 365 | $42.09 | $100.57 | **0.419** |
| Pulmonary Disease | 9,710 | 530 | $357.22 | $451.40 | 0.791 |
| Nephrology | 9,148 | 439 | $109.54 | $161.49 | 0.678 |
| Hematology-Oncology | 9,054 | 215 | $1,647.69 | $2,355.32 | 0.700 |
| General Practice | 8,847 | 2,003 | $34.96 | $58.83 | 0.594 |

The reversals cluster in one recognisable place: **hospital-based and procedural specialties**
(Emergency Medicine, General Surgery, Orthopedic Surgery, Hospitalist, Otolaryngology,
Cardiology). These have low absolute cost per claim in both groups — Orthopedics is $10 versus
$10 — so the ratio is unstable and not commercially meaningful. The largest genuine gaps sit
where an expensive branded alternative exists: Urology 0.419, Neurology 0.514, Dermatology
0.537, General Practice 0.594, Ophthalmology 0.606.

### Direct standardization — the decisive number

Giving the never-engaged group the ever-engaged group's specialty mix, claim-weighted:

```sql
WITH s AS (
  SELECT partd_specialty AS sp,
    sum(tot_clms) FILTER (WHERE never_engaged) AS cl_n, sum(tot_drug_cst) FILTER (WHERE never_engaged) AS co_n,
    sum(tot_clms) FILTER (WHERE NOT never_engaged) AS cl_e, sum(tot_drug_cst) FILTER (WHERE NOT never_engaged) AS co_e
  FROM mddo WHERE partd_specialty IS NOT NULL GROUP BY 1
  HAVING sum(tot_clms) FILTER (WHERE never_engaged)>0 AND sum(tot_clms) FILTER (WHERE NOT never_engaged)>0)
SELECT round(sum(co_n)/sum(cl_n),2) AS never_crude, round(sum(co_e)/sum(cl_e),2) AS ever_crude,
       round((sum(co_n)/sum(cl_n))/(sum(co_e)/sum(cl_e)),3) AS crude_ratio,
       round(sum(cl_e*(co_n/cl_n))/sum(cl_e),2) AS never_standardized,
       round((sum(cl_e*(co_n/cl_n))/sum(cl_e))/(sum(co_e)/sum(cl_e)),3) AS standardized_ratio
FROM s;
```

| | Cost per claim | Ratio to engaged |
|---|---|---|
| Engaged (observed) | $184.56 | 1.000 |
| Never engaged (observed, crude) | $99.08 | **0.537** |
| Never engaged (standardized to engaged specialty mix) | **$158.31** | **0.858** |

The crude deficit is 46.3%; the specialty-standardized deficit is 14.2%. **Composition accounts
for roughly 69% of the pooled gap** ((0.463 − 0.142) / 0.463), leaving about 31% as a genuine
within-specialty difference.

**Verdict: predominantly a composition effect, with a real residual.** Both halves need
reporting. Saying "never-engaged physicians are generic prescribers" is mostly restating that
they are disproportionately emergency physicians, hospitalists, and psychiatrists. But a ~14%
within-specialty gap is not nothing, and it is concentrated in exactly the specialties where
brand alternatives exist.

---

## E2 — Cost-per-claim distribution

```sql
SELECT CASE WHEN never_engaged THEN 'never engaged' ELSE 'ever engaged' END AS grp, count(*) AS n,
  round(quantile_cont(cpc,0.10),2) AS p10, ..., round(quantile_cont(cpc,0.99),2) AS p99, round(max(cpc),0) AS max
FROM mddo GROUP BY 1;
```

| Group | n | p10 | p20 | p30 | p40 | p50 | p60 | p70 | p80 | p90 | p99 | max |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ever engaged | 550,188 | 11.57 | 23.78 | 44.42 | 63.98 | **81.99** | 102.96 | 137.71 | 218.52 | 488.39 | 3,552.95 | 158,313 |
| Never engaged | 146,459 | 10.77 | 16.97 | 25.90 | 39.22 | **53.55** | 69.76 | 87.87 | 114.29 | 179.31 | 1,263.29 | 92,801 |

The distributions are nearly identical at the bottom (p10: $10.77 vs $11.57) and diverge
steadily upward — the ratio falls from 0.93 at p10 to 0.52 at p80 and 0.37 at p90. **The gap is
entirely in the upper half of the distribution.** Low-cost-per-claim prescribing is equally
common in both groups; what engaged physicians have that never-engaged physicians largely lack
is a high-cost-per-claim tail.

Never-engaged rate by cost-per-claim decile:

| Decile | Cost/claim range | n | Never engaged | % never |
|---|---|---|---|---|
| 1 | $0–11.34 | 69,665 | 16,148 | 23.18 |
| 2 | $11.34–21.38 | 69,665 | 21,290 | **30.56** |
| 3 | $21.38–38.86 | 69,665 | 20,805 | 29.86 |
| 4 | $38.86–57.69 | 69,665 | 18,886 | 27.11 |
| 5 | $57.69–75.56 | 69,665 | 15,733 | 22.58 |
| 6 | $75.56–94.78 | 69,665 | 14,421 | 20.70 |
| 7 | $94.78–123.41 | 69,665 | 13,335 | 19.14 |
| 8 | $123.41–187.45 | 69,664 | 12,092 | 17.36 |
| 9 | $187.45–414.86 | 69,664 | 8,460 | 12.14 |
| 10 | $414.89–158,312.71 | 69,664 | 5,289 | **7.59** |

Monotonic from decile 2 down to decile 10, 30.56% → 7.59%. **Decile 1 breaks the pattern**
(23.18%, below deciles 2–4): the very cheapest prescribers are disproportionately emergency
physicians and surgeons writing short generic courses, who are engaged at low rates for
structural reasons unrelated to cost. This is the composition effect from E1 showing up again.

---

## E3 — The two-way cut

Volume decile × cost-per-claim decile, both computed over the full MD/DO population. Cell values
are **never-engaged rate (%)**.

| Vol ↓ / CPC → | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| **1** | 30.4 | 35.8 | 34.9 | 35.1 | 32.9 | 32.3 | 33.1 | 31.3 | 31.7 | 24.6 |
| **2** | 24.8 | 32.3 | 34.3 | 32.1 | 31.1 | 31.2 | 30.4 | 30.2 | 28.8 | 18.5 |
| **3** | 21.2 | 32.4 | 33.9 | 30.7 | 29.1 | 27.6 | 28.9 | 27.3 | 21.4 | 14.3 |
| **4** | 20.6 | 33.3 | 32.1 | 28.5 | 28.5 | 27.9 | 26.0 | 26.4 | 18.5 | 10.9 |
| **5** | 19.6 | 30.4 | 29.4 | 26.3 | 26.6 | 26.9 | 25.8 | 24.4 | 15.8 | 9.8 |
| **6** | 14.2 | 25.1 | 23.0 | 21.8 | 22.8 | 24.0 | 24.0 | 21.2 | 11.2 | 6.8 |
| **7** | 9.1 | 17.1 | 18.6 | 20.4 | 20.7 | 22.0 | 20.1 | 16.1 | 6.7 | 4.8 |
| **8** | 5.5 | 10.4 | 17.1 | 21.9 | 20.2 | 19.4 | 17.3 | 11.4 | 4.7 | 3.3 |
| **9** | 5.8 | 13.7 | **28.1** | **29.9** | 19.6 | 18.0 | 14.5 | 8.4 | 2.8 | 2.6 |
| **10** | 10.5 | 13.1 | 22.2 | **25.2** | 13.8 | 11.6 | 8.3 | 3.4 | 1.5 | **0.6** |

The gradient runs diagonally: never-engagement is highest at low volume and low-to-middling cost
per claim, and collapses toward the high-volume / high-cost corner. **The bottom-right cell —
top-decile volume and top-decile cost per claim — is 0.6% never engaged (11 of 1,712).** Industry
has reached essentially every physician who is both high-volume and high-cost.

**A pocket worth noting:** cells (volume 9–10, cost decile 3–4) run 22–30% never-engaged, far
above their neighbours. These are very high-volume, very cheap prescribers — the generic
primary-care core. It is the single largest concentration of never-engaged physicians with real
prescribing volume in the data, and it is precisely the group the selection objection targets.

### The target cell

```sql
SELECT count(*) AS n, sum(tot_clms) AS claims, sum(tot_drug_cst) AS cost
FROM mddo WHERE never_engaged AND clms_decile>=9 AND cpc_decile>=9;
```

| | Value |
|---|---|
| Prescribers | **553** |
| Claims | 2,408,917 |
| Drug cost | **$923.6 M** |
| Their cost per claim | $383.42 |
| Share of MD/DO claims | 0.200% |
| Share of MD/DO drug cost | 0.438% |
| Share of never-engaged MD/DO cost | 6.81% |
| Share of the 17,108 | 3.23% |

23,797 MD/DOs sit in the high-volume × high-cost quadrant; 553 of them (2.32%) have never been
engaged.

**Verified:** zero of the 553 appear in the Profile Supplement, and zero in PY2025 General
Payments.

**Read plainly: this is a small number.** $924 M is real money and 553 physicians is a callable
list, but it is 0.44% of MD/DO Part D spend. The population that unambiguously survives the
selection objection is roughly 3% of the Phase A headline. Anyone sizing this as a commercial
opportunity should use 553 / $0.92 B, not 17,108 / $8.21 B — those two numbers answer different
questions, and only the first is robust to the objection that industry ignored these physicians
because they prescribe cheaply.

---

## E4 — Composition of the surviving group

n = 553, so all percentages below are noisy; cells under ~20 should be treated as indicative
only.

### Specialty — a decisive shift away from primary care

| Specialty | n | % of 553 | Their drug cost |
|---|---|---|---|
| Internal Medicine | 122 | 22.06 | $178.6 M |
| **Cardiology** | 97 | **17.54** | $108.5 M |
| **Endocrinology** | 67 | **12.12** | $109.6 M |
| **Rheumatology** | 60 | **10.85** | $174.7 M |
| Family Practice | 57 | 10.31 | $75.1 M |
| Psychiatry | 43 | 7.78 | $36.1 M |
| Neurology | 26 | 4.70 | $32.7 M |
| Pulmonary Disease | 15 | 2.71 | $22.4 M |
| Infectious Disease | 15 | 2.71 | $49.1 M |
| Psychiatry & Neurology | 10 | 1.81 | $7.8 M |
| Hematology-Oncology | 4 | 0.72 | $20.8 M |
| Advanced Heart Failure & Transplant Cardiology | 4 | 0.72 | $9.0 M |

**Primary care falls from 87.28% of the 17,108 to 32.37% of the 553.** The surviving group is
specialty medicine: Cardiology, Endocrinology and Rheumatology together are 40.5% of it and
carry $392.8 M — more than Internal Medicine and Family Practice combined ($253.7 M).

This directly answers E4's question, and it changes the commercial character of the finding. The
Phase A white space was a primary-care story. The *selection-robust* white space is a
specialist story — and specifically the three specialties with the most expensive chronic
therapeutic classes in Part D. Rheumatology is the sharpest case: 60 physicians carrying
$174.7 M, the highest cost per physician in the table.

### State — the Phase A pattern persists

| State | n in 553 | % of 553 | % never-engaged *within the high-vol/high-cost cell* |
|---|---|---|---|
| ME | 17 | 3.07 | **22.7** |
| MN | 34 | 6.15 | **15.2** |
| MA | 58 | 10.49 | 9.8 |
| OR | 16 | 2.89 | 7.4 |
| WI | 26 | 4.70 | 7.3 |
| WA | 20 | 3.62 | 5.6 |
| CA | 75 | 13.56 | 3.0 |
| NY | 55 | 9.95 | 2.7 |
| PA | 28 | 5.06 | 2.7 |
| OH | 22 | 3.98 | 2.7 |
| IL | 16 | 2.89 | 2.0 |
| TX | 16 | 2.89 | **0.9** |

**The pattern does not wash out.** The last column is the like-for-like comparison — the
never-engaged share *among* high-volume, high-cost physicians in each state. Maine 22.7%,
Minnesota 15.2%, Massachusetts 9.8%, Wisconsin 7.3% against Texas 0.9%, Illinois 2.0% and Ohio
2.7%. That is a 25× range, holding both volume and prescribing cost constant, in the exact
population industry has the strongest incentive to reach. The state ordering matches Phase A's.

The raw counts are dominated by CA, MA and NY simply because those states have the most
physicians; the rate column is the meaningful one.

Per Decision 3, no legal classification is attached to these states.

### Rurality — still irrelevant

| Category | n | % of 553 |
|---|---|---|
| Metropolitan | 501 | **90.60** |
| Micropolitan | 37 | 6.69 |
| Rural | 7 | 1.27 |
| Small town | 7 | 1.27 |
| Unknown | 1 | 0.18 |

90.60% metropolitan, against 90.9% for never-engaged MD/DOs overall. **Phase A's finding holds
exactly** — rurality carries no information about non-engagement, including in this subgroup.

---

## E5 — Threshold sensitivity

```sql
SELECT th, count(*) AS n, sum(tot_clms) AS claims, sum(tot_drug_cst) AS cost
FROM mddo WHERE never_engaged AND clms_decile>=th AND cpc_decile>=th GROUP BY th;
```

Symmetric thresholds:

| Threshold (both axes) | Prescribers | Claims | Drug cost | % MD/DO cost | Their cost/claim |
|---|---|---|---|---|---|
| ≥ 8 (top 30%) | **3,896** | 11,415,499 | $3.017 B | 1.430 | $264.26 |
| ≥ 9 (top 20%) | **553** | 2,408,917 | $0.924 B | 0.438 | $383.42 |
| ≥ 10 (top 10%) | **11** | 69,190 | $0.041 B | 0.019 | $588.88 |

Asymmetric:

| Definition | Prescribers | Drug cost |
|---|---|---|
| Volume ≥ 9, cost/claim ≥ 8 | 1,747 | $1.701 B |
| Volume ≥ 8, cost/claim ≥ 9 | 1,588 | $1.964 B |
| Volume ≥ 9, cost/claim ≥ 10 | 199 | $0.491 B |
| Volume ≥ 10, cost/claim ≥ 9 | 84 | $0.231 B |

**The count moves by a factor of ~350 across two decile steps** (3,896 → 553 → 11), far faster
than the ~9× you would expect if the two axes were independent. That is the signal itself: the
joint distribution is strongly negatively dependent in the corner. Engagement coverage
approaches saturation as both volume and cost rise, so each step toward the corner removes most
of what remains.

**Does the finding exist only at one threshold?** No — it degrades smoothly and predictably
rather than appearing at a single arbitrary cut. But its magnitude is entirely
threshold-dependent, and there is no natural cut point in the data to prefer. At ≥8 the group is
$3.0 B and arguably interesting; at ≥10 it is 11 physicians and does not exist. **Any headline
built on this cell must state its threshold, and none of the three deserves to be called "the"
number.** I would report ≥8 and ≥9 together as a range: **553–3,896 physicians, $0.9–3.0 B**.

---

## What surprised me

**1. The composition control took most of the finding away, and the direction reverses in a
quarter of specialties.** I expected the E1 control to attenuate the gap somewhat. Removing 69%
of it — and finding 14 of 54 specialties where never-engaged physicians prescribe *more*
expensively — is a much stronger correction than I anticipated when I wrote the Phase A section.
The Phase A decile table was not wrong, but deciles held the wrong variable constant, and I
drew a behavioural conclusion from it that the data does not support. Worth remembering that
"holds in all ten deciles" sounded like strong evidence and was mostly restating a composition
effect.

**2. The surviving group is specialists, not primary care — a complete inversion.** Phase A's
white space was 87% Family Practice and Internal Medicine. Adding one orthogonal filter turns it
into 32% primary care and 40% Cardiology/Endocrinology/Rheumatology. The two findings point at
entirely different commercial targets, sales structures, and message strategies. Whichever gets
carried forward should be an explicit decision rather than an accident of which table someone
reads.

**3. The state effect survives every control I put on it.** Volume held constant (Phase A: 40×
among high-volume). Volume *and* prescribing cost held constant (here: 25× within the
high-volume/high-cost cell, ME 22.7% vs TX 0.9%). Specialty mix is different in Maine than
Texas, so this is not fully adjusted — but a factor this persistent across independent
stratifications is not a composition artifact. Of everything in Phase A and this extension, the
state pattern is the most robust result, and it is the one the task list keeps deliberately
holding at arm's length.

**4. The cost-per-claim distributions are identical at the bottom and only diverge at the top.**
p10 is $10.77 versus $11.57 — a 7% difference. By p90 it is $179 versus $488. Engagement is not
associated with prescribing *somewhat* more expensively across the board; it is associated with
having an expensive tail at all. That shape is more consistent with a small number of specific
high-cost products driving the entire relationship than with a diffuse behavioural difference,
which is a sharper and more testable question for Phase C than "brand versus generic."

**5. The 0.6% cell.** Among top-decile-volume, top-decile-cost MD/DOs — 1,712 physicians —
exactly 11 have never received anything from industry. Whatever else is true about coverage
gaps, at the intersection of high volume and high spend the industry's reach is effectively
total. That is a useful boundary condition: it tells you the engagement machine works, and that
the white space exists everywhere except where the money most obviously is.

---

## Caveats

- **Cost per claim is not brand share.** It confounds therapeutic mix, generic substitution,
  formulary, patient case mix, and 30-day-fill conventions. Phase A Decision 2 removed brand
  metrics for good reason; this measure is cleaner (never suppressed) but answers a blurrier
  question. Do not translate these ratios into brand-prescribing claims.
- **Selection versus treatment is not addressed and cannot be** with cross-sectional data.
- **n = 553 is small** for the E4 breakdowns; state and specialty cells in the teens are
  indicative only.
- **Decile boundaries are population-relative**, computed over all 696,647 MD/DOs, so "high cost
  per claim" means high relative to physicians generally, not relative to specialty peers. A
  specialty-relative version would be a reasonable robustness check and would likely raise the
  primary-care share of the surviving group.
- The 15,235 blank-NPI supplement rows continue to bias every never-engaged figure in one
  direction (Phase A / recon Flag 3).

## Files

No new files written. All analysis reads `work/analytic_population.parquet` from Phase A.
Nothing downloaded, nothing deleted.
