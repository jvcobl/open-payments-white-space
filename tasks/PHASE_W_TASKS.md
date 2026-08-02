# Phase W — Research and Ownership Payment Integration

**Read `PHASE_R_FINDINGS.md` and `PHASE_V_FINDINGS.md` first.**

Final data acquisition for this project. After it, the work moves to writing regardless of outcome.

---

## New files on disk

In `~/Downloads`, five program years (2021–2025) of each:

- `OP_DTL_RSRCH_PGYR20*.csv` — research payments, ~790 MB to 1.05 GB each
- `OP_DTL_OWNRSHP_PGYR20*.csv` — ownership and investment, ~1–2.2 MB each

Move them into `~/whitespace`, convert to Parquet in `work/` using the established convention (`all_varchar=true`, all columns), verify row counts against source, and **ask before deleting any CSV**.

Research files carry a different schema from general payments — profile the headers before assuming field names.

---

## Why this matters

Every channel classification in Phases S, B, and R used **General Payments only**. Research is arguably the most substantive industry relationship that exists, and it has been invisible.

This matters more than the 4.6% exposure suggests, because research relationships concentrate in academic medical centers — which are exactly the organizations scoring highest on the R2 discriminant. Excluding research may be *producing* the academic-versus-staff-model split rather than revealing it.

---

## Tasks

### W1 — The supplement comprehensiveness test ⭐⭐ **run this first**

Phase V verified the Profile Supplement is comprehensive for general payments (0 of 770,465 physicians paid in PY2021 were absent from it). It did **not** verify comprehensiveness for research, and flagged that as resting on documentation rather than data.

Test it directly: **how many MD/DOs classified as baseline never-engaged (absent from the Profile Supplement) appear in the research payment files?** Same for ownership.

- **Zero or near-zero** → the supplement is confirmed comprehensive across payment categories, and the population counts throughout the project stand. This closes the last unverified assumption.
- **Non-trivial** → the supplement is *not* the complete roster, "never engaged" is overstated, and every population figure in the project needs revision. Report the exact count, and characterize who they are.

Report this before anything else in the output.

### W2 — Recompute the channel classification

Two versions, both reported:

**(a) Comparable to R2** — fold research into the non-F&B axis, keeping the same four cells (fully engaged / meal-only / relationship-only / no record). Report the national table alongside R2's, so the change is visible.

**(b) Three-axis** — F&B, non-F&B general, research as separate axes. How many MD/DOs are research-only? Where do they sit by specialty, organization, and state?

### W3 — Does the 553 survive?

Any of the 553 selection-robust physicians with a research or ownership payment **must be removed** — a research relationship means they are not never-engaged.

Report the corrected count and dollar figure. If the number moves materially, that supersedes the Phase R headline.

### W4 — Does the R2 discriminant change?

Recompute with research folded into non-F&B:

- Gift-ban state group and low-restriction group discriminants
- Kaiser and the non-Kaiser 1,000+ reference
- The full organization table from Phase R's "highly F&B-suppressed" ranking

**Prediction to test, not assume:** research-intensive academic centers should move *up* on the non-F&B axis, widening the separation from Kaiser. If instead the separation collapses, the discriminant was substantially reading research-relationship intensity — which is a different finding and must be reported plainly.

### W5 — The organization/state confound ⭐

Nine of the ten highest-discriminant organizations in Phase R sit in gift-ban or restriction states (MA, MN, VT). Those organizations may score high because of where they are, not what they are.

- Compute each organization's discriminant **relative to its own state's baseline** rather than the national baseline
- Does the high-discriminant group survive that adjustment, or does it collapse toward 1.0?
- The Kaiser entities span multiple states including low-restriction Georgia and Hawaii — confirm their signature persists under state-relative scoring

> This determines what the organization-level result can claim. If the high side is purely a state artifact, say so: the honest version is a *contact-ban signature at organization level* and a *gift-ban signature at state level*, which are two findings with two evidence bases rather than one unified discriminant.

---

## Rules

- Descriptive only.
- Show your SQL.
- Raw counts alongside percentages.
- Ask before deleting anything.
- If a result supersedes a Phase R or V figure, state it explicitly with the corrected number.
- **No new analytical directions.** If something interesting appears that isn't in W1–W5, note it in "What surprised me" rather than pursuing it.

---

## Output

Write `PHASE_W_FINDINGS.md`.

Open with **Verdict**: the W1 result first (does the supplement hold?), then whether W3 or W4 changes a headline figure.

Include a **Corrected figures** section listing every number that must be updated before writing, and a **Final numbers** table superseding Phase R's R5 consolidated table.

Close with **What surprised me**.
