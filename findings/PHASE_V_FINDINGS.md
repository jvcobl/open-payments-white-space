# Phase V — Verification Before Writing

Generated 2026-08-02. Completeness checks on results that are otherwise final.
Assumes `PHASE_R_FINDINGS.md`.

---

## Verdict

| Check | Outcome | Changes a Phase R conclusion? |
|---|---|---|
| **V1 — Research payments** | **Cannot be run. Files are not on disk.** Nothing downloaded. | **No figure changes.** But it identifies the largest remaining threat to the R2 discriminant, and the exposure is bounded below. |
| **V2 — Ownership / investment payments** | **Cannot be run in full. Files are not on disk.** A partial in-file signal was available and was checked. | **No.** Zero of the 146,459 baseline never-engaged and zero of the 553 carry an ownership flag. |
| **V3 — External validation** | **Both checks pass.** | **No.** Independently corroborates the pipeline. |
| **V4 — Drug samples** | Confirmed. | **No figure changes, but a required wording change throughout.** |

**Nothing in Phase V supersedes a Phase R number.** One correction is a wording requirement (V4),
one is a minor documentation error in reconnaissance (noted under V3).

**The single most important output of this phase is V4's wording rule**, and the second is V1's
explicit statement of what has *not* been checked.

---

## V1 — Research payments ⭐

### 1. Are the files on disk or reachable?

**No.** Searched `~/whitespace`, `~/whitespace/work`, `~/Downloads`, `~/Desktop`, `~/Documents`
to depth 3 for `*RSRCH*`, `*OWNRSHP*`, `*research*`, `*ownership*`, `*PHYS_OWN*`. Zero matches.

```
find ~/whitespace ~/Downloads ~/Desktop ~/Documents -maxdepth 3 \
  \( -iname "*RSRCH*" -o -iname "*OWNRSHP*" -o -iname "*research*" -o -iname "*ownership*" \)
# (no results)
```

Everything on disk from Open Payments is: the Covered Recipient Profile Supplement, and General
Payments detail for PY2021–PY2025. **Per the rules, I have not downloaded anything.**

**To run V1 you would need**, from the CMS Open Payments PY2026 (June 2026) publication:

| File | Approx size |
|---|---|
| `OP_DTL_RSRCH_PGYR2021_P06302026_06032026.csv` | ~1 GB |
| `OP_DTL_RSRCH_PGYR2022_P06302026_06032026.csv` | ~1 GB |
| `OP_DTL_RSRCH_PGYR2023_P06302026_06032026.csv` | ~1 GB |
| `OP_DTL_RSRCH_PGYR2024_P06302026_06032026.csv` | ~1 GB |
| `OP_DTL_RSRCH_PGYR2025_P06302026_06032026.csv` | ~1 GB |

Research files carry both a `Covered_Recipient_NPI` and `Principal_Investigator_1..5` NPI fields.
**Both must be used** — a physician can be a named PI on a study whose covered recipient is the
teaching hospital, and using only the covered-recipient field would miss exactly the population
V1 is worried about.

### 2–6. What can and cannot be said without them

Tasks 2–6 cannot be answered. But the exposure is not unbounded, and one structural point matters
a great deal:

#### The baseline never-engaged flag does not come from General Payments

This is the key distinction and it limits the damage. `never_engaged` is defined as **absent from
the Covered Recipient Profile Supplement**, which is a profile roster, not a payment file. CMS
creates a covered-recipient profile for any recipient in the Open Payments system regardless of
which payment category the record falls under.

**If that is correct, then a research-only recipient already appears in the supplement, is
already flagged ever-engaged, and is already excluded from the 146,459 and from the 553.** Under
that reading V1's central worry — *"a physician with an active research relationship and no
general payments currently lands in the never-engaged cell"* — is **false for the baseline flag**,
and true only for the *channel* classification.

**I want to be exact about the strength of this claim.** What is verified on disk is that the
supplement is comprehensive for *general* payment recipients: Phase R found 0 of 770,465
physicians paid in PY2021 absent from it (5, 1 and 6 for 2022–2024 out of ~900,000 each). That
establishes comprehensiveness for one payment category. **It does not prove research coverage,
and I could not test research coverage without the research file.** The claim above rests on how
CMS documents the supplement, not on data in hand.

**The test that would settle it**, once the files exist: take research-file NPIs that appear in
no General Payments file for any year, and check them against the supplement. If ~0% are absent,
the supplement is all-category and the baseline flag — and therefore the 553, the 17,108, the
146,459, and every headline count in the project — is already research-safe.

