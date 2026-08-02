# Phase S — The State Mechanism Test

Generated 2026-08-02. Descriptive only. Assumes `PHASE_A_FINDINGS.md` and
`PHASE_A_EXT_FINDINGS.md`.

**Scoping constraint, applied throughout.** The engagement flag in
`work/analytic_population.parquet` is *cumulative* (ever engaged, all program years). Only
PY2025 General Payments is on disk. Every payment-level figure below is therefore **PY2025
only**, and is labelled as such at each point of use. The two populations are never blended.

---

## Headline

**S3 verdict — the state effect does not survive. It collapses.**

Reclassifying physicians whose PY2025 engagement is food-and-beverage-only as never-engaged
takes the state spread from **8.39× to 1.16×**, and the standard deviation across states from
**10.46 points to 2.03**. Mississippi moves from the *lowest* never-engagement rate in the
country (7.26%) to nearly the *highest* (65.40%). Vermont barely moves (60.89% → 67.17%). The
rank ordering essentially dissolves — Spearman ρ between baseline and counterfactual state
rankings is **0.121**.

**S1 — 74.86% of PY2025-engaged MD/DOs have food-and-beverage payments and nothing else**
(278,801 of 372,443, PY2025 only). Their median footprint is 4 payment records totalling
**$171.63**. 36.9% have two records or fewer; 34.89% total under $100 for the year.

**The state effect in this project is, to a first approximation, a meal-channel effect.**

### But the mechanism is subtler than "recording artifact" — read this before using the result

The task framed the hypothesis as gift bans erasing a *recorded channel*. That framing needs
one correction, because it changes what the finding licenses you to say.

The federal Sunshine Act requires manufacturers to report **all** covered meals regardless of
state law. A state gift ban does not make a meal go unrecorded — it stops the meal from
happening. So the collapse above is not evidence that engagement is being hidden.

The actual mechanism is narrower and more interesting: **a rep visit that includes no meal
generates no Open Payments record at all.** Detailing, sampling, and in-office rep contact are
not reportable transfers of value. So in a gift-ban state a rep can still walk the halls; what
disappears is the $14 sandwich that would have made that physician visible in the database.
Two states with identical rep coverage can therefore show a 7× difference in measured
engagement.

**What this data can establish:** the state gradient is carried almost entirely by the F&B
channel. **What it cannot establish:** whether underlying industry *contact* differs by state,
because non-reportable contact is invisible by construction. S4 gives partial evidence that
real engagement is also genuinely lower in restricted states — just far less so than the
headline numbers implied.

---

## S1 — Is food and beverage the entry point?

### Population reconciliation

```sql
SELECT (SELECT count(*) FROM 'work/analytic_population.parquet' WHERE is_mddo) AS mddo_total,
       (SELECT count(*) FROM 'work/analytic_population.parquet' WHERE is_mddo AND NOT never_engaged) AS ever_engaged_cumulative,
       (SELECT count(*) FROM 'work/py2025_mddo_payments.parquet') AS with_py2025_payments;
```

| | n | % of MD/DO |
|---|---|---|
| MD/DO Part D prescribers | 696,647 | 100% |
| Ever engaged (cumulative) | 550,188 | 78.98% |
| **With ≥1 PY2025 General Payment** | **372,443** | **53.46%** |
| Ever engaged but **no** PY2025 payment | 177,784 | 25.52% |

**32.3% of ever-engaged MD/DOs received nothing in PY2025.** That gap is the single largest
source of imprecision in this phase and is why S3 is a directional test rather than an estimate.

39 MD/DOs have PY2025 payments but are flagged never-engaged — the NPI-level inconsistency
reconnaissance found (432 nationally). Negligible; left as-is.

### Distributions (PY2025 payment recipients only, n = 372,443)

| Measure | min | p25 | median | p75 | p90 | p99 | max | mean |
|---|---|---|---|---|---|---|---|---|
| Payment records | 1 | 2 | **7** | 25 | 62 | 188 | 1,120 | 22.5 |
| Total USD | $0.13 | $86.66 | **$293.53** | $1,087.17 | $3,488.99 | $88,194.17 | $20,624,190 | $4,805.66 |

The median engaged physician's entire annual industry footprint is **7 records worth $293.53**.
A quarter of them are at 2 records or fewer and under $87.

### The core question

