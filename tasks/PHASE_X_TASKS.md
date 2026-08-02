# Phase X — Blind Validation Against an External Labelled Set

**Read `PHASE_R_FINDINGS.md` and `PHASE_W_FINDINGS.md` first.** Final analysis. No new data.

---

## Why

The R2 channel discriminant was demonstrated on groups defined in advance — gift-ban states versus Kaiser. That shows two chosen groups differ; it does not show the measure identifies policy where it was not told the answer.

Larkin et al., *JAMA* 2017;317(17):1785–1795 provides an external labelled set built by other researchers for a different purpose: 19 academic medical centers that enacted pharmaceutical detailing restrictions between 2006 and 2012, coded across three policy areas.

**Structural facts about this set:**
- 17 of the 19 restricted salesperson **access to facilities**. Only Northwestern and Thomas Jefferson did not. Access restriction is near-universal here.
- 11 of 19 regulated gifts, access, **and** enforcement. The remaining 8 fell short on at least one.
- States: California, Illinois, Massachusetts, Pennsylvania, New York. Only Massachusetts overlaps the restriction-state group from R2 — so this is largely a test of organization independent of state.
- The authors note the study period ended in 2012 and that many AMCs adopted stricter measures afterward. Labels are therefore likely conservative.

---

## The labelled set

**All three policy areas (gift + access + enforcement), n = 11:**
UCLA · Boston University · University of Illinois Chicago · USC Keck · University of Pittsburgh · University of Rochester · University of Massachusetts · Rush Medical College · New York Medical College · SUNY Downstate · Tufts

**Fewer than three areas, n = 8:**
Stanford (no enforcement) · Northwestern (no access, no enforcement) · UC Davis (no enforcement) · UCSF (no enforcement) · Mount Sinai (no enforcement) · UC San Diego (no enforcement) · Temple (no enforcement) · Thomas Jefferson (no access, no enforcement)

---

## Tasks

### X1 — Match institutions to organizations

These are 2017 institution names; the DAC file has present-day organization names and `org_pac_id`. Match them.

- Fuzzy-match against `Facility Name` and organization names in the Phase W base table
- **Report every match with its matched name, `org_pac_id`, MD/DO prescriber count, and state, so Jacob can verify by hand.** Flag any that are ambiguous or unmatched.
- Some institutions will map to multiple organizations (a medical school, a health system, a faculty practice plan). Report all candidates rather than picking one silently.
- Exclude organizations with fewer than 50 MD/DO Part D prescribers from the scored analysis, but list them.

> Do not proceed to X2 until the match table is produced. If fewer than 10 of 19 match cleanly, say so — the test may not be runnable.

### X2 — Score them ⭐

For each matched organization, compute the **state-relative discriminant** exactly as defined in Phase W's W5 (scored against its own state's baseline, not the national one).

Report alongside:
- Kaiser entities (state-relative)
- The non-Kaiser 1,000+ reference group
- National baseline

### X3 — The test

**Primary:** where do the AMCs fall — the high range (>1, gift-ban-like: meal suppressed, relationship intact) or the Kaiser range (<1, contact-ban-like: both suppressed)?

**Secondary:** do the 11 "all three areas" AMCs score differently from the 8 that fell short? Direction and magnitude.

**Report all three possible outcomes honestly:**
- AMCs high, Kaiser low → the discriminant separates *restricted sales access* from *no commercial relationship*, validated blind against an external standard
- AMCs low, clustering with Kaiser → the discriminant is reading institution type or research intensity rather than policy mechanism
- AMCs scattered → the discriminant does not track documented policy, and R2's interpretation must be substantially weakened

A null or negative result here is as valuable as a positive one and must be reported flat, without softening.

### X4 — Limitations specific to this test

State explicitly:
- Policies date from 2006–2012; the data window is 2021–2025
- Institutional structures have changed materially over that period (mergers, faculty practice reorganizations)
- Matching is by name, not by a verified crosswalk, so misattribution is possible
- n = 19, and fewer after match failures — this is a directional check, not a calibration

---

## Rules

- Descriptive only. No models.
- Show your SQL and the full match table.
- Raw counts alongside percentages.
- Do not download, do not delete.
- **Do not tune the discriminant to make this test work.** It is defined in Phase W; use it as-is.

---

## Output

Write `PHASE_X_FINDINGS.md`.

Open with **Verdict**: which of the three X3 outcomes occurred, in one line.

Include the full X1 match table so Jacob can verify institution matching by hand.

Close with **What surprised me** and a short statement of what R2 can and cannot claim in light of this result.
