#!/usr/bin/env python3
"""
fig1_discriminant.py

PRODUCES : figures/fig1_discriminant.png
SOURCE   : PHASE_X_FINDINGS.md §X2-X3; PHASE_W_FINDINGS.md §W4-W5
INPUTS   : figures/data/discriminant_orgs.csv    (05_discriminant.sql)
           figures/data/discriminant_amcs.csv    (06_amc_validation.sql)
           figures/data/discriminant_states.csv  (05_discriminant.sql)

The two-axis channel measure. Each point is positioned by how much its
physicians' two payment channels are suppressed relative to expectation.

Three positions, and the third is the point of the figure:

  * Gift-ban STATES sit up and left: meals suppressed, relationships less so.
  * Kaiser entities sit down and left: BOTH channels suppressed.
  * The academic medical centres sit in the MIDDLE, inside the reference cloud.

That last position is the corrective. The AMCs restrict detailing, and their
food-and-beverage reach is nonetheless near normal for their own states (median
ratio 0.919 against 1.032 for all other organisations). Only Rochester, UCSF and
Boston University show real meal suppression. So the measure is not detecting
"has a restriction policy". It is detecting whether a commercial relationship
was ELIMINATED. AMCs restrict the sales call and keep consulting, speaking and
research; Kaiser ends the relationship.

NORMALISATION WARNING, stated on the figure itself: organisations are scored
against their own state's baseline (Phase W W5), state groups against the
national baseline, because scoring a state against itself is circular. The two
marker families are therefore not numerically comparable; only their direction
is.

Point annotations are given as (F&B ratio, non-F&B ratio), and every text
element on the plot carries a semi-transparent white backing box so it stays
legible over the scatter cloud and the y = x diagonal.
"""
import os
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, "data")

# Backing box for every text element drawn inside the axes.
BBOX = dict(boxstyle="round,pad=0.25", facecolor="white", alpha=0.85,
            edgecolor="none")

orgs = pd.read_csv(os.path.join(DATA, "discriminant_orgs.csv"))
amcs = pd.read_csv(os.path.join(DATA, "discriminant_amcs.csv"))
states = pd.read_csv(os.path.join(DATA, "discriminant_states.csv"))

orgs["is_kaiser"] = orgs["is_kaiser"].astype(str).str.lower().isin(["true", "1", "t"])
kaiser = orgs[orgs["is_kaiser"]]
ref = orgs[~orgs["is_kaiser"]]

LO, HI = 0.3, 1.7
fig, ax = plt.subplots(figsize=(9.6, 7.8))

ax.plot([LO, HI], [LO, HI], color="#4a4a4a", lw=1.1, ls="--", zorder=2)

ax.scatter(ref["ratio_fnb"], ref["ratio_non"], s=13, c="#c9cdd4",
           edgecolors="none", alpha=0.65, zorder=1,
           label=f"All other organisations ≥100 prescribers (n={len(ref)})")
ax.scatter(amcs["ratio_fnb"], amcs["ratio_non"], s=80, marker="o",
           facecolors="none", edgecolors="#1f5fa8", linewidths=1.9, zorder=3,
           label=f"Academic medical centres, Larkin et al. (n={len(amcs)})")
ax.scatter(kaiser["ratio_fnb"], kaiser["ratio_non"], s=108, marker="D",
           c="#c2352b", edgecolors="white", linewidths=0.8, zorder=4,
           label=f"Kaiser / Permanente entities (n={len(kaiser)})")

# State groups: national baseline, see normalisation note.
order = ["Gift-ban states (VT, MN, ME, MA)",
         "Empirically similar (WA, OR, WI)",
         "Low-restriction states (MS, AL, TX)"]
colours = {order[0]: "#1a7f47", order[1]: "#57a77b", order[2]: "#9dbfa9"}
offsets = {order[0]: (-15, 4), order[1]: (14, -30), order[2]: (14, 7)}
halign  = {order[0]: "right", order[1]: "left", order[2]: "left"}
for i, name in enumerate(order):
    row = states[states["state_group"] == name]
    if row.empty:
        continue
    x, y = float(row["ratio_fnb"].iloc[0]), float(row["ratio_non"].iloc[0])
    ax.scatter([x], [y], s=175, marker="s", c=colours[name],
               edgecolors="white", linewidths=1.2, zorder=5,
               label=("State aggregates (national baseline)" if i == 0 else None))
    ax.annotate(name.replace(" states", "").replace(" (", "\n("),
                xy=(x, y), xytext=offsets[name], textcoords="offset points",
                fontsize=8.4, color="#14532c", ha=halign[name],
                fontweight="bold", zorder=7, bbox=BBOX)

