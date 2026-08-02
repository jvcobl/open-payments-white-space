# Phase B — Practice Ownership and Structure

**Read `PHASE_A_FINDINGS.md`, `PHASE_A_EXT_FINDINGS.md`, and `PHASE_S_FINDINGS.md` first.**

Uses `work/analytic_population.parquet`, `DAC_NationalDownloadableFile.csv`, and `Facility_Affiliation.csv` — all already converted to Parquet in `work/`. No new data required.

---

## Where the project stands

Three results constrain this phase:

1. **Phase A** — 21.02% of MD/DO Part D prescribers have never appeared in Open Payments. Specialty explains 12.63% of variance, state 4.22%, rurality 0.07%. **Over 81% is unexplained.**
2. **Extension** — the high-volume white space is 96.8% generic prescribers. The selection-robust group is 553 physicians / $924M, of which 40% are Cardiology, Endocrinology, and Rheumatology.
3. **Phase S** — the state effect is predominantly a meal-channel artifact. Reclassifying F&B-only engagement collapses the spread from 8.39× to 1.16×.

Phase B tests the remaining structural hypothesis: **practice-level policy.** Many health systems and academic centers restrict or ban industry representative access. If that mechanism operates, group size and institutional affiliation should predict non-engagement.

---

## Critical design requirement — run everything twice

Phase S established that the baseline never-engaged flag is contaminated: it conflates "no industry relationship" with "no *reportable* industry relationship." Every analysis in this phase must therefore be run under **both** definitions:

- **Baseline** — absent from the Profile Supplement (cumulative, all years)
- **F&B-adjusted** — baseline PLUS physicians whose only PY2025 engagement is food-and-beverage

Report both side by side throughout. Where they disagree, the disagreement is the finding.

> Note the known bias: the F&B-adjusted definition is an upper bound, because 32.3% of ever-engaged MD/DOs have no PY2025 payment to classify. Additional program years are being obtained separately. State this limitation wherever the adjusted figure appears.

---

## Tasks

### B1 — Join and assess coverage

Join DAC and Facility_Affiliation to the analytic population on NPI.

- What share of MD/DO Part D prescribers appear in DAC? In Facility_Affiliation?
- Is the missingness random, or does it correlate with engagement status, volume, specialty, or state?

> **If non-enrollment in DAC correlates with never-engagement, every result in this phase is confounded.** DAC covers Medicare-enrolled clinicians; physicians outside that population are missing for reasons that may relate to practice type. Check this first and report it prominently. If the correlation is strong, say so and treat the rest of the phase as provisional.

### B2 — Group size

`num_org_mem` is practice group size.

- Never-engaged rate by group-size band (solo, 2–9, 10–49, 50–199, 200+ — or a binning you justify)
- **Stratified by specialty and by volume decile.** Group size correlates with both; an unstratified comparison will read a specialty effect as an ownership effect.
- Report under both engagement definitions

Phase A's direction of prediction: larger and system-owned practices should show *higher* non-engagement, since institutional policies restrict rep access.

### B3 — Facility affiliation

- Never-engaged rate by `facility_type` (hospital, critical access, rehab, etc.)
- Never-engaged rate for affiliated vs. unaffiliated physicians
- Physicians affiliated with multiple facilities vs. one vs. none
- Both definitions, stratified by specialty

### B4 — The organizational clustering test ⭐

If practice policy is the mechanism, never-engagement should **cluster within organizations** far more than chance.

- For organizations (`org_pac_id`) with ≥20 MD/DO Part D prescribers, compute the never-engaged rate within each
- Compare the observed distribution to what independence would produce (a simple binomial expectation is sufficient — no models)
- **How many organizations are at or near 100% never-engaged? At or near 0%?**
- Report the largest organizations at each extreme by prescriber count

> This is the strongest available test of the institutional-policy hypothesis. Clustering is the signature; a flat distribution would falsify it.

### B5 — The selection-robust 553

For the 553 high-volume / high-cost never-engaged MD/DOs from the Extension:

- Practice characteristics — group size, affiliation, organization
- Do they concentrate in a small number of organizations?
- **The 60 rheumatologists specifically:** how many distinct `org_pac_id` values do they span? Name the largest organizations and their prescriber counts.

> Sixty rheumatologists averaging ~$2.9M each in Part D spend, in a biologics-driven specialty, with zero recorded industry contact, is the single most anomalous group in the project. If they cluster institutionally, that identifies the mechanism. If they are scattered, the institutional explanation fails for them and something else is operating.

### B6 — Updated variance decomposition

Rerun Phase A's A6 decomposition with practice variables added. How much does organization, group size, and affiliation add beyond specialty, state, and rurality?

Report the residual under both engagement definitions.

> **Both outcomes are informative and should be reported without spin.** If practice variables explain a substantial share, the structural story holds. If the residual stays above ~75%, the honest conclusion is that non-engagement is **not predictable from observable public characteristics** — which is itself a significant finding about the limits of public-data targeting.

---

## Rules

- **Descriptive only.** No predictive models, no causal claims.
- Every figure under both engagement definitions unless a task says otherwise.
- Show your SQL.
- Raw counts alongside every percentage.
- Do not download, do not delete.
- Flag prominently anything contradicting Phases A, Extension, or S.
- Where the data cannot answer a question, say so and specify what would be needed.

---

## Output

Write `PHASE_B_FINDINGS.md`.

Open with **Headline**: the B4 clustering verdict, the B6 residual under both definitions, and the B5 rheumatology result.

Close with **What surprised me**, and a **Reinterpretation** section for any earlier conclusion that should now read differently.