```sql
SELECT count(*) AS n,
  count(*) FILTER (WHERE n_nonfnb=0) AS fnb_only,
  round(100.0*count(*) FILTER (WHERE n_nonfnb=0)/count(*),2) AS pct_fnb_only,
  count(*) FILTER (WHERE n_fnb>0) AS any_fnb,
  round(100.0*count(*) FILTER (WHERE n_fnb>0)/count(*),2) AS pct_any_fnb
FROM 'work/py2025_mddo_payments.parquet';
```

| | n | % |
|---|---|---|
| **F&B-only (no other category)** | **278,801** | **74.86%** |
| At least one F&B payment | 365,670 | 98.18% |
| No F&B at all | 6,773 | 1.82% |

Nationally, F&B is **89.97% of MD/DO payment records but only 12.81% of dollars** (PY2025).

How marginal is the F&B-only group?

| Measure | p25 | median | p75 |
|---|---|---|---|
| Records | 2 | **4** | 16 |
| Total USD | $57.02 | **$171.63** | $482.35 |

- **36.90%** (102,888) have ≤ 2 payment records for the entire year
- **34.89%** (97,283) total under $100 for the entire year

**Verdict: yes, decisively.** Three-quarters of PY2025-engaged physicians appear in Open
Payments solely through meals, typically four of them worth under $200 in total. Only **13.44%
of all MD/DOs (93,642)** have any non-F&B PY2025 payment. Removing the meal channel removes
most of the engaged population from the database.

---

## S2 — Channel mix by state

Among MD/DOs with PY2025 payment records. States with ≥300 such physicians shown in the main
table; **Vermont has only 176 and is reported separately** rather than dropped, since it is the
state the hypothesis is built on.

### Key states

| State | n phys | % records F&B | % dollars F&B | % F&B-only | median records | median USD |
|---|---|---|---|---|---|---|
| **VT** | 176 | **61.53** | 5.72 | **52.27** | 2 | $143 |
| MN | 3,911 | 67.12 | 4.33 | 63.95 | 3 | $177 |
| DC | 1,380 | 78.11 | 6.99 | 71.52 | 6 | $283 |
| OR | 3,205 | 80.02 | 8.37 | 72.01 | 3 | $172 |
| WI | 4,277 | 80.58 | 11.31 | 70.28 | 3 | $174 |
| NH | 1,224 | 81.29 | 9.58 | 74.92 | 3 | $168 |
| WA | 5,371 | 82.03 | 9.90 | 72.84 | 3 | $191 |
| MA | 7,642 | 82.71 | 8.09 | 66.19 | 4 | $241 |
| ME | 885 | 84.88 | 16.41 | 75.48 | 3 | $149 |
| … | | | | | | |
| TX | 30,313 | 90.57 | 15.28 | 74.81 | 10 | $387 |
| LA | 6,513 | 93.12 | 19.74 | 76.42 | 12 | $387 |
| MS | 3,323 | **93.88** | 21.41 | 79.96 | **11** | $322 |
| AL | 6,110 | **94.24** | 16.55 | 78.49 | 11 | $363 |

### Full table, ranked by % F&B-only (n ≥ 300)

