# Phase X — Blind Validation Against an External Labelled Set

Generated 2026-08-02. Final analysis. No new data. Descriptive only.
Assumes `PHASE_R_FINDINGS.md` and `PHASE_W_FINDINGS.md`.

The discriminant is used exactly as defined in Phase W's W5 — state-relative, research included
in the non-F&B axis. **It was not tuned for this test.**

---

## Verdict

**Outcome 1: the AMCs score high, Kaiser scores low, and the two sets do not overlap at all.**

| Group | n units | Median discriminant | Min | Max |
|---|---|---|---|---|
| **19 Larkin et al. AMCs (18 matched)** | 18 | **1.110** | **0.932** | 1.360 |
| **Kaiser / Permanente entities** | 8 | **0.727** | 0.557 | **0.794** |
| Non-Kaiser organizations 1,000+ | 183 | 1.040 | — | — |
| All other organizations ≥100 | 629 | 0.962 | — | — |

**Every one of the 18 matched AMCs scores above every one of the 8 Kaiser entities.** The gap
between the lowest AMC (0.932) and the highest Kaiser entity (0.794) is 0.138, with 26 units and
zero overlap. The separation survives dropping research from the measure entirely (AMC min 0.888
vs Kaiser max 0.795), dropping the one ambiguous match, and restricting to institutions with
≥500 prescribers.

**This is a genuine blind validation.** The labels come from an external research team, built for
a different purpose, on institutions the measure was never shown. The measure assigns them
correctly and unanimously.

### But it validates something narrower than it first appears — read this before using it

**17 of the 19 AMCs restricted salesperson access to facilities, yet they land at 1.110 — in the
gift-ban range, not the Kaiser range.** If the discriminant simply detected "this institution has
an access-restriction policy," these institutions should have scored below 1. They do not.

Sharper still: **the two AMCs that did *not* restrict access — Northwestern (1.067) and Thomas
Jefferson (1.157) — sit squarely inside the distribution of the seventeen that did.**

So the discriminant is **not** reading the presence of a written access policy. It is reading
**how completely industry contact is actually eliminated**, and those are different things. An
academic detailing policy — credentialing, appointment-only, no unaccompanied reps — suppresses
meals modestly (ratio 0.919) while leaving consulting, speaking and research relationships fully
intact (1.024). Kaiser's closed-panel model suppresses both (0.577 and 0.439).

**What is validated: the discriminant reliably separates partial restriction from
near-total exclusion, against externally assigned labels.** What is *not* validated: that it
detects documented policy adoption, or that it can grade policy strength — see the secondary
result below.

---

## X1 — Match table

Institution names are from Larkin et al. (2017); organization names and `org_pac_id` are
present-day DAC. **Matched by name, then disambiguated by DAC practice city where the name was
generic.** Organizations under 50 MD/DO Part D prescribers are listed but excluded from scoring.

**Please verify these by hand — particularly the flagged rows.**

### All three policy areas (gift + access + enforcement), n = 11