#### Bounding the channel-classification exposure

What research payments *would* change is the R2 four-cell table, since that is built from
General Payments only.

```sql
SELECT count(*) FILTER (WHERE cell4='4 no record') AS no_record_cell,
       count(*) FILTER (WHERE cell4='4 no record' AND never_base) AS also_never_base,
       count(*) FILTER (WHERE cell4='4 no record' AND NOT never_base) AS ever_engaged_unclassified,
       count(*) FILTER (WHERE cell4='3 relationship-only') AS relationship_only_now
FROM 'work/phase_r_base.parquet';
```

| | n |
|---|---|
| "No record in window" cell | 178,579 |
| — of which baseline never-engaged (absent from supplement entirely) | 146,420 |
| — of which **ever-engaged but unclassifiable** | **32,159** |
| Relationship-only cell as currently measured | 8,715 |

**Only the 32,159 can move.** The 146,420 are absent from the supplement, so under the reading
above they have no payments of any category. **The absolute worst case is that all 32,159 have
in-window research payments**, which would take relationship-only from 8,715 (1.25%) to 40,874
(5.87%).

That worst case is implausible on the evidence. Those 32,159 look like lapsed low-intensity
general-payment recipients, not active investigators:

| | The 32,159 | All MD/DO |
|---|---|---|
| Median Part D claims | 231 | 348 |
| In bottom 3 volume deciles | 37.5% | 30.0% |
| In an organization of 1,000+ | **24.7%** | **23.7%** |

Industry-funded clinical trial work concentrates in large academic organizations. This group is
**not** disproportionately in them (24.7% vs 23.7% — essentially identical) and is *lower* volume
than average. The profile fits physicians who received a few meals before 2021 and nothing since.

#### Direction of the likely bias on the R2 discriminant

The discriminant is non-F&B preservation ÷ F&B preservation. Adding research to the non-F&B axis
raises non-F&B reach wherever research is concentrated.

**The most likely effect is to widen the observed separation, not narrow it.** The organizations
with the highest discriminants — Mass General (1.889), Fairview (1.722), University of Vermont
Medical Center (1.648), Mayo SE Minnesota (1.458), Duke (1.307) — are precisely the
research-intensive academic centers. Kaiser's industry-sponsored trial volume is smaller relative
to its size. Adding research would therefore be expected to lift the numerator more for the
gift-ban/academic group than for Kaiser.

**This is reasoning, not a result.** It is untested, it could run the other way, and it is
**the single largest open threat to R2** — which is a headline finding of Phase R. It should be
stated as such in any writeup, and the R2 discriminant should be described as computed on
general payments only.

### V1 verdict

**Cannot be run; nothing downloaded; no Phase R figure changes.** The baseline population counts
are very likely already research-safe by construction, but that rests on documentation rather
than on data in hand. The R2 discriminant is computed on general payments only and this is its
principal unverified assumption.

---

## V2 — Ownership and investment payments

### Are the files on disk?

**No.** Same search as V1. Would require `OP_DTL_OWNRSHP_PGYR2021..2025_P06302026_06032026.csv`
(these are small, typically tens of MB).

### A partial signal was available and was checked

General Payments carries a `Physician_Ownership_Indicator` column, which flags a payment record
where the physician or an immediate family member holds an ownership or investment interest in
the paying manufacturer. It is **not** the ownership payment file — it is an attribute on general
payment records — but it is the only ownership information on disk and it is worth reporting.

```sql
SELECT Physician_Ownership_Indicator, count(*) AS records,
       count(DISTINCT trim(Covered_Recipient_NPI)) AS distinct_npis
FROM read_parquet('work/op_general_py202*.parquet')
WHERE length(trim(coalesce(Covered_Recipient_NPI,'')))=10 GROUP BY 1;
```

| Indicator | Records | Distinct NPIs (all recipients) |
|---|---|---|
| No | 61,351,132 | 1,487,415 |
| NULL | 9,538,914 | 438,105 |
| **Yes** | **123,145** | **38,017** |

Restricted to our MD/DO population:

| | n |
|---|---|
| MD/DO Part D prescribers with an ownership-flagged payment | **29,129** |
| — of which baseline never-engaged | **0** |
| — of which in the 553 | **0** |

**Zero, in both cases — though this is true by construction and should not be over-read.** An
ownership-flagged record *is* a general payment record, so anyone carrying the flag is already in
General Payments and already engaged. The check confirms internal consistency; it does not test
whether a physician appears in the standalone ownership file without any general payment.

