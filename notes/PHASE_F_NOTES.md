# Phase F — Figure Revision Notes

Generated 2026-08-02. Layout and accuracy fixes on the three figures, plus one diagnostic.
No re-analysis. `run_all.sh` still passes: **8 exact, 2 within the documented ±0.002 tolerance,
12 seconds.**

---

## F1 — Figure 1 (discriminant scatter)

All four layout fixes applied, plus the state aggregate, plus a rewritten claim.

| Fix | What changed |
|---|---|
| Crossing leader lines | Rochester's point is below-left of Boston University's, so Rochester's label now sits **below-left** and BU's **above-left**. The lines run parallel. |
| Legend colliding with data | Moved to the **lower-right quadrant**. |
| Wasted canvas | Axes cropped to **0.3–1.7** on both. The y = x diagonal is drawn across the visible range. |
| Wrapping y-axis label | Now `Non-F&B reach (observed ÷ expected)`; the channel list (consulting, speaking, travel, education, research) moved to the caption. |

### The state aggregate, and why it changes the reading

Added as green squares. All three state groups are plotted, not just the gift-ban one — the
low-restriction group at the opposite corner is what makes the axis of variation legible.

**Your diagnosis was right, and it corrects something I wrote in Phase X.** Checking the AMC
positions directly:

| | Median F&B ratio |
|---|---|
| All other organisations ≥100 prescribers | **1.032** |
| The 18 AMCs | **0.919** |
| Kaiser entities | 0.577 |

**Only 3 of the 18 AMCs fall below 0.80 on the F&B axis** — Rochester (0.530), Boston University
(0.718) and UCSF (0.793). The other fifteen have essentially normal meal reach for their own
states. The old figure's "gift-ban signature" arrow pointed at the upper-left region and the AMCs
were the highlighted set, which implied they lived there. They do not; they sit mid-plot inside
the reference cloud.

The three-position structure is now visible and labelled:

| Group | Position | F&B ratio | non-F&B ratio |
|---|---|---|---|
| **Gift-ban states** (VT, MN, ME, MA) | up and left | 0.689 | 0.815 |
| Empirically similar (WA, OR, WI) | up and left, nearer centre | 0.763 | 0.844 |
| Low-restriction states (MS, AL, TX) | up and right | 1.126 | 1.108 |
| **The 18 AMCs** | **centre** | **0.919** | **1.023** |
| **Kaiser entities** | **down and left** | **0.577** | **0.439** |

**Revised claim, on the title and in the caption:** the measure detects **elimination** of a
commercial relationship, not **restriction** of one. AMCs restrict detailing and still look
ordinary, because consulting, speaking and research continue. The figure no longer describes the
AMCs as showing a gift-ban signature anywhere.

### One thing I had to decide, flagged on the figure itself

**The squares and the circles use different denominators, and I could not avoid it.**
Organisations are scored against their own state's baseline (Phase W §W5). A *state* cannot be
scored against its own state — that is circular and returns 1.0 by construction — so state
aggregates use the **national** baseline.

Both the caption and a comment in `05_discriminant.sql` say so explicitly: the two marker
families are comparable **directionally, not numerically**. If you would rather not carry that
caveat, the alternative is to drop the squares, at the cost of losing the three-position
structure. I judged the structure worth the caveat, but it is a judgement and you may reverse it.

---

## F2 — Figure 2 (state channel composition)

**The broken legend is fixed** — it was overprinting the title, and now sits **below the x-axis
as a single horizontal row**, at figure level so the axes box cannot clip it.

**Stack reordered.** From the bottom: **relationship-only**, no record, meal-only, fully engaged.
Anchored at zero, the 0.15–6.42% band is now comparable across all 52 states instead of floating
mid-stack.

**Added a second panel rather than a broken axis.** Anchoring at zero makes the band *comparable*
but a 6-point range inside a 100-point axis is still not *legible*. The figure is now two panels
sharing the x-axis: a short top panel showing relationship-only alone on a 0–7% scale, and the
full composition below. Vermont and Mississippi are labelled on the top panel.