| Institution | Matched organization | `org_pac_id` | MD/DO | State | Basis | Flag |
|---|---|---|---|---|---|---|
| **UCLA** | THE REGENTS OF THE UNIVERSITY OF CALIFORNIA | 1355248584 | 1,179 | CA | City: Los Angeles (3,847), Santa Monica (1,777) | inferred by city |
| | THE REGENTS OF THE UNIVERSITY OF CALIFORNIA | 1456255959 | 75 | CA | City: Los Angeles (479) | inferred by city |
| | UC REGENTS | 0749180453 | 65 | CA | City: Los Angeles (228) | inferred by city |
| | REGENTS OF THE UNIVERSITY OF CALIFORNIA LOS ANGELES | 4587857727 | 50 | CA | Name explicit | — |
| **Boston University** | EVANS MEDICAL FOUNDATION INC | 7416946546 | 332 | MA | BU's faculty practice plan | ⚠ name does not contain "Boston University" |
| | BOSTON MEDICAL CENTER CORPORATION | 0547222051 | 8 | MA | — | below threshold |
| **Univ Illinois Chicago** | THE BOARD OF TRUSTEES OF THE UNIVERSITY OF ILLINOIS | 3072422716 | 515 | IL | Name | — |
| **USC Keck** | USC CARE MEDICAL GROUP INC | 0446157747 | 543 | CA | Name | — |
| **Univ Pittsburgh** | UNIVERSITY OF PITTSBURGH PHYSICIANS | 8729990239 | 1,445 | PA | Name | — |
| **Univ Rochester** | UNIVERSITY OF ROCHESTER | 5799699088 | 401 | NY | Name | — |
| **Univ Massachusetts** | UMASS MEMORIAL MEDICAL GROUP INC | 4284539891 | 1,042 | MA | Name | — |
| **Rush Medical College** | RUSH UNIVERSITY MEDICAL GROUP | 5496658874 | 740 | IL | Name | — |
| | RUSH-COPLEY MEDICAL GROUP NFP | 7618864877 | 28 | IL | — | below threshold |
| **New York Medical College** | WESTCHESTER MEDICAL CENTER ADVANCED PHYSICIAN SERVICES PC | 3173660776 | 343 | NY | NYMC's principal teaching hospital | ⚠⚠ **ambiguous — this is the affiliated hospital, not the college** |
| **SUNY Downstate** | UNIVERSITY PHYSICIANS OF BROOKLYN, INC. | 0749192284 | 80 | NY | Name | — |
| | UNIVERSITY HOSPITAL OF BROOKLYN SUNY DOWNSTATE HEALTH SCIENCES UNIV | 7113318122 | 55 | NY | Name | — |
| **Tufts** | CARDIOVASCULAR CENTER AT TUFTS MEDICAL CENTER INC | 3870857816 | 33 | MA | — | ❌ **below threshold** |
| | TUFTS MEDICAL CENTER COMMUNITY CARE INC | 4981915659 | 9 | MA | — | below threshold |
| | TUFTS MEDICAL CENTER EP LLC | 0446306716 | 7 | MA | — | below threshold |

### Fewer than three policy areas, n = 8

| Institution | Matched organization | `org_pac_id` | MD/DO | State | Basis | Flag |
|---|---|---|---|---|---|---|
| **Stanford** (no enforcement) | STANFORD HEALTH CARE | 6709797491 | 1,324 | CA | Name | — |
| **Northwestern** (no access, no enforcement) | NORTHWESTERN MEDICAL FACULTY FOUNDATION | 4587576814 | 1,814 | IL | Name | — |
| **UC Davis** (no enforcement) | REGENTS OF THE UNIV OF CA | 3375456619 | 668 | CA | City: Sacramento (2,956) | inferred by city |
| | REGENTS OF THE UNIVERSITY OF CALIFORNIA | 8022922475 | 176 | CA | City: Sacramento (463) | inferred by city |
| **UCSF** (no enforcement) | UNIVERSITY OF CALIFORNIA SAN FRANCISCO | 4486567229 | 687 | CA | Name | — |
| | UNIVERSITY OF CALIFORNIA SFGH MEDICAL GROUP | 5496668410 | 214 | CA | Name (SF General) | — |
| | REGENTS OF THE UNIVERSITY OF CALIFORNIA | 4284547274 | 172 | CA | City: San Francisco (917) | inferred by city |
| | REGENTS UNIV OF CALIFORNIA UCSF | 6305160300 | 153 | CA | Name explicit | — |
| **Mount Sinai** (no enforcement) | ICAHN SCHOOL OF MEDICINE AT MOUNT SINAI | 2264691070 | 1,712 | NY | Name | — |
| | ICAHN SCHOOL OF MEDICINE AT MOUNT SINAI | 8224282926 | 137 | NY | Name | — |
| **UC San Diego** (no enforcement) | REGENTS OF THE UNIVERSITY OF CALIFORNIA | 3577476761 | 948 | CA | City: San Diego (2,744), La Jolla (1,722) | inferred by city |
| | UC SAN DIEGO HEALTH COMMUNITY GROUP | 3971849175 | 55 | CA | Name explicit | — |
| **Temple** (no enforcement) | TEMPLE FACULTY PRACTICE PLAN INC | 0345588711 | 680 | PA | Name | — |
| | TEMPLE PHYSICIANS INC | 2062317233 | 92 | PA | Name | — |
| **Thomas Jefferson** (no access, no enforcement) | JEFFERSON UNIVERSITY PHYSICIANS | 7911819180 | 609 | PA | Name | — |