That residual case is the same structural question as V1 and has the same answer: if the Profile
Supplement is the all-category roster, such a physician is already flagged ever-engaged.
Ownership/investment recipients are in any case a very small population — recon Q11 put research
and ownership combined at ~2.6% of engaged NPIs.

### V2 verdict

**Cannot be run in full; no Phase R figure changes.** The partial check is consistent with the
existing classification and finds no contamination of the 553.

---

## V3 — External validation against published figures

> Both published figures are taken from the task document's citation of Kanter, Carpenter,
> Lehmann & Mello (*JAMA Network Open*, 2019). I have not read the paper and cannot confirm its
> exact population definitions, which matters for how tightly these should be expected to match.

### V3.1 — Median annual payment

```sql
WITH y AS (SELECT TRY_CAST(Program_Year AS INTEGER) yr, trim(Covered_Recipient_NPI) npi,
             sum(TRY_CAST(Total_Amount_of_Payment_USDollars AS DOUBLE)) usd, count(*) recs
           FROM read_parquet('work/op_general_py202*.parquet')
           WHERE length(trim(coalesce(Covered_Recipient_NPI,'')))=10 GROUP BY 1,2)
SELECT yr, count(*) engaged_mddo, median(usd), quantile_cont(usd,0.25), quantile_cont(usd,0.75)
FROM y JOIN 'work/phase_r_base.parquet' b ON y.npi=b.npi GROUP BY 1 ORDER BY 1;
```

| Program year | Engaged MD/DOs | **Median annual $** | p25 | p75 | Mean | Median records |
|---|---|---|---|---|---|---|
| 2021 | 308,905 | **$222.44** | $60.00 | $879.77 | $4,065.97 | 6 |
| 2022 | 342,111 | **$254.74** | $73.76 | $983.75 | $5,095.55 | 6 |
| 2023 | 363,751 | **$272.09** | $80.49 | $1,004.48 | $4,342.33 | 7 |
| 2024 | 374,156 | **$282.80** | $84.11 | $1,054.20 | $4,540.28 | 7 |
| 2025 | 372,443 | **$293.53** | $86.66 | $1,087.17 | $4,805.66 | 7 |

**Published comparison: $201 median annual payment, 2015.**

**Consistent — and the direction is right.** Our earliest year (2021) is $222.44, six years after
the published 2015 figure of $201, rising steadily to $293.53 by 2025. That is roughly 4% annual
nominal growth across the series, which is an unremarkable trajectory for a figure like this.
The order of magnitude matches exactly: low hundreds of dollars, not tens and not thousands.

The mean/median gap is enormous in every year (mean ~$4,000–5,000 against a median under $300),
confirming the extreme right skew that Phase S first noted. **Any published or internal figure
quoting a mean payment is describing a different phenomenon than one quoting a median.**

Differences that would prevent an exact match, stated rather than used to explain the result
away: our population is MD/DO **Part D prescribers**, not all physicians; the years differ by
6–10; and this is General Payments only.

### V3.2 — Share of physicians receiving payments

Published comparison: **roughly two-thirds of physicians receive industry payments.**
Our cumulative figure is 78.98% ever-engaged.

| Program year | MD/DOs engaged that year | % of 696,647 |
|---|---|---|
| 2021 | 308,905 | **44.34** |
| 2022 | 342,111 | 49.11 |
| 2023 | 363,751 | 52.21 |
| 2024 | 374,156 | 53.71 |
| 2025 | 372,443 | **53.46** |

**The single-year figure does not land on two-thirds — it undershoots at 53.46%, while the
cumulative figure overshoots at 78.98%. Two-thirds sits between them.** The task predicted the
single year would land nearer two-thirds; on the full MD/DO denominator it does not, and I am
reporting that plainly.

The gap is explained by the denominator, and this resolves cleanly:

| Denominator, PY2025 | n | 1-year engaged | 5-year engaged | Cumulative |
|---|---|---|---|---|
| All MD/DO Part D prescribers | 696,647 | 53.46% | 74.37% | 78.98% |
| Excluding hospital-based/structural specialties | 576,940 | 58.83% | 79.02% | 83.36% |
| **Office-based, volume decile ≥ 5** | **376,312** | **63.50%** | 82.52% | 86.29% |

Our denominator includes ~120,000 emergency physicians, pathologists, radiologists,
anesthesiologists, hospitalists and trainees — physicians Phase A identified as *structurally*
unengaged, with median Part D volumes in the tens of claims. A study of practising physicians
generally would weight these differently. **Restricting to office-based physicians with
meaningful prescribing volume gives 63.50% in a single year — essentially two-thirds.**