I chose this over a broken axis or an inset because it adds no visual furniture — no axis breaks,
no inset frame, no second legend — and the state ordering stays aligned between the two panels.
It is one extra panel and no extra clutter, which is the judgement the task asked for.

All 52 states retained. Caption content retained, including the qualifier that **Vermont's
absolute non-F&B reach (17.5%) is still below Mississippi's (35.2%)** and the "no *reported*
payment" wording.

---

## F3 — Figure 3 (volume gradient)

**Accuracy fix applied. The old caption was wrong and you were right to catch it.**

It read: *"adjusted runs 71.5% → 62.8% (1.14×, essentially flat)"*. Both halves were misleading —
those are endpoints of a non-monotonic series, and it is not flat.

| | Value |
|---|---|
| Adjusted, decile 1 | 71.5% |
| Adjusted, **minimum (decile 8)** | **53.2%** |
| Adjusted, decile 10 | 62.8% |
| **True range** | **71.5 → 53.2, i.e. 1.34×** |
| Baseline range | 32.5 → 10.8, i.e. 3.0× |

New caption states the true range, names the decile-8 turn, says the series is non-monotonic, and
says it is flat **only relative to** the baseline's 3.0× rather than flat in absolute terms. The
module docstring carries the same correction. The caption now also points to §F4 below.

---

## F4 — The decile-8 dip ⭐

**It is fully explained. It is specialty composition, and nothing else.**

### What is actually moving

`never_fnb5` is driven by whether a physician has any non-F&B relationship. Decomposed by decile:

```sql
SELECT clms_decile, round(100.0*count(*) FILTER (WHERE never_fnb5)/count(*),2) AS pct_never_adj,
       round(100.0*count(*) FILTER (WHERE n_nonfnb5>0)/count(*),2) AS pct_any_nonfnb
FROM 'work/analysis_base.parquet' GROUP BY 1 ORDER BY 1;
```

| Decile | % never (adjusted) | % with any non-F&B | % primary care | % specialist |
|---|---|---|---|---|
| 1 | 71.50 | 21.4 | 25.0 | 5.8 |
| 5 | 69.19 | 26.0 | 29.4 | 11.9 |
| 6 | 65.43 | 30.1 | 32.7 | 18.8 |
| 7 | 56.53 | 39.9 | 31.2 | 32.3 |
| **8** | **53.23** | **43.3** | 35.2 | **37.4** |
| 9 | 60.69 | 35.4 | **56.0** | 25.9 |
| 10 | 62.75 | 33.6 | **80.2** | 10.9 |

Non-F&B relationship reach peaks at decile 8 (43.3%) and falls away in 9 and 10. The dip in
never-engagement is the mirror image of that.

### Why: the top deciles stop being specialists and become primary care

Specialist share peaks at decile 8 (37.4%) and collapses to 10.9% by decile 10, while primary
care goes 35.2% → 56.0% → **80.2%**. Specialists hold consulting, speaking and research
relationships at far higher rates than primary-care physicians, who overwhelmingly receive meals
only. So the very highest-volume deciles are dominated by high-volume family-practice and
internal-medicine prescribers whose entire industry footprint is food and beverage — and adjusted
never-engagement rises again.

### The test: standardize on specialty and the dip disappears

Holding specialty mix at the national distribution:

| Decile | Crude | **Specialty-standardized** |
|---|---|---|
| 1 | 71.50 | 71.37 |
| 5 | 69.19 | 67.48 |
| 6 | 65.43 | 66.07 |
| 7 | 56.53 | 63.14 |
| **8** | **53.23** | **60.67** |
| **9** | **60.69** | **59.01** |
| **10** | **62.75** | **56.22** |

**Perfectly monotonic. The turn is entirely composition.**

### Organization type ruled out

