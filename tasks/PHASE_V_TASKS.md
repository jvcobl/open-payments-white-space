# Phase V — Verification Before Writing

**Read `PHASE_R_FINDINGS.md` first.** Small, focused task. No new analysis phase — these are completeness checks on results that are otherwise final.

---

## V1 — Research payments ⭐ **the real gap**

Every channel classification in Phases S, B, and R uses **General Payments only**. Open Payments has three payment categories: general, research, and ownership/investment. The research file was never loaded.

Consequence: a physician with an active industry **research** relationship and no general payments currently lands in "no record in window" — the never-engaged cell. Research is arguably the most substantive industry relationship that exists, and it is presently invisible to this analysis.

Tasks:

1. Download is **not** required — check first whether research payment files are already on disk or reachable. If they are not present, **stop and report that**; do not download without asking.
2. If available: how many MD/DOs classified as never-engaged (baseline) have research payments?
3. How many classified as meal-only have research payments?
4. Recompute the four-cell channel table with research included as a non-F&B channel.
5. Does the R2 discriminant change? Report gift-ban-state and Kaiser discriminant values with and without research included.
6. Does the 553 selection-robust group change? **Any of the 553 with a research payment must be removed** — that would mean they are not never-engaged.

> If research payments materially change the four-cell distribution or the discriminant, that supersedes the corresponding Phase R figures and must be flagged as such.

## V2 — Ownership and investment payments

Same check, smaller. Physician ownership or investment interests are the third Open Payments category.

- Are those files on disk or reachable?
- If available, how many baseline never-engaged MD/DOs appear in them?
- Any of the 553?

## V3 — External validation against published figures

Two independent published numbers to check the pipeline against:

1. **Kanter, Carpenter, Lehmann & Mello (JAMA Network Open 2019)** report the median annual payment to physicians was **$201 in 2015**. Compute the median annual payment per engaged MD/DO for each program year on disk (2021–2025). Report whether the order of magnitude is consistent, noting that our population is Part D prescribers rather than all physicians and that years differ.
2. That work also reports roughly **two-thirds of physicians receive industry payments**. Our cumulative figure is 78.98% ever-engaged (21.02% never). Compute the **single-year** ever-engaged rate for each program year on disk. Does a single year land nearer two-thirds? This tests whether the difference between our figure and theirs is explained by the cumulative window, as expected.

> Both are sanity checks against outside sources. A large discrepancy would indicate a pipeline problem and must be reported prominently rather than explained away.

## V4 — Drug samples limitation

No computation required. Confirm and state for the record: drug samples are **not reportable** under the Sunshine Act. A representative can visit a physician, leave samples, and generate no Open Payments record of any kind.

State plainly in the output what this means for the project's central claim — specifically, that "never engaged" must everywhere be worded as **"never received a reported industry payment."**

---

## Rules

- **Do not download anything without asking first.**
- Descriptive only.
- Show your SQL.
- Raw counts alongside percentages.
- If a check supersedes a Phase R figure, say so explicitly and give the corrected number.
- If a check cannot be run with what is on disk, say so and specify exactly what would be needed.

---

## Output

Write `PHASE_V_FINDINGS.md`.

Open with **Verdict**: for each of V1–V4, whether it changes any Phase R conclusion, and if so which.

Include a short **Corrected figures** section listing any number that must be updated before writing.
