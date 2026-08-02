# Phase R — Revision on Cumulative History

**Read `PHASE_A_FINDINGS.md`, `PHASE_A_EXT_FINDINGS.md`, `PHASE_S_FINDINGS.md`, and `PHASE_B_FINDINGS.md` first.**

Uses `work/mddo_payments_5yr.parquet`, `work/analytic_population.parquet`, and the Phase B base table. No new data required.

**This is the final analytical phase.** After it, the project moves to writing. Do not propose additional phases; if something is genuinely unresolvable, note it as a limitation instead.

---

## What changed

Five program years (PY2021–2025) are now available, verified row-for-row. Three consequences:

1. **Recon Q1 is confirmed, not assumed.** Of 770,465 physicians paid in 2021, zero are absent from the Profile Supplement. The cumulative logic the project rests on holds.
2. **The unclassifiable share fell from 32.31% to 5.85%.** The F&B-adjusted definition is now estimable rather than directional.
3. **The headline numbers have shifted.** F&B-only is 58.7% over five years, not 74.86% over one. F&B-adjusted never-engagement is 64.67%, not 61.04%.

Everything reported in Phases S and B under the F&B-adjusted definition was computed on one year. It must be recomputed.

---

## Tasks

### R1 — Re-run the state counterfactual on five-year history ⭐

This is the project's central finding and it currently rests on a single program year.

Recompute Phase S's S3 using cumulative five-year channel classification:

- Never-engaged rate by state, baseline and F&B-adjusted
- Spread (max/min ratio), SD, CV — before and after
- Spearman rank correlation between baseline and adjusted state ordering
- The Mississippi and Vermont cases specifically, since they anchored the original result

**Report whether the 8.39× → 1.16× collapse survives, strengthens, or weakens.** State the new figures plainly, and say explicitly if they differ materially from what Phase S reported.

### R2 — The channel signature test ⭐⭐ **the most important task in this phase**

Kaiser Permanente and Vermont both produce zero food-and-beverage records, for opposite reasons. Kaiser publicly states it does not allow pharmaceutical sales representatives to enter its hospitals and medical offices — a ban on *contact*. Vermont's 2009 law bans the *gift*, not the visit; a rep may still detail a Vermont physician.

If that distinction is real, the two should have **different channel signatures.**

Classify every MD/DO on two independent axes over five years:

| | any non-F&B | no non-F&B |
|---|---|---|
| **any F&B** | fully engaged | meal-only |
| **no F&B** | relationship-only | never engaged |

Then compare the four-cell distribution across:

- **High-restriction states** (VT, MN, ME, MA, and the empirically similar WA, OR, WI) vs. low ones (MS, AL, TX)
- **Kaiser/Permanente organizations** vs. size-and-specialty-matched non-Kaiser organizations
- Any other organization from Phase B's extreme list with ≥100 MD/DO prescribers

**Predictions to test, not assume:**
- Gift-ban states → suppressed F&B, non-F&B relatively preserved ("relationship intact, meal illegal")
- Contact-ban organizations → suppressed on *both* axes ("no rep in the building")

Report the **relationship-only rate** and the **fully-engaged rate** separately for each group — those two figures are what discriminate the mechanisms.

> If the predicted divergence appears, it means the channel signature can distinguish a measurement artifact from a real access restriction. Say so explicitly, and state what it would take to validate the discriminant properly. If it does not appear, say that just as plainly — a null here is a real result and must not be softened.

### R3 — Recompute Phase B under five-year classification

Specifically:
- **B4** — organizational clustering (the 128× VIF) under the corrected F&B-adjusted definition
- **B6** — out-of-sample variance decomposition, both definitions
- The Kaiser figure (51.2% baseline vs 21.0% national)
- The group-size gradient, and whether it remains a pure meal-channel artifact

Phase B found that under the one-year adjusted definition organization *degraded* predictive accuracy. Check whether that holds with five years, and interpret it in light of R2.

### R4 — Recompute the selection-robust group

- Does the 553 change under five-year classification?
- Do the 60 rheumatologists change?
- Restate the dollar figures and the threshold range (553–3,896, $0.9–3.0B)

### R5 — Consolidated numbers table

Produce a single table of every headline figure in the project, corrected to five-year history, in a form ready to write from. One row per claim, with: the figure, the definition it uses, the phase it came from, and any caveat that must travel with it.

Flag any number appearing in an earlier findings document that is now superseded, so nothing stale gets carried into the writeup.

---

## Rules

- **Descriptive only.** No models beyond the out-of-sample decomposition already established in Phase B.
- Every figure labelled with its engagement definition and its observation window.
- Show your SQL.
- Raw counts alongside every percentage.
- Do not download, do not delete.
- Flag prominently anything that contradicts an earlier phase.
- **State the 2013–2020 gap as a limitation wherever cumulative claims are made.** The residual 5.85% unclassifiable are most likely physicians engaged only in that earlier window. Obtaining those years is out of scope.

---

## Output

Write `PHASE_R_FINDINGS.md`.

Open with **Headline**: the R1 verdict (does the state collapse survive?) and the R2 verdict (do the channel signatures diverge?).

Include the R5 consolidated table as its own clearly marked section.

Close with **What surprised me**, and a **Superseded** section listing every earlier figure that should no longer be quoted.