The task's second candidate does not hold. Organisational composition is close to flat across
deciles — the share in organisations of 1,000+ runs 18–26% with no peak at 8, Kaiser runs
0.7–3.7%, and adding an organisation-size band to the standardization changes nothing (the
standardized series still runs 70.67 → 56.87, monotonic). **Specialty alone accounts for it.**

### Not a new finding

This is the same mechanism Phase A already documented for the *baseline* series, where the decile-9
uptick (12.01% → 13.73%) was attributed to the identical specialty shift. The adjusted definition
simply makes it larger and more visible, because the adjusted measure depends on relationship
reach, which is exactly where specialists and primary care differ most.

**Nothing here is unexplained, and nothing needs a caveat beyond the caption line now on Figure 3.**

---

## Verification

```
  PASS   MD/DO Part D prescribers               696647
  PASS   Never-engaged (baseline)               146459
  PASS   Never-engaged %                        21.02
  PASS   Selection-robust group                 553
  PASS   Selection-robust group $M              924
  PASS   Meal-only, 5-year %                    58.7
  PASS   Four-cell relationship-only            8715
  PASS   Four-cell relationship-only %          1.25
  PASS*  AMC median discriminant                published 1.110, got 1.109  (Δ0.0010 ≤ 0.002)
  PASS*  Kaiser median discriminant             published 0.727, got 0.726  (Δ0.0010 ≤ 0.002)

Total runtime: 12 seconds
RESULT: all headline figures reproduce.
```

All three PNGs regenerated. Every caption retains the "no *reported* payment" wording per
Phase V §V4. Nothing committed, nothing deleted.

**One file changed outside `figures/`:** `scripts/05_discriminant.sql` gained a
`figures/data/discriminant_states.csv` export for the new state markers, with the normalisation
caveat as a comment. No analysis in that script changed.

---

## For the writeup — a claim that must change

Phase X concluded that the discriminant separates *"partial restriction from near-total
exclusion"*, and I described the AMC result as validating the high end of the measure. **F1 shows
the AMCs are not at the high end.** They are at the centre, with near-normal meal reach.

The corrected statement is narrower and cleaner:

- **Kaiser is the finding.** Both channels suppressed, uniquely, and invariantly across seven
  states.
- **Gift-ban states are a separate finding** with a separate evidence base — meals suppressed,
  relationships relatively preserved.
- **The AMCs are the control that makes both interpretable.** Eighteen institutions with
  documented detailing restrictions look *ordinary* on this measure. That is what establishes
  that the measure is not detecting policy, paperwork, or academic status — it is detecting
  whether the commercial relationship still exists.

That is a more useful result than the one Phase X claimed, and it is better supported.

---

# Phase F — Addendum: three follow-up figure fixes

Layout and wording only. No re-analysis. All three PNGs regenerated;
`run_all.sh` still passes (8 exact, 2 within the documented ±0.002 tolerance, 12 seconds).

## 1. Figure 1 — the y = x annotation moved off the Kaiser diamonds

It sat at (0.335, 0.40) with a leader to the diagonal at (0.52, 0.52), which ran straight through
two Kaiser markers. Moved to **(1.35, 1.24)** with its leader redrawn to the diagonal at
**(1.44, 1.44)** — open space in the upper right, with no data between the label and the line it
points at. Split to two lines so it does not run past the right axis. Nothing else on the figure
changed.

## 2. Figure 2 — caption no longer implies a gradient

The previous caption named only the two extremes, which read as though relationship-only declined
smoothly across the ordering. It does not. Read off the existing panel:

| Block | Relationship-only |
|---|---|
| Gift-ban end (VT, MN, ME, WI, MA, WA) | 6.42, 3.63, 2.53, 3.46, 3.33, 2.22 |
| **Middle 40 states** | **0.41% to 2.83%, no clean ordering** |
| Low-restriction end (SC, GA, FL, AL, LA, MS) | 0.49, 0.71, 0.55, 0.55, 0.24, 0.15 |