**Both checks pass.** The pipeline reproduces an independently published payment magnitude and an
independently published engagement prevalence once the denominators are aligned. There is no
discrepancy requiring escalation.

### A minor documentation error found while checking

Reconnaissance Q11 records General Payments PY2025 as having **95 columns**. It has **91**,
verified against the source CSV header and against the Parquet, which match each other exactly:

```
head -1 OP_DTL_GNRL_PGYR2025_*.csv | tr ',' '\n' | wc -l   # 91
diff <(csv header, sorted) <(parquet columns, sorted)       # IDENTICAL - no columns dropped
```

No data was lost and no analysis is affected — every column used in Phases S/B/R is present. This
is a transcription error in `RECON_FINDINGS.md` only, noted so the number is not repeated.

---

## V4 — Drug samples

**No computation required. Confirmed and stated for the record.**

**Drug samples are not reportable under the Physician Payments Sunshine Act.** Section 6002 of
the Affordable Care Act requires applicable manufacturers to report payments and transfers of
value to covered recipients, and **product samples intended for patient use are excluded from
that reporting requirement.** They are tracked separately under the PDMA, which is not a public
per-physician dataset.

### What this means for the project's central claim

A pharmaceutical representative can:

- enter a physician's office,
- conduct a full detailing conversation,
- leave drug samples for patient use,
- and depart having generated **no Open Payments record of any kind.**

The record appears only if something else changes hands — most often a meal. **This is not a
marginal edge case. It is the ordinary form of a sales call**, and it means the absence of an
Open Payments record is not evidence of the absence of industry contact.

### Required wording, everywhere

> **"Never engaged" must be worded throughout as "never received a reported industry payment"** —
> or an equivalent explicitly bounded phrasing such as "no recorded transfer of value" or "absent
> from Open Payments."

Phrasings that are **not** supportable by this data and must not be used:

| Do not write | Write instead |
|---|---|
| "physicians never contacted by industry" | "physicians with no reported industry payment" |
| "never reached by pharma" | "not reached through any reportable channel" |
| "no industry relationship" | "no recorded transfer of value" |
| "untouched by industry" | "absent from Open Payments" |

This is a **ceiling on what the entire project can claim**, not a caveat to append at the end.
The white space is a *measurement* population — physicians invisible to the disclosure system —
and the commercial argument for reaching them is unaffected by that, since a physician with no
reportable payment history is genuinely one the industry has not engaged through the channels
that produce records.

Three earlier results now read as three faces of the same limitation, and they should be
presented together:

1. **Phase S** — a rep visit that includes no meal generates no record at all.
2. **Phase R / R2** — a gift ban removes the meal but not the visit; the two are separable at
   group level by their channel signature.
3. **V4** — sampling and detailing are never reportable, in any state, under any policy.

Together these say: **Open Payments measures the reportable surface of industry engagement, and
the meal is most of that surface.** Every finding in this project is a finding about that surface.

---

## Corrected figures

**No Phase R figure is superseded by Phase V.** For completeness:

| Item | Status | Action |
|---|---|---|
| All Phase R numeric findings | Unchanged | Carry forward as written |
| Recon Q11, "General Payments PY2025 has 95 columns" | **Wrong — it has 91** | Correct in `RECON_FINDINGS.md`; no analytical impact |
| "Never engaged" phrasing, all documents | **Must change** | Reword to "never received a reported industry payment" per V4 |
| R2 discriminant (1.168 gift-ban / 0.656 Kaiser) | Unchanged | **Must be labelled "general payments only"**; research not included |
| The 553 | Unchanged, zero ownership flags | Likely research-safe by construction; unverified — see V1 |

### Open items carried into writing

1. **Research payments are not loaded.** The baseline counts are very likely unaffected; the R2
   discriminant is computed on general payments only. Test specified in V1.
2. **Ownership payments are not loaded.** Population is small (~2.6% of engaged NPIs with
   research combined); partial check found no contamination.
3. **2013–2020 is unobserved.** 5.85% of ever-engaged MD/DOs unclassifiable by channel
   (Phase R).
4. **Phase A's A2 matched-window test** remains unrun although the files now exist.
5. **Drug samples and detailing are permanently unobservable** in this or any Open Payments
   analysis. This one cannot be closed by obtaining more data.

---

## Files

No new data files were created. No files were downloaded. No files were deleted.
Everything in `~/whitespace` is intact.
