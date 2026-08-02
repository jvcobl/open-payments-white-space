# Phase A — Characterizing the Never-Engaged Population

**Read `CLAUDE_CODE_HANDOFF_v2.md` and `RECON_FINDINGS.md` first. This document assumes both.**

Reconnaissance is complete. Parquet files are in `work/`. This is the first analysis phase.

---

## Decisions made since reconnaissance

These are settled. Do not re-litigate them, but do flag if the data contradicts any.

1. **Primary denominator is MD/DO**, not the "eligible" population. Reason: MD/DOs have ~13 consistent program years of Open Payments coverage. Non-physician practitioners only became covered recipients in PY2021, so their "never engaged" means "never since 2021" — a structurally shorter window. Report all three denominators (all prescribers, eligible, MD/DO) but anchor on MD/DO.

2. **Drop all brand-share metrics.** 44% suppression concentrated among low-volume prescribers, who skew never-engaged, biases brand share in exactly the direction that would flatter the finding. Use total claims and total drug cost instead.

3. **State is a first-class stratification variable.** The state spread found in reconnaissance (66.3% VT to 9.8% MS) appears to track state pharmaceutical gift-ban and disclosure laws. Vermont banned most gifts to providers in 2009 (18 VSA §§ 4631a, 4632); Minnesota, Maine, Massachusetts, West Virginia, and DC have disclosure or restriction regimes of varying strength.

   **Do NOT hardcode a legal classification.** That list is unverified for current status — several state reporting laws were repealed or altered after the federal Sunshine Act took effect, and the reconnaissance top-seven includes states (WA, OR, WI) whose statutes have not been checked. Treat state as an empirical variable. The legal explanation is a hypothesis for a later phase, not an input here.

4. **The reframed question:** not "who has pharma never reached?" but **"how much of never-engagement is structural versus behavioral?"** Structural = law, employer policy, practice setting. Behavioral = low volume, geography, individual choice. These are different commercial targets and nobody has separated them.

---

## Definitions

- **Never engaged** — NPI present in Part D 2024, absent from the Covered Recipient Profile Supplement (which reconnaissance confirmed is cumulative across all program years).
- **Ever engaged** — NPI present in both.
- **Analytic population** — Part D 2024 prescribers restricted to MD/DO, identified using the empirically derived credential/taxonomy approach from reconnaissance Q7.

---

## Tasks

### A1 — Build and persist the analytic table

Join Part D 2024 → NPPES (specialty, credential, practice state, practice ZIP, entity type) → engagement flag from the Profile Supplement.

Persist as `work/analytic_population.parquet`. One row per NPI. Include enough columns that later phases don't need to re-derive anything: NPI, credential, primary taxonomy, specialty description, practice state, practice ZIP, total claims, total drug cost, beneficiary count, engagement flag, and population flags (is_mddo, is_npp, is_pharmacist, is_student).

> **Checkpoint:** row count matches the Part D prescriber count from reconnaissance Q2, and the never-engaged share reproduces the reconnaissance figures for each denominator. If it doesn't reproduce, stop and report — something in the join changed.

### A2 — Test the NPP observation-window artifact

Hypothesis: NPP never-engagement is inflated relative to MD/DO because NPPs have only ~5 program years of coverage versus ~13.

Test it: compute never-engaged rates for MD/DO and NPP separately. Then restrict the engagement definition to PY2021-and-later only, and recompute both. If the MD/DO rate rises substantially toward the NPP rate under the matched window, the artifact is confirmed.

Report both the naive and window-matched comparison.

> Note: this requires program-year information. The Profile Supplement has no year column, so you will need the General Payments files to establish recency. Only PY2025 is on disk. If PY2025 alone is insufficient to test this properly, say so and specify exactly which additional program years would be needed rather than working around it.

### A3 — Volume distribution ⭐ **the most important task**

The commercial question the entire project rests on: **are never-engaged prescribers low-volume and marginal, or is there a real population of high-volume prescribers nobody has ever touched?**

- Distribution of total claims and total drug cost, never-engaged vs. ever-engaged (median, quartiles, and the full decile breakdown)
- Cut the MD/DO population into prescribing-volume deciles. Report never-engaged rate within each decile.
- **The headline number: how many never-engaged MD/DOs sit in the top two volume deciles, and what share of total Part D claims and cost do they represent?**

That last figure is the finding. If it is near zero, the white-space story is much weaker and we need to know that immediately. If it is substantial, that is the result.

### A4 — Specialty

- Never-engaged rate by specialty, MD/DO only, for specialties with adequate sample size (state your threshold)
- Rank specialties by *count* of high-volume never-engaged prescribers, not just by rate — a high rate in a tiny specialty is less interesting than a moderate rate in a large one
- Note any specialty where the pattern looks structural rather than behavioral (e.g. specialties with little or no pharma commercial interest)

### A5 — Geography

- Never-engaged rate by state, MD/DO only. This refines the reconnaissance figure, which used all prescribers.
- Report alongside each state's count of high-volume never-engaged prescribers.
- If a rural/urban classification can be derived from what is on disk, do it and document the method. If it requires an external crosswalk we do not have (RUCA, county typology), **do not download one** — flag it as a gap for the next phase.

### A6 — Structural vs. behavioral, first cut

How much of the variation in never-engagement is accounted for by state alone? A simple descriptive decomposition is sufficient — between-state versus within-state variance. This is scene-setting for Phase B (practice ownership), not a causal model.

Do not fit predictive models. Descriptive only.

---

## Rules

- **Descriptive analysis only.** No regression, no prediction, no causal claims.
- **Show your SQL.** Jacob verifies rather than trusting.
- Round percentages to two decimals; report raw counts alongside every percentage.
- If a number seems implausible, say so rather than reporting it flat.
- **Do not delete source CSVs.** 148 GB free; there is no reason.
- **Do not download anything.**
- If a task cannot be completed with the data on disk, say so explicitly and specify what would be needed. Do not substitute a proxy without flagging it.

---

## Output

Write `PHASE_A_FINDINGS.md`, organized by task number. For each: the answer, the query, any caveat.

At the top, put a short section titled **Headline** containing:
- Never-engaged count and share, MD/DO (primary), with the other two denominators alongside
- The count of high-volume never-engaged prescribers from A3 and their share of total claims and cost
- Anything that contradicts the reconnaissance findings or the decisions above

Then a short section titled **What surprised me** — anything in the data that was not anticipated by this task list. That section is often the most valuable part.
