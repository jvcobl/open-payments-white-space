# Phase P — Repository Assembly and Figures

**Read `PHASE_R_FINDINGS.md`, `PHASE_W_FINDINGS.md`, and `PHASE_X_FINDINGS.md` first.** No new analysis. This is packaging.

The analysis is complete. The problem is that it exists as ad-hoc queries across seven findings documents rather than as a runnable pipeline. Fix that.

---

## P1 — Repository structure

Create in `~/whitespace`:

```
whitespace/
├── README.md              ← Jacob supplies; do not write it
├── scripts/               ← numbered, runnable, in order
├── figures/               ← PNG + the script that made each
├── findings/              ← move the 7 phase documents here
├── work/                  ← Parquet (gitignored)
└── .gitignore
```

`.gitignore` must exclude `work/`, all `*.csv`, all `*.parquet`. **No CMS data in the repo** — the files are hundreds of MB to 11 GB and are publicly redownloadable.

Initialize git. Do not commit until Jacob has reviewed.

## P2 — Extract the pipeline into scripts

Pull the SQL out of the findings documents into numbered, runnable scripts:

```
scripts/
├── 00_convert_to_parquet.sh
├── 01_build_analytic_population.sql
├── 02_channel_classification.sql
├── 03_state_analysis.sql
├── 04_organization_analysis.sql
├── 05_discriminant.sql
├── 06_amc_validation.sql
└── run_all.sh
```

Each script: a header comment stating what it produces, which findings document it comes from, and its inputs. Every script must run standalone given the Parquet files.

**`run_all.sh` must reproduce these headline numbers, and print them for checking:**

| Figure | Value |
|---|---|
| MD/DO Part D prescribers | 696,647 |
| Never-engaged (baseline) | 146,459 (21.02%) |
| Selection-robust group | 553 ($924M) |
| Meal-only, 5-year | 58.7% |
| Four-cell relationship-only | 8,715 (1.25%) |
| AMC median discriminant | 1.110 |
| Kaiser median discriminant | 0.727 |

> **If any number fails to reproduce, stop and report it.** A pipeline that doesn't regenerate the findings is worse than no pipeline.

## P3 — Figures

Three, in `figures/`, each with its generating script. Matplotlib is fine. Clean and legible over decorative — no chartjunk, readable axis labels, a caption line stating what the reader should take from it.

**Figure 1 — the two-axis discriminant.** ⭐ The most important artifact in the project.

Scatter. X = state-relative F&B ratio, Y = state-relative non-F&B ratio. Plot the 8 Kaiser entities, the 18 AMCs, and the reference group, distinctly marked. Draw the y = x diagonal.

Annotate **Rochester (0.530) and Boston University (0.718)** explicitly — they suppress meals as hard as Kaiser (0.577) and are still correctly separated because their non-F&B ratios are 0.717 and 0.917 against Kaiser's 0.439. That is the single clearest demonstration that one axis would have failed and two succeed.

**Figure 2 — channel composition by state.** Stacked bars, states ordered by F&B reach, from VT (24.64% any F&B) to MS (90.07%). Four segments: fully engaged, meal-only, relationship-only, no record. The point: relationship-only runs 6.42% in Vermont against 0.15% in Mississippi.

**Figure 3 — the volume gradient.** Never-engaged rate by prescribing-volume decile, baseline and F&B-adjusted on the same axes. Baseline falls monotonically 32.52% → 10.83%; the adjusted line is flat. That contrast is the meal-channel artifact in one image.

## P4 — Reproducibility check

Run `run_all.sh` end to end from the Parquet files. Confirm every headline figure regenerates. Report the runtime.

---

## Rules

- **Do not write README.md.** Jacob supplies it.
- No new analysis. If a number can't be reproduced, report it rather than recomputing it a different way.
- Do not commit to git.
- Do not delete anything.
- Keep dependencies minimal — DuckDB CLI, Python with matplotlib and pandas. Nothing else.

---

## Output

Write `PHASE_P_NOTES.md`: the repo tree, what each script does, the reproducibility check result with any discrepancy, and anything Jacob must fix by hand before committing.
