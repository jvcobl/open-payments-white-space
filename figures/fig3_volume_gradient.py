#!/usr/bin/env python3
"""
fig3_volume_gradient.py

PRODUCES : figures/fig3_volume_gradient.png
SOURCE   : PHASE_A_FINDINGS.md §A3; PHASE_R_FINDINGS.md §R1
INPUTS   : figures/data/volume_gradient.csv (from 03_state_analysis.sql)

Never-engaged rate by prescribing-volume decile, under both engagement
definitions on one axis.

Baseline (absent from the Profile Supplement) falls steeply and near
monotonically, 32.5% to 10.8% (a 3.0x spread): the reading that industry
engagement tracks prescribing volume. Reclassify physicians whose entire
five-year footprint is food and beverage and that spread largely collapses.

The adjusted line is NOT flat in absolute terms: it runs 71.5% at decile 1 down
to a minimum of 53.2% at decile 8, then rises again through 9 and 10. That is a
1.34x range, and non-monotonic. It is flat only relative to the baseline's 3.0x.
The decile-8 dip is diagnosed in PHASE_F_NOTES.md §F4.

The gap between the two lines is the meal channel. Most of what looks like
commercially rational targeting by volume is the distribution of who got a
sandwich.

Detail moved here from the figure caption to keep that caption to three lines:

  * Baseline falls 32.5% -> 10.8% across deciles, a 3.0x spread, near monotonic.
  * The decile-8 turn is specialty composition. Specialist share peaks at decile
    8 (37.4%) and collapses to 10.9% by decile 10, while primary care runs
    35.2% -> 56.0% -> 80.2%. Specialists hold consulting, speaking and research
    relationships at far higher rates; the top deciles are dominated by
    high-volume primary-care prescribers whose whole footprint is meals.
    Standardising on specialty makes the series perfectly monotonic
    (71.4 -> 56.2). Organisation type is ruled out. See PHASE_F_NOTES.md F4.
  * Both series are descriptive; neither implies causation.
"""
import os
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
df = pd.read_csv(os.path.join(HERE, "data", "volume_gradient.csv")).sort_values("volume_decile")

fig, ax = plt.subplots(figsize=(10.4, 6.6))
x = df["volume_decile"]

ax.fill_between(x, df["pct_never_baseline"], df["pct_never_adjusted"],
                color="#8fb8de", alpha=0.28, zorder=1,
                label="difference = the meal channel")
ax.plot(x, df["pct_never_adjusted"], marker="s", ms=6.0, lw=2.1,
        color="#c2352b", zorder=3,
        label="Adjusted: also counts physicians whose only\nfive-year footprint is food and beverage")
ax.plot(x, df["pct_never_baseline"], marker="o", ms=6.0, lw=2.1,
        color="#1f5fa8", zorder=3,
        label="Baseline: absent from Open Payments entirely")

for xi, yi in [(x.iloc[0], df["pct_never_baseline"].iloc[0]),
               (x.iloc[-1], df["pct_never_baseline"].iloc[-1])]:
    ax.annotate(f"{yi:.1f}%", xy=(xi, yi), xytext=(0, -17),
                textcoords="offset points", ha="center",
                fontsize=9, color="#14406f", fontweight="bold")
for xi, yi in [(x.iloc[0], df["pct_never_adjusted"].iloc[0]),
               (x.iloc[-1], df["pct_never_adjusted"].iloc[-1])]:
    ax.annotate(f"{yi:.1f}%", xy=(xi, yi), xytext=(0, 10),
                textcoords="offset points", ha="center",
                fontsize=9, color="#8d241d", fontweight="bold")

ax.set_xticks(range(1, 11))
ax.set_xlabel("Part D prescribing-volume decile  (1 = fewest claims, 10 = most)")
ax.set_ylabel("Never-engaged MD/DO prescribers (%)")
ax.set_ylim(0, 80)
ax.set_title("The volume gradient is mostly a meal-channel artifact",
             fontsize=13, pad=12)
ax.grid(alpha=0.22, lw=0.6)
ax.set_axisbelow(True)
for s in ("top", "right"):
    ax.spines[s].set_visible(False)
ax.legend(loc="center right", fontsize=8.8, frameon=False)

b0, b9 = df["pct_never_baseline"].iloc[0], df["pct_never_baseline"].iloc[-1]
a0, a9 = df["pct_never_adjusted"].iloc[0], df["pct_never_adjusted"].iloc[-1]
# The adjusted series is NOT flat and NOT monotonic: state its true range and
# where it turns, rather than quoting endpoints.
a_min = df["pct_never_adjusted"].min()
a_max = df["pct_never_adjusted"].max()
a_min_dec = int(df.loc[df["pct_never_adjusted"].idxmin(), "volume_decile"])
fig.text(0.5, 0.012,
         f"The adjusted line is not flat: it runs {a_max:.1f}% down to {a_min:.1f}% at decile {a_min_dec}, then rises "
         f"again. That is a {a_max/a_min:.2f}× range, and non-monotonic.\n"
         f"That decile-{a_min_dec} turn is specialty composition, not a channel effect. Standardising on specialty makes "
         "the series monotonic (PHASE_F_NOTES.md §F4).\n"
         "\"Never engaged\" means no *reported* payment: drug samples and detailing are never reportable under the "
         "Sunshine Act.",
         ha="center", fontsize=8.4, color="#333333")

fig.tight_layout(rect=[0, 0.085, 1, 1])
out = os.path.join(HERE, "fig3_volume_gradient.png")
fig.savefig(out, dpi=200)
print(f"wrote {out}")