| State | n | %rec F&B | %$ F&B | %F&B-only | | State | n | %rec F&B | %$ F&B | %F&B-only |
|---|---|---|---|---|---|---|---|---|---|---|
| PR | 4,416 | 91.94 | 25.16 | 85.12 | | NC | 11,862 | 88.34 | 10.76 | 74.46 |
| MS | 3,323 | 93.88 | 21.41 | 79.96 | | NV | 2,998 | 89.93 | 17.10 | 74.35 |
| AR | 3,257 | 94.35 | 25.38 | 79.46 | | IN | 7,599 | 91.84 | 16.46 | 74.15 |
| DE | 1,199 | 93.94 | 28.30 | 78.90 | | IL | 14,924 | 87.36 | 10.71 | 74.12 |
| SC | 6,856 | 92.71 | 14.60 | 78.59 | | CT | 4,608 | 89.57 | 13.62 | 73.74 |
| AL | 6,110 | 94.24 | 16.55 | 78.49 | | CO | 5,534 | 85.21 | 9.18 | 73.73 |
| WV | 2,049 | 90.20 | 16.80 | 77.89 | | OH | 14,149 | 89.05 | 11.27 | 73.51 |
| ID | 1,543 | 88.75 | 11.04 | 77.77 | | TN | 7,787 | 91.65 | 8.93 | 73.40 |
| AK | 579 | 91.77 | 25.89 | 77.72 | | RI | 1,278 | 89.45 | 12.74 | 73.24 |
| OK | 4,352 | 93.24 | 20.49 | 77.69 | | VA | 8,585 | 89.44 | 13.28 | 72.85 |
| NJ | 12,697 | 93.14 | 18.84 | 77.62 | | WA | 5,371 | 82.03 | 9.90 | 72.84 |
| KS | 3,261 | 91.02 | 6.08 | 77.61 | | MO | 7,819 | 89.56 | 10.19 | 72.72 |
| MT | 888 | 89.15 | 21.77 | 77.48 | | ND | 744 | 87.80 | 20.02 | 72.58 |
| NE | 2,502 | 92.23 | 17.97 | 77.10 | | OR | 3,205 | 80.02 | 8.37 | 72.01 |
| LA | 6,513 | 93.12 | 19.74 | 76.42 | | AZ | 7,604 | 89.89 | 15.34 | 71.92 |
| PA | 17,319 | 89.77 | 12.91 | 75.91 | | DC | 1,380 | 78.11 | 6.99 | 71.52 |
| SD | 953 | 83.02 | 9.13 | 75.87 | | UT | 2,789 | 87.47 | 10.30 | 71.50 |
| NY | 26,231 | 89.51 | 12.05 | 75.74 | | WI | 4,277 | 80.58 | 11.31 | 70.28 |
| ME | 885 | 84.88 | 16.41 | 75.48 | | MA | 7,642 | 82.71 | 8.09 | 66.19 |
| FL | 29,956 | 90.95 | 14.37 | 75.48 | | MN | 3,911 | 67.12 | 4.33 | 63.95 |
| HI | 1,389 | 93.71 | 28.25 | 75.45 | | *(VT)* | *176* | *61.53* | *5.72* | *52.27* |
| NM | 1,569 | 89.21 | 20.34 | 75.33 | | | | | | |
| WY | 391 | 88.67 | 16.00 | 75.19 | | | | | | |
| MD | 7,069 | 91.27 | 8.48 | 75.14 | | | | | | |
| MI | 12,995 | 89.97 | 14.83 | 75.12 | | | | | | |
| IA | 2,727 | 88.77 | 17.91 | 75.06 | | | | | | |
| CA | 37,760 | 88.95 | 11.99 | 74.99 | | | | | | |
| NH | 1,224 | 81.29 | 9.58 | 74.92 | | | | | | |
| GA | 12,273 | 91.88 | 15.71 | 74.83 | | | | | | |
| TX | 30,313 | 90.57 | 15.28 | 74.81 | | | | | | |
| KY | 5,502 | 92.25 | 14.85 | 74.79 | | | | | | |

**The bottom of this list is the top of the never-engaged list.** VT, MN, MA, WI, OR, WA, NH,
DC and ME occupy nine of the eleven lowest F&B-record-share positions. The relationship is
strongly negative and visible without any modelling.

The intensity measures move together with it. Median payment records per engaged physician:
**VT 2, MN 3, ME 3, OR 3, WA 3, WI 3, NH 3** against **LA 12, TN 12, MS 11, AL 11, KY 11,
GA 11, TX 10**. Engaged physicians in restricted states are not merely fewer — the ones who
are engaged have a much thinner footprint.

**On the unverified hypothesis set** (§S2 instruction): VT, MN, ME, MA, WV and DC were named as
having verified gift-ban or disclosure regimes. VT, MN, ME, MA and DC all sit in the bottom
tenth of F&B share. **WV does not** — it is 90.20% F&B records and 77.89% F&B-only, squarely in
the high-F&B group alongside Mississippi and Alabama. Meanwhile **WA, OR and WI — whose
statutes were explicitly flagged as unchecked — behave exactly like the verified restriction
states.** So the empirical grouping and the named legal grouping agree on five states, disagree
on one, and add three unverified ones. That is worth knowing before anyone treats the legal
hypothesis as settled. No legal classification is applied anywhere in this document.

---

## S3 — The counterfactual ⭐

### Construction

