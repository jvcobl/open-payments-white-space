# Phase F — Figure Revision

Small, focused. Layout and accuracy fixes on the three figures, plus one diagnostic query. No new analysis beyond F4.

---

## F1 — Figure 1 (discriminant scatter)

Content and encoding are correct. Four fixes:

1. **The two leader lines cross.** Rochester's label sits above Boston University's, but Rochester's point is below and to the left of BU's. Swap the label positions so the lines run parallel rather than crossing.
2. **Legend collides with data** — a grey point overlaps "(n=812)". Move the legend to the lower-right quadrant, which is empty.
3. **Crop the axes to 0.3–1.7 on both.** No data exists below 0.4 on x or 0.25 on y; roughly a quarter of the canvas is unused. Keep the y = x diagonal drawn across the visible range.
4. Shorten the y-axis label so it doesn't wrap awkwardly. Something like "Non-F&B reach (observed ÷ expected)" with the channel list moved to the caption.

**Add a third group marker.** Plot the gift-ban state aggregate — the VT/MN/ME/MA group position — as a distinct marker (e.g. a green square).

Reason: the AMCs sit at F&B ≈ 0.85–1.2, which is *normal* meal reach relative to their own states. Only Rochester and BU show real suppression. So the current annotation implies AMCs occupy the upper-left gift-ban region when they in fact sit mid-plot inside the reference cloud. Showing the state aggregate makes the actual three-position structure visible: **states up-left, AMCs centre, Kaiser down-left.**

**Revise the caption accordingly.** The claim to make is that the discriminant detects *elimination* of a commercial relationship rather than *restriction* of one — AMCs restrict detailing and still look ordinary, because consulting, speaking, and research continue. Do not describe the AMCs as showing a gift-ban signature.

## F2 — Figure 2 (state channel composition)

**Currently broken: the legend prints directly over the title, making it unreadable.**

1. Move the legend **below the x-axis**, horizontal, single row.
2. **Reorder the stack so relationship-only is the bottom segment**, anchored at zero. Order from bottom: relationship-only, no record, meal-only, fully engaged.

   Reason: relationship-only is the discriminating variable and at 0.15–6.42% it is a thin band. Floating mid-stack it cannot be compared across states; anchored at zero it can.
3. Consider a broken or secondary y-axis, or an inset, so the 0–7% range is legible. Use judgement — do not clutter it.
4. Keep all 52 states. Keep the existing caption content, including the qualifier that Vermont's absolute non-F&B reach is still below Mississippi's.

## F3 — Figure 3 (volume gradient)

Layout is fine. One accuracy fix:

**The caption states the adjusted line runs 71.5% → 62.8% (1.14×, essentially flat). It is not flat and those are endpoints.** The series dips to 53.2% at decile 8 before rising. True range is 71.5 to 53.2, i.e. 1.34×.

Rewrite to state the actual range and note the non-monotonicity. It remains flat *relative to* the baseline's 3.0× — say that, rather than implying it is flat in absolute terms.

## F4 — Diagnose the decile-8 dip ⭐

One query, reported in `PHASE_F_NOTES.md`, not a new phase.

Adjusted never-engagement should fall monotonically with prescribing volume — higher-volume physicians are more likely to hold non-meal relationships. Instead it bottoms at decile 8 and rises through 9 and 10.

Check the obvious candidates:
- Specialty composition shifting across the top deciles
- Organization type — do deciles 9–10 contain disproportionately many physicians in large organizations that suppress both channels?
- The `never_fnb5` definition interacting with volume in some structural way

Report what you find. **If it is unexplained, say so plainly** — an honest "this is unexplained" is fine and better than a speculative story. It needs to be known before it appears in a writeup, because a reader will see it.

---

## Rules

- Only these figures and the F4 query. No re-analysis.
- Every caption must retain the wording that "never engaged" means no *reported* payment.
- Regenerate all three PNGs and confirm `run_all.sh` still passes.
- Do not commit. Do not delete.

## Output

`PHASE_F_NOTES.md` — what changed in each figure, and the F4 result.