### Match summary

| | n |
|---|---|
| Institutions in the labelled set | 19 |
| **Matched to ≥1 organization with ≥50 MD/DO prescribers** | **18** |
| Unmatched (no organization above threshold) | 1 — **Tufts** |
| Flagged ambiguous | 1 — **New York Medical College** |
| Organizations scored | 29 |
| Physicians covered | 16,306 |

**18 of 19 matched, well above the task's 10-institution floor. The test is runnable.**

Two UC campuses in the labelled set (UCLA, UC Davis) and parts of UCSF/UCSD are identified only
by DAC practice city, because several `org_pac_id`s carry the undifferentiated name "Regents of
the University of California." The city evidence is unambiguous (Los Angeles/Santa Monica;
Sacramento; San Francisco; San Diego/La Jolla) but it is inference, not a verified crosswalk.
**UC Irvine organizations (Orange, CA) were identified and correctly excluded** — Irvine is not
in the labelled set.

---

## X2 — Scores

State-relative discriminant, per organization:

```sql
CREATE TEMP TABLE crS AS
SELECT coalesce(partd_specialty,'?') sp, clms_decile vd, coalesce(partd_state,'?') st,
  avg((n_fnb5>0)::INT) p_fnb, avg((n_nonfnb5>0 OR has_research)::INT) p_non
FROM 'work/phase_w_base.parquet' GROUP BY 1,2,3;

SELECT (avg(any_non::INT)/avg(crS.p_non)) / (avg((n_fnb5>0)::INT)/avg(crS.p_fnb)) AS discriminant
FROM k JOIN crS USING (sp,vd,st) JOIN amc ON k.org_primary=amc.org GROUP BY inst;
```

### Institution level (organizations pooled)

| Institution | Policy | MD/DO | State | F&B ratio | non-F&B ratio | **Discriminant** |
|---|---|---|---|---|---|---|
| Stanford | fewer | 1,324 | CA | 0.903 | 1.228 | **1.360** |
| Univ Rochester | all three | 401 | NY | 0.530 | 0.717 | **1.352** |
| UCSF | fewer | 1,226 | CA | 0.793 | 1.023 | **1.291** |
| Boston University | all three | 332 | MA | 0.718 | 0.917 | **1.277** |
| UC San Diego | fewer | 1,003 | CA | 1.027 | 1.238 | 1.206 |
| UC Davis | fewer | 844 | CA | 0.908 | 1.067 | 1.175 |
| Univ Illinois Chicago | all three | 515 | IL | 0.904 | 1.052 | 1.164 |
| Thomas Jefferson | fewer | 609 | PA | 1.038 | 1.201 | 1.157 |
| Rush | all three | 740 | IL | 0.916 | 1.024 | 1.118 |
| UCLA | all three | 1,369 | CA | 0.916 | 1.009 | 1.103 |
| USC Keck | all three | 543 | CA | 1.125 | 1.232 | 1.095 |
| Univ Pittsburgh | all three | 1,445 | PA | 0.904 | 0.980 | 1.084 |
| Northwestern | fewer | 1,814 | IL | 0.926 | 0.987 | 1.067 |
| Mount Sinai | fewer | 1,849 | NY | 0.956 | 1.017 | 1.064 |
| Temple | fewer | 772 | PA | 0.941 | 0.962 | 1.023 |
| New York Medical College ⚠ | all three | 343 | NY | 1.118 | 1.096 | 0.980 |
| Univ Massachusetts | all three | 1,042 | MA | 0.921 | 0.878 | 0.953 |
| SUNY Downstate | all three | 135 | NY | 1.159 | 1.080 | 0.932 |

### Against the reference groups

| Group | n | Median F&B ratio | Median non-F&B ratio | **Median discriminant** | Range |
|---|---|---|---|---|---|
| **18 AMCs** | 18 | **0.919** | **1.024** | **1.110** | 0.932 – 1.360 |
| **Kaiser entities** | 8 | **0.577** | **0.439** | **0.727** | 0.557 – 0.794 |
| Non-Kaiser org 1,000+ | 183 | — | — | 1.040 | — |
| All other orgs ≥100 | 629 | — | — | 0.962 | — |
| National baseline | — | 1.000 | 1.000 | 1.000 | — |