```sql
CREATE TEMP TABLE cf AS
SELECT a.npi, a.partd_state AS state, a.never_engaged AS never_base,
       -- primary: PY2025 engagement that is F&B-only is reclassified as never-engaged
       (a.never_engaged OR (p.npi IS NOT NULL AND p.n_nonfnb=0)) AS never_cf,
       -- sensitivity: also reclassify ever-engaged with NO PY2025 payment at all
       (a.never_engaged OR p.npi IS NULL OR p.n_nonfnb=0)        AS never_cf_strict
FROM 'work/analytic_population.parquet' a
LEFT JOIN 'work/py2025_mddo_payments.parquet' p ON a.npi=p.npi
WHERE a.is_mddo;
```

The primary counterfactual follows the task literally: only physicians with an F&B-only PY2025
footprint are reclassified. **Ever-engaged physicians with no PY2025 payment keep their engaged
status**, which is the conservative choice — it is the assumption least likely to manufacture a
collapse. The strict variant reclassifies them too and is reported for sensitivity.

### National

| Definition | Never-engaged MD/DOs | % |
|---|---|---|
| Baseline (cumulative) | 146,459 | 21.02 |
| **Counterfactual (F&B-only reclassified)** | 425,226 | **61.04** |
| Strict variant | 603,010 | 86.56 |

### Dispersion across states (n ≥ 500, 52 states/territories)

| Measure | Baseline | Counterfactual | Strict |
|---|---|---|---|
| Max | 60.89 (VT) | 67.17 (VT) | 94.27 |
| Min | 7.26 (MS) | **57.77 (MT)** | 83.31 |
| **Max/min ratio** | **8.39×** | **1.16×** | 1.13× |
| **SD across states** | **10.46** | **2.03** | — |
| **Coefficient of variation** | **0.462** | **0.033** | 0.030 |
| Spearman ρ vs baseline ranking | 1.000 | **0.121** | — |

**Relative dispersion falls by 93%.** The states become nearly indistinguishable: every one of
the 52 lands between 57.8% and 67.2%.

### By state — the reordering

| State | n | Baseline | Counterfactual | Δ | | State | n | Baseline | Counterfactual | Δ |
|---|---|---|---|---|---|---|---|---|---|---|
| VT | 1,465 | 60.89 | 67.17 | **+6.28** | | MI | 24,642 | 20.64 | 60.22 | +39.58 |
| MN | 13,680 | 45.42 | 63.70 | +18.28 | | DE | 2,159 | 18.76 | 62.58 | +43.82 |
| ME | 3,477 | 44.06 | 63.27 | +19.21 | | SD | 1,731 | 18.37 | 60.14 | +41.77 |
| WI | 12,772 | 38.22 | 61.76 | +23.54 | | AZ | 13,266 | 18.15 | 59.38 | +41.23 |
| WA | 15,295 | 36.50 | 62.07 | +25.57 | | OH | 25,715 | 18.01 | 58.44 | +40.43 |
| OR | 8,981 | 36.40 | 62.10 | +25.70 | | WV | 3,739 | 16.90 | 59.59 | +42.69 |
| MA | 20,163 | 35.66 | 60.74 | +25.08 | | MO | 13,832 | 16.89 | 58.00 | +41.11 |
| NH | 3,321 | 32.97 | 60.58 | +27.61 | | NC | 20,423 | 16.61 | 59.85 | +43.24 |
| RI | 3,191 | 32.69 | 62.02 | +29.33 | | KS | 5,559 | 16.46 | 61.99 | +45.53 |
| AK | 1,425 | 32.56 | 64.14 | +31.58 | | AR | 5,260 | 14.70 | 63.88 | +49.18 |
| DC | 2,892 | 29.67 | 63.80 | +34.13 | | PR | 8,665 | 14.68 | 58.06 | +43.38 |
| NM | 3,494 | 28.53 | 62.36 | +33.83 | | NE | 3,887 | 14.56 | 64.19 | +49.63 |
| WY | 905 | 26.85 | 59.34 | +32.49 | | TN | 12,412 | 14.32 | 60.37 | +46.05 |
| CO | 12,018 | 26.25 | 60.20 | +33.95 | | IN | 12,447 | 14.28 | 59.55 | +45.27 |
| MT | 2,169 | 26.05 | **57.77** | +31.72 | | NV | 4,994 | 14.22 | 58.85 | +44.63 |
| HI | 2,948 | 25.47 | 61.02 | +35.55 | | OK | 7,040 | 13.71 | 61.73 | +48.02 |
| CA | 77,176 | 25.40 | 62.09 | +36.69 | | TX | 47,868 | 13.55 | 60.91 | +47.36 |
| IA | 5,858 | 25.26 | 60.21 | +34.95 | | SC | 10,674 | 13.43 | 63.90 | +50.47 |
| CT | 9,519 | 24.72 | 60.42 | +35.70 | | NJ | 19,804 | 12.77 | 62.52 | +49.75 |
| NY | 51,083 | 24.04 | 62.93 | +38.89 | | GA | 18,877 | 12.30 | 60.95 | +48.65 |
| UT | 5,442 | 23.93 | 60.57 | +36.64 | | KY | 8,508 | 11.97 | 60.32 | +48.35 |
| ND | 1,546 | 23.87 | 58.80 | +34.93 | | FL | 47,037 | 11.44 | 59.50 | +48.06 |
| IL | 29,549 | 22.19 | 59.62 | +37.43 | | LA | 9,474 | 9.90 | 62.42 | +52.52 |
| MD | 13,017 | 22.15 | 62.96 | +40.81 | | AL | 8,749 | 9.57 | 64.38 | +54.81 |
| ID | 3,069 | 21.90 | 61.00 | +39.10 | | **MS** | 4,570 | **7.26** | **65.40** | **+58.14** |
| VA | 16,106 | 21.51 | 60.33 | +38.82 | | | | | | |
| PA | 34,297 | 21.28 | 59.61 | +38.33 | | | | | | |

