# Phase S — The State Mechanism Test

**Read `PHASE_A_FINDINGS.md` and `PHASE_A_EXT_FINDINGS.md` first. Assumes `work/analytic_population.parquet`.**

Focused task. One hypothesis, tested several ways. Everything needed is on disk.

---

## Why this exists

The state effect is now the most robust finding in the project. It has survived every control applied to it: all-prescriber → MD/DO, volume stratification, cost-per-claim stratification, both simultaneously, and rurality. Inside the high-volume / high-cost cell — where volume and prescribing cost are both held constant — never-engagement runs ME 22.7% and MN 15.2% against TX 0.9%, a 25× range.

It is described but not explained. This task tests a specific mechanism.

**The hypothesis:** food-and-beverage payments are the *entry point* into Open Payments. For most physicians, their entire recorded footprint may be a handful of small meals. Vermont's 2009 gift ban (18 VSA §§ 4631a, 4632) prohibits gifts and meals — but it does not prohibit consulting agreements, speaker fees, or travel reimbursement.

If that is right, a gift ban does not necessarily reduce *engagement*. It erases the **recorded channel** through which most physicians appear in the database at all. "Never engaged" would then mean something categorically different in Vermont than in Mississippi, and every state comparison in this project would need reinterpreting.

**Do not assume the hypothesis is true.** It is equally interesting if false — that would mean gift bans genuinely reduce industry engagement, which is a substantive policy finding.

---

## Important scoping constraint

The Profile Supplement is cumulative across all program years, but only **PY2025** General Payments is on disk. So:

- "Engaged" in the analytic table means *ever* engaged
- Any payment-level analysis here covers *2025 only*

A physician engaged in 2015 but not 2025 appears in the supplement with no PY2025 payments. **Restrict all payment-level analysis to physicians with at least one PY2025 payment record, and state that restriction every time you report a figure from it.** Do not blend the two populations.

If a result would be materially different with the full payment history, say so and specify which program years would be needed.

---

## Tasks

### S1 — Is food and beverage the entry point?

Among MD/DOs with PY2025 payment records:

- Distribution of payment record count per physician (median, quartiles, p90, p99)
- Distribution of total payment value per physician
- **What share have *only* food-and-beverage payments and nothing else?**
- What share have at least one F&B payment?

> This is the core of the mechanism. If most engaged physicians are engaged solely through meals, then removing meals removes them from the database entirely.

### S2 — Channel mix by state

Among MD/DOs with PY2025 payment records, by state:

- F&B share of payment *records*
- F&B share of payment *dollars*
- Share of physicians who are F&B-only
- Share of the remaining Nature of Payment categories

Rank states. Report the full table, not just the extremes.

> **Do not hardcode a legal classification.** Verified gift-ban or disclosure regimes include Vermont (2009 gift ban, strongest), Minnesota, Maine, Massachusetts, West Virginia, and DC. Statutes for Washington, Oregon, and Wisconsin — all high in the never-engaged ranking — have **not** been checked, and several state reporting laws were altered or repealed after the federal Sunshine Act. Report states empirically and note where they fall relative to that unverified hypothesis set. The legal classification is a question for later, not an input here.

### S3 — The counterfactual ⭐ **the decisive test**

Construct a counterfactual engaged population: physicians whose PY2025 engagement is **F&B-only** are reclassified as never-engaged.

Recompute the never-engaged rate by state under that counterfactual.

**Does the state spread collapse, narrow, or persist?**

- Collapses → the state effect is largely a channel-recording artifact, and every state comparison in this project needs reinterpreting
- Persists → gift bans reduce engagement across all channels, which is a genuine policy finding
- Narrows partially → quantify how much

Report the before/after spread explicitly (max state, min state, ratio, and a dispersion measure).

> Caveat this heavily: it is a one-year counterfactual applied to a cumulative classification. It is a directional test, not an estimate. Say so.

### S4 — Do restricted states shift to unbanned channels?

Among MD/DOs with PY2025 payments, compare the non-F&B category mix (consulting, speaking/faculty, travel, education, honoraria) between high-never-engagement states and low ones.

If gift-ban states show a *higher* share of consulting and speaking, that is evidence engagement persists and merely relocates to legal channels. If their non-F&B volume is also depressed, engagement is genuinely lower.

### S5 — Implications for Phase C

Phase C planned to use food-and-beverage payments as an in-person rep-visit signal.

State plainly, based on S1–S4:

- In which states is that signal interpretable?
- Where is F&B absence confounded with legal restriction rather than lack of rep access?
- Does the channel signal survive at all, and under what stratification?

---

## Rules

- **Descriptive only.** No models, no causal claims.
- Every payment-level figure must carry the PY2025-only restriction in its statement.
- Show your SQL.
- Raw counts alongside every percentage.
- Do not download, do not delete.
- If a finding contradicts Phase A or the Extension, flag it prominently.
- Where the data cannot answer a question, say so and specify what would be needed. Do not substitute a proxy without labelling it.

---

## Output

Write `PHASE_S_FINDINGS.md`.

Open with **Headline**: the S3 verdict in one line — does the state effect survive the counterfactual? — plus the S1 F&B-only share.

Close with **What surprised me**, and a short **Reinterpretation** section listing any earlier conclusion in Phase A or the Extension that should now be read differently.