**The AMC and Kaiser profiles differ on both axes, not just the ratio.** AMCs suppress meals by
8% and preserve relationships at 102% of expectation. Kaiser suppresses meals by 42% and
relationships by 56%.

---

## X3 — The test

### Primary — where do the AMCs fall?

**High, unanimously.** Median 1.110 against Kaiser's 0.727, with complete separation:

| | AMC min | Kaiser max | Gap |
|---|---|---|---|
| With research (headline) | 0.932 | 0.794 | 0.138 |
| **Without research** | **0.888** | **0.795** | **0.093** |

**Robustness:**

| Variant | n | Median | Min | Max |
|---|---|---|---|---|
| All 18 AMCs | 18 | 1.110 | 0.932 | 1.360 |
| Excluding ambiguous NYMC | 17 | 1.118 | 0.932 | 1.360 |
| Only institutions ≥500 prescribers | 14 | 1.110 | 0.953 | 1.360 |
| **Research removed from the measure** | 18 | **1.096** | **0.888** | 1.322 |

**Research is not producing the split.** Phase W's preamble raised exactly this concern —
*"excluding research may be producing the academic-versus-staff-model split rather than revealing
it"* — and the inverse is now testable: *including* research is not producing it either. Dropping
research moves the AMC median by 0.014 and preserves complete separation from Kaiser. Three AMCs
slip just below 1.0 (SUNY Downstate 0.888, UMass 0.936, Temple 0.977) but all remain above every
Kaiser entity.

**This is outcome 1 as the task defined it**, with the narrowing set out in the Verdict: the
discriminant separates partial restriction from near-total exclusion, validated blind. It does
not detect the presence of a written access policy.

### Secondary — do the 11 "all three areas" AMCs differ from the 8 that fell short?

**No. If anything the direction is mildly backwards, and it is not interpretable at this n.**

| Group | n institutions | n physicians | Median | Min | Max | Above 1.0 |
|---|---|---|---|---|---|---|
| **All three policy areas** | 10 | 6,865 | **1.099** | 0.932 | 1.352 | 7 of 10 |
| **Fewer than three** | 8 | 9,441 | **1.166** | 1.023 | 1.360 | 8 of 8 |

(10 rather than 11 in the stricter group because Tufts did not match.)

The institutions with gift, access **and** enforcement policies score **0.067 lower** than those
missing at least one — the opposite of a dose-response relationship, at a magnitude far below
the within-group spread (0.932–1.352). The three lowest-scoring AMCs are all from the "all three"
group; the highest-scoring institution overall (Stanford, 1.360) is from the "fewer" group.

**Reported flat, as required: this measure does not grade policy strength.** It distinguishes
regimes, not degrees within a regime. Anyone hoping to use it to rank institutions by how
seriously they enforce a policy should not.

Two structural reasons this was always a weak test, both noted in the task: 17 of 19 restricted
access, so the groups differ mainly on *enforcement* and *gifts* rather than on the axis the
discriminant reads; and the labels stop in 2012, by which point the two groups may well have
converged.

---

## X4 — Limitations specific to this test

- **Policies date from 2006–2012; the data window is PY2021–2025** — a 9-to-19-year gap. Larkin
  et al. themselves note many AMCs adopted stricter measures after the study period, so the
  labels are conservative and the two policy groups have probably converged. This is the most
  likely explanation for the null secondary result and cannot be distinguished from a genuine
  absence of a dose-response.
- **Institutional structures have changed materially.** Faculty practice plans have merged and
  reorganised; UMass Memorial, Mass General Brigham and the UC health systems in particular look
  structurally different today than in 2012. An `org_pac_id` in 2026 is not the same legal or
  operational entity that adopted a policy in 2009.
- **Matching is by name and city, not a verified crosswalk.** Misattribution is possible. Four
  institutions are identified only by DAC practice city. New York Medical College is matched to
  its principal teaching hospital rather than the college and is flagged throughout; dropping it
  strengthens the result slightly.
- **n = 19, of which 18 matched.** This is a directional check, not a calibration. No threshold,
  cut point, or classifier is proposed.