**Δ is almost perfectly inversely proportional to the baseline rate.** Mississippi gains 58.14
points, Alabama 54.81, Louisiana 52.52 — while Vermont gains 6.28 and Minnesota 18.28. The
low-never-engagement states were low *because* of meal-only engagement; take it away and they
are ordinary.

**Verdict: the spread collapses.** Not "narrows" — collapses. 8.39× → 1.16×, CV 0.462 → 0.033,
rank ordering destroyed (ρ = 0.121).

### Caveats — read before citing any of this

- **This is a one-year counterfactual applied to a cumulative classification.** It is a
  directional test of a mechanism, **not an estimate of anything.** The 61.04% national figure
  is not a claim that 61% of physicians are truly unengaged; it is an arithmetic device.
- **32.3% of ever-engaged MD/DOs (177,784) have no PY2025 payment at all** and cannot be
  channel-classified. They are held engaged in the primary counterfactual. If their historical
  engagement was also disproportionately F&B — which S1 suggests is likely — the true collapse
  is larger, not smaller. The strict variant bounds this at CV 0.030.
- **PY2025 General Payments only.** Research and ownership payments are not on disk; recon Q11
  puts them at ~2.6% of engaged NPIs.
- **To do this properly** you would need `OP_DTL_GNRL_PGYR2016`–`PGYR2024` to classify each
  physician's *cumulative* channel history rather than one year of it. That is the single
  highest-value missing input in the project, and this result is the reason.

---

## S4 — Do restricted states shift to unbanned channels?

Grouping is **empirical, not legal**: Group A = the eight highest-never-engagement states
(VT, MN, ME, WI, WA, OR, MA, NH); Group B = ten of the lowest (MS, AL, LA, KY, GA, NJ, FL, SC,
TX, OK).

### Is non-F&B engagement also depressed? Partly.

Denominator is **all** MD/DOs in the state, so these are population engagement rates, PY2025:

| State | % with ≥1 F&B | % with ≥1 non-F&B | non-F&B $ per MD/DO |
|---|---|---|---|
| VT | **10.38** | **5.73** | $598 |
| ME | 24.65 | 6.24 | $486 |
| MN | 26.51 | 10.31 | $2,110 |
| WI | 31.94 | 9.95 | $1,028 |
| WA | 33.77 | 9.54 | $1,379 |
| OR | 34.47 | 9.99 | $1,476 |
| NH | 35.35 | 9.24 | $1,423 |
| MA | 35.50 | 12.82 | $1,979 |
| … | | | |
| TX | 62.74 | 15.95 | $2,586 |
| GA | 64.31 | 16.36 | $2,307 |
| LA | 68.38 | 16.21 | $1,935 |
| AL | 69.25 | 15.02 | $2,288 |
| MS | **72.47** | 14.57 | $1,721 |

**The F&B spread is 7.0× (VT 10.38% → MS 72.47%). The non-F&B spread is only 2.9×** (VT 5.73%
→ TN 16.69%), and most states cluster between 9% and 16%. Minnesota is the clearest case of
divergence: F&B reach is a third of Mississippi's, but non-F&B dollars per physician ($2,110)
exceed Mississippi's ($1,721).

