#!/usr/bin/env python3
"""
fig2_state_channel.py

PRODUCES : figures/fig2_state_channel.png
SOURCE   : PHASE_R_FINDINGS.md §R2
INPUTS   : figures/data/state_channel.csv (from 03_state_analysis.sql)

Channel composition of every state's MD/DO Part D prescribers, PY2021-2025,
ordered by food-and-beverage reach. Four mutually exclusive cells.

Two layout decisions, both in service of one variable:

  * relationship-only is the BOTTOM segment of the stack, anchored at zero.
    It runs 0.15% to 6.42%. Floating mid-stack it cannot be compared across
    states; anchored at zero it can.
  * it also gets its own panel on a 0-7% scale, because a 6-point band inside a
    100-point axis is not legible however it is anchored.

The point: relationship-only runs 6.42% in Vermont against 0.15% in
Mississippi. But Vermont's ABSOLUTE non-F&B reach (17.5%) is still below
Mississippi's (35.2%): gift-ban states receive less industry contact of every
kind; they simply lose the meal far faster than they lose the professional
relationship.
"""
import os
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
df = pd.read_csv(os.path.join(HERE, "data", "state_channel.csv"))
df = df.sort_values("pct_any_fnb").reset_index(drop=True)

REL = "#c2352b"
# Bottom of the stack first. relationship-only is anchored at zero.
segments = [
    ("pct_relationship_only", "Relationship-only", REL),
    ("pct_no_record",         "No record",         "#e3e5e8"),
    ("pct_meal_only",         "Meal-only",         "#8fb8de"),
    ("pct_fully_engaged",     "Fully engaged",     "#1f5fa8"),
]

fig, (top, ax) = plt.subplots(
    2, 1, figsize=(13.8, 8.0), sharex=True,
    gridspec_kw={"height_ratios": [1, 3.6], "hspace": 0.08})

# ── top panel: the discriminating band, on its own scale ─────────────────────
top.bar(df["state"], df["pct_relationship_only"], color=REL,
        width=0.82, edgecolor="white", linewidth=0.35)
top.set_ylim(0, 7)
top.set_ylabel("Relationship-only (%)", fontsize=9.5)
top.grid(axis="y", alpha=0.25, lw=0.6)
top.set_axisbelow(True)
for s in ("top", "right"):
    top.spines[s].set_visible(False)
top.tick_params(axis="y", labelsize=8.5)
top.set_title("Channel composition by state, PY2021–2025", fontsize=13, pad=10)

for st in ("VT", "MS"):
    row = df[df["state"] == st]
    if row.empty:
        continue
    i = int(row.index[0])
    v = float(row["pct_relationship_only"].iloc[0])
    top.annotate(f"{st} {v:.2f}%", xy=(i, v), xytext=(0, 5),
                 textcoords="offset points", ha="center",
                 fontsize=8.6, color="#8d241d", fontweight="bold")

# ── bottom panel: full composition ───────────────────────────────────────────
bottom = pd.Series(0.0, index=df.index)
for col, label, colour in segments:
    ax.bar(df["state"], df[col], bottom=bottom, label=label,
           color=colour, width=0.82, edgecolor="white", linewidth=0.35)
    bottom = bottom + df[col]

ax.set_ylim(0, 100)
ax.set_ylabel("Share of the state's MD/DO Part D prescribers (%)")
ax.set_xlabel("State, ordered by food-and-beverage reach (lowest → highest)")
ax.tick_params(axis="x", labelsize=8.4, rotation=90)
ax.grid(axis="y", alpha=0.22, lw=0.6)
ax.set_axisbelow(True)
for s in ("top", "right"):
    ax.spines[s].set_visible(False)

# Legend below the x-axis, single horizontal row (figure-level so it is not
# clipped by the axes box).
handles, labels = ax.get_legend_handles_labels()
fig.legend(handles, labels, loc="center", bbox_to_anchor=(0.5, 0.125),
           fontsize=10, frameon=False, ncol=4)

def pct(state, col):
    row = df[df["state"] == state]
    return None if row.empty else float(row[col].iloc[0])

vt, ms = pct("VT", "pct_relationship_only"), pct("MS", "pct_relationship_only")
note = ""
if vt is not None and ms is not None:
    vt_r, ms_r = round(vt, 2), round(ms, 2)
    note = (f"Relationship-only (dark red, bottom of the stack and shown alone above) is high at the gift-ban end "
            f"({vt_r:.2f}% in Vermont), low at the low-restriction end\n"
            f"({ms_r:.2f}% in Mississippi), and noisy in between: the middle 40 states bounce between 0.41% and 2.83% "
            f"with no clean ordering. The {vt_r/ms_r:.0f}× is a comparison\nof extremes, not a gradient. ")
fig.text(0.5, 0.012,
         note +
         "Vermont's absolute non-F&B reach (17.5%) is nonetheless still below Mississippi's (35.2%). Gift-ban states "
         "receive less industry contact of every kind,\nbut they lose the meal far faster than they lose the professional "
         "relationship. \"Never engaged\" means no *reported* payment: samples and detailing are never reportable.",
         ha="center", fontsize=8.2, color="#333333")

fig.subplots_adjust(left=0.055, right=0.985, top=0.925, bottom=0.235)
out = os.path.join(HERE, "fig2_state_channel.png")
fig.savefig(out, dpi=200)
print(f"wrote {out}")