- **Only Massachusetts overlaps the R2 restriction-state group**, which is what makes this
  largely a test of organization independent of state — the intended design — but it also means
  four of the five states here (CA, IL, PA, NY) contribute no state-level restriction signal.
- **The comparison group is one organization family.** Kaiser remains a single point of
  reference, however many entities it spans. A second, independently documented near-total
  exclusion system would test the low end properly; none was available.
- **No policy inventory was constructed** and no legal classification is applied anywhere in this
  project.

---

## What surprised me

**1. Complete separation with 26 units and no overlap.** I expected the AMCs to sit above Kaiser
on average with several exceptions. Eighteen out of eighteen above eight out of eight, with a
0.138 gap and no tuning, is a stronger result than the sample size deserves. The honest reading
is that two genuinely different regimes exist and this measure finds the boundary — not that the
measure is precise.

**2. Access restriction turned out not to be the thing being measured.** Seventeen of nineteen
AMCs restricted salesperson access, and they land in the *gift-ban* range. The two without access
restrictions — Northwestern and Thomas Jefferson — are indistinguishable from the rest. **I had
been treating "contact ban" and "access restriction" as the same construct since Phase R; this
test shows they are not.** An academic credentialing policy and a closed-panel HMO produce
different signatures, and only the latter reads as contact suppression. That reframes what R2's
Kaiser finding is evidence *of*.

**3. The stricter-policy group scored slightly lower.** I expected either a positive
dose-response or nothing. Getting a small negative one (1.099 vs 1.166) is a useful corrective
against reading the discriminant as a policy-strength meter. With n = 10 and 8 it is noise, but
it is noise pointing the wrong way, which is worth more than noise pointing the right way.

**4. Rochester and Boston University suppress meals as hard as Kaiser and still score high.**
University of Rochester's F&B ratio is 0.530 and BU's 0.718 — comparable to Kaiser's 0.577. But
their non-F&B ratios are 0.717 and 0.917 against Kaiser's 0.439. **The discriminant is doing real
work here**: three institutions with near-identical meal suppression are correctly separated by
what happens to the rest of the relationship. That is the clearest single demonstration in the
project that the two-axis design was the right one.

**5. Tufts simply is not in the data at scale.** Three Tufts organizations totalling 49 MD/DO
Part D prescribers, against 1,814 for Northwestern. A major Boston academic medical center is
effectively invisible in DAC's organizational structure — presumably because its physicians
reassign benefits through entities that do not carry the Tufts name. A reminder that
`org_pac_id` is a billing construct, not an institutional one, and that absence from an
organization roster is not absence from medicine.

---

## What R2 can and cannot claim in light of this result

**Can claim:**

- The two-axis channel signature distinguishes **partial restriction** (meals suppressed,
  professional relationships intact) from **near-total exclusion** (both suppressed), and does so
  correctly on 18 externally labelled institutions it was never shown, with complete separation
  from the Kaiser reference and no tuning.
- The distinction is **not** an artifact of research payments, institution type, state, specialty
  or prescribing volume — each of those is either controlled in the measure or tested here.
- **Kaiser's signature is genuinely unusual.** It is not what a restrictive academic medical
  center looks like; 18 restrictive AMCs look like something else entirely.

**Cannot claim:**

- That the discriminant **detects documented policy**. It does not: 17 of 19 institutions with
  access-restriction policies score in the non-restricted range, and the two without such
  policies are indistinguishable from those with.
- That it **grades policy strength**. The stricter group scored marginally lower.
- That it works at the **level of an individual physician or a single organization**. Every
  result here is a group median over hundreds to thousands of physicians.
- That the low end is **generally validated**. It rests on one organization family. The AMC
  result validates the high end against 18 independent units; there is no equivalent evidence for
  the low end.

**The recommended framing for the writeup**: the channel signature identifies a real and
externally verifiable distinction in how completely industry contact is eliminated, demonstrated
blind. It is a group-level descriptive instrument, not a policy detector, and its low end is
anchored by a single institution family.

---

## Files

No new data files. Nothing downloaded, nothing deleted. All analysis reads
`work/phase_w_base.parquet` and `work/dac_national.parquet`.