### Non-F&B category mix

Share of non-F&B **records** within each group (PY2025):

| Nature of payment | A (high never-eng.) | B (low never-eng.) | Other |
|---|---|---|---|
| Travel and Lodging | 51.39 | 48.68 | 49.01 |
| **Consulting Fee** | **21.01** | **14.12** | 16.44 |
| **Compensation for services other than consulting (faculty/speaker)** | **14.99** | **21.19** | 20.47 |
| Education | 8.27 | 10.32 | 8.89 |
| Honoraria | 1.38 | 1.68 | 1.65 |
| Faculty/speaker, medical education program | 1.06 | 1.18 | 1.06 |
| Royalty or License | 0.90 | 1.15 | 1.19 |
| Long term medical supply or device loan | 0.44 | 1.03 | 0.74 |
| Grant | 0.38 | 0.22 | 0.28 |
| Gift | 0.13 | 0.12 | 0.12 |
| Entertainment | 0.03 | 0.17 | 0.08 |

Absolute reach — **physicians per 1,000 MD/DOs** receiving each category (PY2025):

| Nature of payment | A | B | A as % of B |
|---|---|---|---|
| **Consulting Fee** | **36.3** | **39.9** | **91%** |
| Travel and Lodging | 55.8 | 74.8 | 75% |
| Compensation, faculty/speaker (non-CE) | 15.9 | 26.5 | **60%** |
| Education | 37.6 | 74.1 | **51%** |
| Honoraria | 4.4 | 6.4 | 69% |
| Faculty/speaker, med-ed program | 2.6 | 3.6 | 72% |
| Long term supply/device loan | 1.5 | 3.8 | 39% |
| Entertainment | 0.2 | 2.1 | 10% |

**Both things are true, and the split is informative.**

*Relocation is real.* Consulting is 21.01% of non-F&B records in restricted states against
14.12% elsewhere, and in absolute reach it is **91% of the comparison group** — essentially
undiminished. Consulting is a genuine professional service, hardest to characterize as a gift,
and it survives.

*But engagement is genuinely lower too.* The promotional channels are all depressed in
absolute terms: education 51%, speaking 60%, honoraria 69%, travel 75%, entertainment 10%.
Restricted states are not simply rerouting the same engagement — they are receiving materially
less of everything except consulting.

**Answer to S4: engagement partially relocates rather than fully relocating.** The channel that
holds is consulting; everything promotional shrinks. So gift bans do appear to reduce real
engagement — but by something closer to the 2.9× non-F&B spread than the 8.39× headline spread,
and most of what the headline was measuring was meals.

---

## S5 — Implications for Phase C

Phase C planned to use food-and-beverage payments as the in-person rep-visit signal. Based on
S1–S4:

**1. The signal is badly confounded with state, and the confounding is large.** F&B population
reach ranges 10.38% (VT) to 72.47% (MS) — a 7× spread on the exact variable Phase C intended to
use as its primary measure. Any national F&B analysis that does not stratify by state is
substantially measuring state law rather than rep activity.

**2. Where the signal is interpretable:** the ~40 states in the middle and upper range of F&B
reach — roughly AZ, NV, IN, AR, OK, TN, TX, FL, NJ, NE, SC, KY, GA, LA, AL, MS and the large
central group (IL, OH, MI, PA, NY, CA, NC, MO, VA, MD…). Within these, F&B absence plausibly
reflects genuine lack of rep contact.

**3. Where it is confounded and should not be used as a rep-access proxy:** **VT, MN, ME, MA,
WI, WA, OR, NH, DC, RI** — and note the three of those (WA, OR, WI) whose statutes are
*unverified*. In these states, F&B absence cannot be distinguished from legal restriction. VT
is unusable outright: 176 engaged physicians statewide with a median of 2 records.

**4. Does the channel signal survive at all?** Yes, but only under stratification, and with a
narrower claim:

- **Use it within-state, never pooled across states.** A physician with no F&B in Mississippi is
  a genuinely unreached physician; a physician with no F&B in Vermont may be seeing a rep weekly.
- **Consulting is the more portable cross-state signal** (91% relative reach, near-invariant),
  though it measures a different and much rarer relationship — 36–40 per 1,000 physicians, not
  a mass channel.
