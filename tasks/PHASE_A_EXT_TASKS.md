# Phase A Extension — Cost-Per-Claim Segmentation

**Continuation of Phase A. Assumes `work/analytic_population.parquet` and `PHASE_A_FINDINGS.md`.**

Small, focused task. One question, several cuts. Should take well under an hour.

---

## Why this exists

Phase A found that never-engaged MD/DOs prescribe at roughly **half the drug cost per claim** of engaged peers, at every volume decile. That finding was reported as a sizing adjustment. It is more than that.

Cost per claim is largely generic-versus-brand mix. So the finding says never-engaged physicians are **generic prescribers** — which raises a question the headline cannot survive without answering:

- **Selection** — industry targeted physicians already inclined to prescribe brand, and screened out generic prescribers. The white space is white *for a reason*, and its commercial value is low.
- **Treatment** — engagement causes brand prescribing, and these physicians write generics because nobody ever reached them. The white space is genuinely untapped.

Phase A data cannot distinguish these. **Do not attempt to.** What it can do is establish whether a high-volume, high-cost-per-claim, never-engaged population exists at all — because that group survives the selection objection regardless of which story is true.

This matters especially because 87% of the high-volume white space is primary care, which prescribes enormous volumes of cheap generics. A large share of the 17,108 may be exactly what the selection story predicts.

---

## Tasks

### E1 — The specialty-composition control ⭐ **run this first**

Before anything else: **is the cost-per-claim gap a composition effect?**

Never-engaged physicians may simply be concentrated in low-cost specialties. If so, "half the cost per claim" says nothing about prescribing behavior.

- Compute mean and median cost per claim by engagement status **within each specialty** (n ≥ 500)
- Report how many specialties show the gap in the same direction, and its typical magnitude within specialty
- Compare the pooled gap to the within-specialty gap

> **This determines what the finding means.** If the gap largely disappears within specialty, it is composition and should be reported that way. If it persists within specialty, it is a genuine prescribing-behavior difference. Either result is publishable; misreporting it is not.

### E2 — Cost-per-claim distribution

- Cost per claim for every MD/DO in the analytic population, by engagement status
- Full decile breakdown, not just central tendency
- Flag and document any denominator problems (zero or suppressed claim counts)

### E3 — The two-way cut

Cross prescribing-volume decile against cost-per-claim decile, reporting never-engaged rate in each cell. A 10×10 grid.

Then isolate the target cell: **high volume (decile ≥ 9) AND high cost per claim (decile ≥ 9) AND never engaged.**

Report count, total claims, total drug cost, and share of MD/DO totals.

> This is the number that survives the selection objection. If it is small, say so plainly — that is a real result and we need it before Phase B, not after.

### E4 — Composition of the surviving group

For the cell isolated in E3:

- Specialty composition. Does it stay 87% primary care, or shift toward specialty medicine?
- State composition. Does the legal-regime pattern from Phase A persist here, or wash out?
- Rurality composition. Phase A found rurality irrelevant overall — does that hold in this subgroup?

### E5 — Threshold sensitivity

The decile-9 cutoff is arbitrary. Re-run E3's headline at deciles ≥ 8 and ≥ 10 (top decile only) for both axes. Report how the count moves.

If the finding only exists at one threshold, that is important to know.

---

## Rules

- **Descriptive only.** No models, no causal language.
- **Do not claim selection or treatment.** State explicitly what this data cannot distinguish.
- Show your SQL.
- Raw counts alongside every percentage.
- Do not download, do not delete.
- If a result contradicts Phase A, flag it prominently rather than reconciling it quietly.

---

## Output

Append to `PHASE_A_FINDINGS.md` as a new section, or write `PHASE_A_EXT_FINDINGS.md` — your call, but say which.

Open with **Headline**: the E3 target-cell count and dollar figure, and a one-line verdict on E1 (composition effect or genuine behavioral difference).

Close with **What surprised me.**