The caption now states the shape explicitly — **high at the gift-ban end, low at the
low-restriction end, noisy in between** — and says the 43× is **a comparison of extremes, not a
gradient**. The Vermont-versus-Mississippi absolute-reach qualifier and the "no *reported*
payment" wording are both retained.

This is a wording fix, not a data change: the middle-state values were always visible in the top
panel, and the caption was the part overstating them.

## 3. Figure 3 — caption cut from five lines to three

Kept, as specified:

1. the true range — 71.5% down to 53.2% at decile 8, then rising: a 1.34× range, non-monotonic;
2. the cause — specialty composition, not a channel effect, with the pointer to §F4;
3. the "no *reported* payment" wording.

Moved into the module docstring: the baseline's 32.5 → 10.8 (3.0×) spread, the specialist-share
and primary-care-share numbers behind the decile-8 turn, the specialty-standardised series, the
fact that organisation type is ruled out, and the descriptive-only disclaimer. Caption font
nudged 8.2 → 8.4 now that there is room.

## Verification

```
  PASS   MD/DO Part D prescribers               696647
  PASS   Never-engaged (baseline)               146459
  PASS   Never-engaged %                        21.02
  PASS   Selection-robust group                 553
  PASS   Selection-robust group $M              924
  PASS   Meal-only, 5-year %                    58.7
  PASS   Four-cell relationship-only            8715
  PASS   Four-cell relationship-only %          1.25
  PASS*  AMC median discriminant                published 1.110, got 1.109  (Δ0.0010 ≤ 0.002)
  PASS*  Kaiser median discriminant             published 0.727, got 0.726  (Δ0.0010 ≤ 0.002)

Total runtime: 12 seconds
RESULT: all headline figures reproduce.
```

Only the three `figures/*.py` files changed. No SQL, no data, nothing committed, nothing deleted.

---

# Phase F — Addendum 2: figure 1 layout, and em dash removal

Layout and wording only. No re-analysis. All three PNGs regenerated; `run_all.sh` passes
(8 exact, 2 within the documented ±0.002 tolerance, 12 seconds).

## Figure 1 layout

**Annotations shortened to coordinate form.** `Rochester (0.53, 0.72)`,
`Boston University (0.72, 0.92)`, `Kaiser median (0.58, 0.44)`. All three round correctly from
the source CSVs (Rochester 0.5305/0.7172, BU 0.7181/0.9163, Kaiser medians 0.5772/0.4386). The
caption gained one line naming the format: *"Annotated values are (F&B ratio, non-F&B ratio)."*

**Backing boxes.** A single `BBOX` constant, matching the requested dict verbatim, is applied to
all **nine** text elements inside the axes: the three data annotations, the three state group
labels, the two quadrant labels, and the y = x label. Verified at render: `len(ax.texts) == 9`,
every one boxed. The figure caption, axis labels, title and legend sit outside the axes and do
not need it.

**Collisions fixed.** Two of the three data annotations were still clipping after the first pass,
so all three moved from pixel offsets to **data coordinates**, which places them against the
cloud and the diagonal exactly rather than by guesswork:

| Annotation | Position | Was |
|---|---|---|
| Rochester | (0.355, 0.630) | clipped through the left spine |
| Boston University | (0.395, 1.025) | a grey point sat on the "B" of non-F&B |
| Kaiser median | (0.800, 0.370) | clipped at the bottom axis |

No text now crosses the diagonal illegibly, no label is clipped, and the two leader lines still
run parallel rather than crossing.

## Em dash removal

**16 em dashes, all removed.** Zero U+2014 remain, confirmed at the byte level (a scan for the
UTF-8 sequence `e2 80 94` returns 0 in all three files), including escaped and entity forms.

Distribution and replacement, chosen per the four stated rules rather than by blanket
substitution:

| File | Location | Rule applied |
|---|---|---|
| fig1 | 2 docstring bullets | colon (setup before result) |
| fig1 | docstring, "not detecting X — it is detecting Y" | period, split |
| fig1 | docstring, normalisation warning | connective (see note below) |
| fig1 | code comment | colon |
| fig1 | caption, circularity aside | parentheses |
| fig2 | docstring, VT/MS contrast | colon |
| fig2 | caption ×2 | colon |
| fig3 | docstring, 3.0x spread | parentheses, then colon (see below) |
| fig3 | docstring, 1.34x range | period, split |
| fig3 | **2 legend labels** | colon |
| fig3 | caption ×2 | period split, then colon |

**Three items beyond the literal brief, disclosed rather than assumed:**

1. **Two fig3 legend labels** (`Adjusted — ...`, `Baseline — ...`) carried em dashes. They are
   rendered figure text, not captions or docstrings. Leaving em dashes in the legend while
   removing them from the caption directly below would have looked like an oversight, so both
   were converted. Say the word and I will revert.
2. **One fig1 code comment.** Zero visible effect; changed for internal consistency.
3. **fig1 docstring, one added connective.** `... state groups against the national baseline,
   **because** scoring a state against itself is circular.` That sentence already carries a colon
   earlier, so a second one would have doubled up, and a period split would have dropped the
   causal link. Adding *because* is the only word introduced anywhere in this pass.

**Not changed, deliberately:** the single en dash in fig2's title (`PY2021–2025`). It is a
numeric year range, which is the correct use of an en dash, and the brief was em dashes only.

## What the verification pass found

Five independent audits ran over the three scripts (em dash completeness, replacement quality,
fig1 layout requirements, scope creep, caption requirements), then a synthesis pass. Three
findings survived and were fixed:

1. **fig3 docstring line 13 — parentheses orphaned a trailing appositive.** The original dash was
   anchoring *two* things: the spread and the "the reading that..." gloss. Parenthesising only the
   spread left the gloss dangling off a bare comma. Changed to
   `10.8% (a 3.0x spread): the reading that industry engagement tracks prescribing volume.`
2. **Colon monotony in the fig3 caption.** All three sentences had ended up with exactly one colon
   each, which is the signature of one-for-one substitution. The middle one became a period split,
   which the user's own rules also permit: `not a channel effect. Standardising on specialty...`
3. **Same in the fig2 caption.** `Mississippi's (35.2%). Gift-ban states receive less...`

**Verified clean:** all 16 substitutions land on one of the four permitted replacements; no
numeric value, threshold, column, filter or computation changed anywhere, and every figure quoted
in the three scripts re-verifies against the regenerated CSVs; `no *reported* payment` with
asterisks is present in all three captions; every substantive qualifier survives (fig1's
normalisation warning, fig2's VT-below-MS caveat and its "comparison of extremes, not a gradient"
line, fig3's full range statement); all three captions render unclipped with no string-seam
collisions.

**Two audit findings I did not act on, and one the audit got wrong:**

- **Not acted on — fig2's "not a gradient" caveat sits inside a conditional.** It is built inside
  `if vt is not None and ms is not None:` while the hardcoded VT/MS sentence that follows is
  unconditional. If either state row ever went missing the caveat would vanish silently and the
  caption would reopen the gradient reading that Addendum 1 §2 exists to prevent. Real latent
  fragility, but fixing it is a code-structure change rather than a layout or em dash fix, so it
  is flagged here rather than done.
- **Not acted on — fig2's docstring** still frames VT versus MS as a bare extreme, without the
  "not a gradient" qualifier its own caption now carries. Adding it would be new wording.
- **Audit was wrong on one point.** One agent flagged running `run_all.sh` as violating "no
  re-analysis". You explicitly asked me to confirm it still passes, and the pipeline is
  deterministic since the NTILE tiebreaker, so the rebuilt CSVs are byte-identical in content.
  Not a violation. A second agent claimed a fig3 sentence had "an em dash deleted with no
  replacement"; the synthesis pass checked and refuted it.

Only the three `figures/*.py` files changed. No SQL, no data, nothing deleted, nothing committed.