- **The absence of a reportable payment is not the absence of engagement.** Non-reportable rep
  contact — detailing, sampling, digital — is invisible in Open Payments everywhere, not just in
  restricted states. Phase C should state this as a structural limit, not a caveat.

**5. What would fix it:** cumulative channel history (`PGYR2016`–`PGYR2024`) would let you
classify each physician's *lifetime* channel mix rather than one year, which is the difference
between a directional test and an estimate. Without it, Phase C's F&B analysis is a
single-year, state-confounded proxy and should be labelled as such.

---

## What surprised me

**1. The collapse is more complete than "the state effect is partly channel."** I expected
narrowing. Going from 8.39× to 1.16× with the rank ordering inverted — Mississippi from last to
near-first — is close to the maximum possible result. Every state lands in a 9.4-point band.
The state variable that survived four independent controls across Phase A and the Extension
turns out to be almost entirely one payment category.

**2. Vermont barely moves, and that is the most informative single number here.** VT gains 6.28
points under the counterfactual against Mississippi's 58.14. Vermont's engaged population was
*already* not meal-based — 52.27% F&B-only against a 74.86% national average, the lowest in the
country. The gift ban did not just lower Vermont's engagement count; it changed the composition
of what engagement means there. That is a qualitatively different state, not a low-scoring one.

**3. Consulting is untouched.** 91% relative reach in restricted states while education runs
51% and entertainment 10%. The channel that survives a gift ban is the one that most resembles
real professional work. Whether that reflects genuine substitution, or simply that consulting
was never the marginal channel to begin with, this data cannot say — but the contrast between
91% and 10% is stark and was not anticipated by the task.

**4. West Virginia breaks the legal hypothesis; Washington, Oregon and Wisconsin support it.**
WV was named as a verified restriction state and sits at 90.20% F&B records, indistinguishable
from Alabama. WA, OR and WI were flagged as *unverified* and behave exactly like Minnesota and
Maine. The empirical grouping and the named legal grouping are close but not the same, which is
a caution against ever having hardcoded the classification.

**5. The median engaged physician is engaged for $293.53 a year.** Across 7 records. A quarter
are under $87. "Ever engaged" — the binary this entire project is built on — is for most people
a handful of sandwiches. That does not invalidate the binary, but it means "engaged" and
"unengaged" are far closer together than the framing implies, and the interesting variation may
be in intensity rather than incidence.

---

## Reinterpretation — what should now be read differently

**1. Phase A Decision 3 — "state is a first-class stratification variable."** Still true, but
the reason has changed. State stratifies *channel recording*, and only secondarily engagement.
Any writeup that presents the state map as a map of industry reach is wrong; it is closer to a
map of meal reportability.

**2. Phase A §A5 — the 8.4× state spread and the 40× spread among high-volume prescribers.**
Both numbers stand arithmetically. Both should now be presented as *predominantly F&B-channel
effects*. The 40× figure in particular should not be described as showing "something blocking
access," which is how I framed it in Phase A's "What surprised me" #4 — S4 shows access is
reduced by roughly 2.9×, not 40×, with the remainder being meal recording.

**3. Phase A §A6 — state explains 4.22% of individual variance (7.79% within primary care).**
That variance is now identifiable as largely F&B-channel variance rather than a structural
access constraint. It does not change the arithmetic, but it substantially weakens the
inference I drew that a structural explanation should be sought at the practice level *because*
geography mattered. Geography mattered for a measurement reason.

**4. Extension §E4 — "the state pattern persists in the high-value cell" (ME 22.7% vs TX
0.9%).** This survived volume and cost controls but does **not** survive the channel control.
It should be reinterpreted the same way: high-volume, high-cost physicians in Maine are less
likely to have a *recorded* engagement, not necessarily less likely to be engaged.

**5. Extension "What surprised me" #3 — "the state effect survives every control I put on
it."** That claim is now false and should be struck. It survived every control available at
the time; it does not survive this one. This is the clearest example in the project of a
finding that looked robust because the right control had not been run.

**6. Phase C's core design.** F&B-as-rep-visit-signal needs the state stratification set out in
S5 before it is used at all.

---

## Files

| Path | Rows | Contents |
|---|---|---|
| `work/py2025_mddo_payments.parquet` | 372,443 | One row per MD/DO with ≥1 PY2025 General Payment: record counts, dollars, and F&B / non-F&B splits |

Nothing downloaded, nothing deleted. Source CSVs and all prior Parquet files intact.