ax.text(0.335, 1.63, "meals suppressed more than relationships",
        fontsize=9.6, color="#1a7f47", va="top", zorder=7, bbox=BBOX)
ax.text(1.20, 0.60, "relationships suppressed\nmore than meals",
        fontsize=9.6, color="#c2352b", va="bottom", ha="left",
        zorder=7, bbox=BBOX)
ax.annotate("both suppressed\nequally  (y = x)", xy=(1.44, 1.44),
            xytext=(1.34, 1.22), fontsize=8.5, color="#4a4a4a", ha="left",
            zorder=7, bbox=BBOX,
            arrowprops=dict(arrowstyle="-", lw=0.8, color="#4a4a4a"))

# Coordinate form keeps these short enough to sit clear of the cloud. Rochester
# is below-left of Boston University, so its label sits below-left and BU's
# above-left, which keeps the two leader lines parallel rather than crossing.
# Label positions are in DATA coordinates so they can be placed against the
# cloud and the diagonal exactly, rather than by pixel offset.
notes = {
    "Univ Rochester":    ("Rochester (0.53, 0.72)", (0.355, 0.630)),
    "Boston University": ("Boston University (0.72, 0.92)", (0.395, 1.025)),
}
for inst, (label, pos) in notes.items():
    row = amcs[amcs["institution"] == inst]
    if row.empty:
        continue
    x, y = float(row["ratio_fnb"].iloc[0]), float(row["ratio_non"].iloc[0])
    ax.annotate(label, xy=(x, y), xytext=pos, textcoords="data",
                fontsize=8.6, color="#14406f", ha="left", va="center",
                zorder=7, bbox=BBOX,
                arrowprops=dict(arrowstyle="-", lw=0.9, color="#14406f"))

kx, ky = kaiser["ratio_fnb"].median(), kaiser["ratio_non"].median()
ax.annotate("Kaiser median (0.58, 0.44)", xy=(kx, ky),
            xytext=(0.80, 0.370), textcoords="data", fontsize=8.6,
            color="#8d241d", ha="left", va="center", zorder=7, bbox=BBOX,
            arrowprops=dict(arrowstyle="-", lw=0.9, color="#8d241d"))

ax.set_xlim(LO, HI)
ax.set_ylim(LO, HI)
ax.set_xlabel("F&B reach  (observed ÷ expected)")
ax.set_ylabel("Non-F&B reach  (observed ÷ expected)")
ax.set_title("The measure detects elimination of a relationship, not restriction of one",
             fontsize=13, pad=12)
ax.grid(alpha=0.22, lw=0.6)
ax.set_axisbelow(True)
for s in ("top", "right"):
    ax.spines[s].set_visible(False)
ax.legend(loc="lower right", fontsize=8.5, frameon=False)

amc_fnb = amcs["ratio_fnb"].median()
ref_fnb = ref["ratio_fnb"].median()
fig.text(0.5, 0.005,
         "Expected = the physician's own specialty × prescribing-volume decile; for organisations also × their own state. "
         "Non-F&B covers consulting,\n"
         "speaking, travel, education and research. Annotated values are (F&B ratio, non-F&B ratio). "
         "State aggregates use the national baseline\n"
         "(scoring a state against itself is circular), so squares and circles are not numerically comparable, only directionally. "
         "The AMCs restrict\n"
         f"detailing yet their meal reach is near normal ({amc_fnb:.2f} against {ref_fnb:.2f} for all other organisations) and their "
         "relationships continue, so they sit\n"
         "mid-plot. Kaiser ends both. \"Never engaged\" throughout means no *reported* payment.",
         ha="center", fontsize=8.1, color="#333333")

fig.tight_layout(rect=[0, 0.095, 1, 1])
out = os.path.join(HERE, "fig1_discriminant.png")
fig.savefig(out, dpi=200)
print(f"wrote {out}")
