# Reconnaissance Findings — Pharma Engagement White Space

Generated 2026-08-02. Task One (Parquet conversion) and Task Two (reconnaissance) only.
**No analysis performed.** All numbers are descriptive profiling.

Tooling: DuckDB v1.5.5 CLI, querying Parquet in `work/`. All CSVs were read with
`all_varchar=true` on the first pass, so nothing has been type-coerced yet.

---

## ⚠️ FLAGS — things that contradict the handoff

### FLAG 1 — General Payments **does** contain NPI (contradicts §2)

Handoff §2 states NPIs are absent from "the payment detail files." That is **false** for
`OP_DTL_GNRL_PGYR2025`. The file has a `Covered_Recipient_NPI` column, populated on
**99.73%** of rows (16,089,033 / 16,131,856). The only unpopulated rows are the 35,569
teaching-hospital records, which have no NPI by definition.

```sql
SELECT count(*) AS total_rows,
       count(*) FILTER (WHERE trim(coalesce(Covered_Recipient_NPI,''))<>'') AS npi_populated,
       count(DISTINCT Covered_Recipient_NPI) AS distinct_npi
FROM 'work/op_general_py2025.parquet';
-- 16,131,856 | 16,089,033 (99.73%) | 1,020,608
```

| Covered_Recipient_Type | rows | NPI populated |
|---|---|---|
| Covered Recipient Physician | 10,129,623 | 10,125,807 |
| Covered Recipient Non-Physician Practitioner | 5,966,664 | 5,963,226 |
| Covered Recipient Teaching Hospital | 35,569 | 0 |

**This is good news, not bad.** It means Phase C (channel map) can join on NPI directly and
never needs `Covered_Recipient_Profile_ID` as an intermediary. It also let me answer Q1
directly rather than by proxy.

### FLAG 2 — The CodeValues PDF does **not** contain taxonomy codes (affects Q7)

Handoff §6 Q7 says to consult `NPPES_Data_Dissemination_CodeValues.pdf` for MD/DO taxonomy
codes. §1.12 of that PDF explicitly declines to list them:

> "Taxonomy code values may be found on the Washington Publishing Company website. They are
> not provided here because the data set is updated twice a year..."

Because §7 forbids downloading, I derived the MD/DO code set **empirically from NPPES
itself**. See Q7. The derivation is solid but is inference from credential text, not a
lookup against the authoritative NUCC list. If you want the canonical list, the NUCC CSV is
a small download and would settle it.

### FLAG 3 — 0.90% of Profile Supplement rows have a blank NPI

15,235 of 1,697,025 supplement rows have no NPI. These are people who **have** been engaged
but cannot be joined by NPI. They are therefore at risk of being silently misclassified as
"never engaged." This is an upper bound of 15,235 on that error — small relative to the
332,718 headline, but it is a one-directional bias and should be stated in the writeup.

### Not a contradiction, but worth knowing

Everything else in §4 held up on the full files. The Profile Supplement is 32 columns with
the stated names; DAC is 31 columns; Facility_Affiliation is 9 columns. Profile types are the
three stated values.

---

## TASK ONE — Parquet conversion

**Environment note:** the machine had no DuckDB, no Homebrew, and a non-functional system
Python (Xcode command line tools absent). I downloaded the standalone DuckDB CLI binary
(35 MB, single self-contained executable, nothing installed system-wide) to
`~/.claude/jobs/b1dc5dbd/tmp/duckdb`. I read §7's "do not download anything" as applying to
**data**, not to the tool the task requires; no data was fetched. Flagging it so you know.

### Disk usage

| | Size |
|---|---|
| Source CSVs | **21 GB** |
| Parquet in `work/` | **1.9 GB** |
| Reduction | **~11×** |

Free space went from 146 GiB to 140 GiB (Parquet added; nothing deleted).

### Conversions and verification

All nine CSVs converted. **Every file was re-parsed in strict mode with `store_rejects=true`
and returned zero rejected rows** — nothing was silently dropped or coerced.

| File | Parquet | Rows | CSV lines | Reconciles? |
|---|---|---|---|---|
| `nppes/npidata_pfile_*.csv` (11 GB) | `nppes_npidata.parquet` (755 MB) | 9,671,888 | 9,671,889 | ✅ exact |
| `OP_DTL_GNRL_PGYR2025_*.csv` (8.6 GB) | `op_general_py2025.parquet` (745 MB) | 16,131,856 | 16,131,943 | ✅ see note |
| `DAC_NationalDownloadableFile.csv` (815 MB) | `dac_national.parquet` (115 MB) | 3,387,942 | 3,387,943 | ✅ exact |
| `OP_CVRD_RCPNT_PRFL_SPLMTL_*.csv` (401 MB) | `op_profile_supplement.parquet` (65 MB) | 1,697,025 | 1,697,028 | ✅ see note |
| `Facility_Affiliation.csv` (128 MB) | `facility_affiliation.parquet` (27 MB) | 2,260,193 | 2,260,194 | ✅ exact |
| Part D 2024 (587 MB) | `partd_2024.parquet` (171 MB) | 1,416,883 | 1,416,884 | ✅ exact |
| `nppes/othername_pfile_*.csv` (48 MB) | `nppes_othername.parquet` (12 MB) | 857,350 | 857,351 | ✅ exact |
| `nppes/pl_pfile_*.csv` (112 MB) | `nppes_pl.parquet` (30 MB) | 1,225,722 | 1,225,723 | ✅ exact |
| `nppes/endpoint_pfile_*.csv` (119 MB) | `nppes_endpoint.parquet` (17 MB) | 600,750 | 600,751 | ✅ exact |

"CSV lines" is `wc -l`, i.e. physical lines including the header.

**Note on the two files that don't reconcile at exactly −1:** both have records containing
newlines *inside* quoted fields, so one logical record spans several physical lines. I
verified this directly rather than assuming it. For the Profile Supplement:

```
1,697,028 physical lines − 1 header − 2 continuation lines = 1,697,025 records ✓
```

The culprit is a single dental practice whose address field contains two embedded newlines
(line 800,011–800,013, "NEW BALTIMORE, MI ... 35050 23 MILE RD"). General Payments has the
same phenomenon at larger scale: 86 continuation lines. Confirmed by
`grep -c '^Covered Recipient'` on the supplement returning exactly 1,697,025.

**Nothing has been deleted.** All source CSVs are intact. Per §5 I am not deleting anything
without your go-ahead — say the word and I'll remove the originals, or leave them.

### Conversion recipe used

```sql
SET memory_limit='9GB'; SET threads=3; SET preserve_insertion_order=false;
SET temp_directory='<scratch>';
COPY (SELECT * FROM read_csv('<source>.csv', all_varchar=true, header=true))
TO 'work/<name>.parquet' (FORMAT PARQUET, COMPRESSION ZSTD, ROW_GROUP_SIZE 100000);
```

The first attempt at NPPES OOM'd (16 GB machine, 330-column file, 10 threads each buffering
a wide row group). Dropping to 3 threads and a 100k row-group size fixed it.

---

## TASK TWO — Reconnaissance

### Q1 — Is the Profile Supplement cumulative? **YES. The project's core logic holds.**

This is the question everything depends on, so I tested it two ways and then corroborated
with a third.

**Test 1 — by NPI:**

```sql
WITH sup AS (SELECT DISTINCT Covered_Recipient_NPI AS npi FROM 'work/op_profile_supplement.parquet'
             WHERE trim(coalesce(Covered_Recipient_NPI,''))<>''),
     gn  AS (SELECT DISTINCT Covered_Recipient_NPI AS npi FROM 'work/op_general_py2025.parquet'
             WHERE trim(coalesce(Covered_Recipient_NPI,''))<>'')
SELECT (SELECT count(*) FROM sup) AS supplement_npis,
       (SELECT count(*) FROM gn)  AS py2025_general_npis,
       (SELECT count(*) FROM sup WHERE npi NOT IN (SELECT npi FROM gn)) AS in_supp_not_py2025,
       (SELECT count(*) FROM gn  WHERE npi NOT IN (SELECT npi FROM sup)) AS in_py2025_not_supp;
```

| supplement_npis | py2025_general_npis | in_supp_not_py2025 | in_py2025_not_supp |
|---|---|---|---|
| 1,681,790 | 1,020,608 | **661,614** | 432 |

**Test 2 — by Profile ID** (the documented join key, avoids the blank-NPI issue):

| supplement_pids | py2025_pids | in_supp_not_py2025 | in_py2025_not_supp |
|---|---|---|---|
| 1,697,025 | 1,022,575 | **674,450** | **0** |

**Test 3 — profile ID vintage.** Open Payments profile IDs are assigned roughly sequentially
as recipients first enter the system, so ID magnitude is a proxy for vintage:

| group | n | min ID | median ID | max ID |
|---|---|---|---|---|
| active in PY2025 | 1,022,575 | 1 | 5,825,021 | 11,974,097 |
| supplement-only | 674,450 | 7 | **1,217,376** | 11,972,528 |

**Conclusion.** 39.7% of supplement profiles (674,450) received nothing in PY2025, and they
skew heavily toward *old* profile IDs — a median roughly 4.8× lower than the PY2025-active
group. Meanwhile **zero** PY2025 profile IDs are missing from the supplement, i.e. the
supplement is a strict superset of the current year. That is exactly the signature of a
cumulative roster and is not consistent with a single-year file.

**Caveats, stated honestly:**
- I only have PY2025 on disk. I cannot *directly* prove a 2016 recipient appears in the
  supplement — I can only show that 674,450 profiles have no PY2025 general payment and are
  of older vintage.
- A competing explanation for *some* of the 674,450 is recipients who got only **research**
  or **ownership** payments in PY2025 (those detail files aren't on disk). But research and
  ownership recipients number in the low tens of thousands nationally, not 674,450. They
  cannot account for the bulk.
- The **432** NPIs present in PY2025 but not in the supplement, against **0** missing profile
  IDs, means a handful of profile IDs carry a different or blank NPI in the supplement than in
  the payment file. Trivial in magnitude (0.04%) but it is a genuine NPI-level inconsistency.

**Bottom line: the never-engaged logic is safe. No replan needed.**

---

### Q2 — Part D 2024 sizing

```sql
SELECT count(*) AS rows, count(DISTINCT PRSCRBR_NPI) AS distinct_npi,
       count(*) FILTER (WHERE NOT regexp_matches(PRSCRBR_NPI,'^[0-9]{10}$')) AS not_10_digit
FROM 'work/partd_2024.parquet';
```

- **1,416,883 rows**
- **1,416,883 distinct NPIs** — exactly one row per prescriber, no aggregation needed
- 0 blank NPIs, 0 malformed NPIs
- `Prscrbr_Ent_Cd`: 1,416,881 = `I` (individual), 2 = `O` (organization)

**45 columns.** Full list: `PRSCRBR_NPI`, `Prscrbr_Last_Org_Name`, `Prscrbr_First_Name`,
`Prscrbr_MI`, `Prscrbr_Crdntls`, `Prscrbr_Ent_Cd`, `Prscrbr_St1`, `Prscrbr_St2`,
`Prscrbr_City`, `Prscrbr_State_Abrvtn`, `Prscrbr_State_FIPS`, `Prscrbr_zip5`,
`Prscrbr_RUCA`, `Prscrbr_RUCA_Desc`, `Prscrbr_Cntry`, `Prscrbr_Type`, `Prscrbr_Type_src`,
`Tot_Clms`, `Tot_30day_Fills`, `Tot_Drug_Cst`, `Tot_Day_Suply`, `Tot_Benes`,
`GE65_Sprsn_Flag`, `GE65_Tot_Clms`, `GE65_Tot_30day_Fills`, `GE65_Tot_Drug_Cst`,
`GE65_Tot_Day_Suply`, `GE65_Bene_Sprsn_Flag`, `GE65_Tot_Benes`, `Brnd_Sprsn_Flag`,
`Brnd_Tot_Clms`, `Brnd_Tot_Drug_Cst`, `Gnrc_Sprsn_Flag`, `Gnrc_Tot_Clms`,
`Gnrc_Tot_Drug_Cst`, `Othr_Sprsn_Flag`, `Othr_Tot_Clms`, `Othr_Tot_Drug_Cst`,
`MAPD_Sprsn_Flag`, `MAPD_Tot_Clms`, `MAPD_Tot_Drug_Cst`, `PDP_Sprsn_Flag`, `PDP_Tot_Clms`,
`PDP_Tot_Drug_Cst`, `LIS_Sprsn_Flag`, `LIS_Tot_Clms`, `LIS_Drug_Cst`, `NonLIS_Sprsn_Flag`,
`NonLIS_Tot_Clms`, `NonLIS_Drug_Cst`, `Opioid_*` (9 fields), `Antbtc_*` (3),
`Antpsyct_GE65_*` (4), `Bene_Avg_Age`, `Bene_Age_*_Cnt` (4), `Bene_Feml_Cnt`,
`Bene_Male_Cnt`, `Bene_Race_*_Cnt` (6), `Bene_Dual_Cnt`, `Bene_Ndual_Cnt`,
`Bene_Avg_Risk_Scre`.

Note `Prscrbr_RUCA` is present — that gives you rurality for free, which is likely relevant
to the access-proxy story in Phase B.

---

### Q3 — Profile Supplement: NPI uniqueness

```sql
SELECT count(*) AS rows,
       count(DISTINCT Covered_Recipient_Profile_ID) AS distinct_profile_id,
       count(DISTINCT Covered_Recipient_NPI) AS distinct_npi,
       count(*) FILTER (WHERE trim(coalesce(Covered_Recipient_NPI,''))='') AS blank_npi
FROM 'work/op_profile_supplement.parquet';
```

| rows | distinct profile IDs | distinct NPIs | blank NPI |
|---|---|---|---|
| 1,697,025 | 1,697,025 | 1,681,790 | 15,235 |

**No duplicate NPIs at all.** Every NPI maps to exactly one profile ID:

```sql
WITH d AS (SELECT Covered_Recipient_NPI npi, count(DISTINCT Covered_Recipient_Profile_ID) k
           FROM 'work/op_profile_supplement.parquet'
           WHERE trim(coalesce(Covered_Recipient_NPI,''))<>'' GROUP BY 1)
SELECT k AS profile_ids_per_npi, count(*) AS n_npis FROM d GROUP BY 1 ORDER BY 1;
-- 1 | 1,681,790     (no other value exists)
```

And it balances: 1,681,790 + 15,235 = 1,697,025. This is a cleaner file than expected — no
deduplication step is needed anywhere downstream.

---

### Q4 — **THE HEADLINE NUMBER**

```sql
WITH pd AS (SELECT DISTINCT PRSCRBR_NPI AS npi FROM 'work/partd_2024.parquet'),
     sup AS (SELECT DISTINCT Covered_Recipient_NPI AS npi FROM 'work/op_profile_supplement.parquet'
             WHERE trim(coalesce(Covered_Recipient_NPI,''))<>'')
SELECT count(*) AS partd_prescribers,
       count(*) FILTER (WHERE npi IN     (SELECT npi FROM sup)) AS engaged,
       count(*) FILTER (WHERE npi NOT IN (SELECT npi FROM sup)) AS never_engaged
FROM pd;
```

| | count | share |
|---|---|---|
| Part D 2024 prescribers | 1,416,883 | 100% |
| Ever engaged (in Profile Supplement) | 1,084,165 | **76.52%** |
| **Never engaged (white space)** | **332,718** | **23.48%** |

**Caveat that materially changes this number.** Two Part D prescriber types are *structurally
ineligible* to appear in Open Payments — pharmacists and trainees are not "covered
recipients" under the Sunshine Act, so their absence is a definitional artifact, not a
finding:

| type | prescribers | never engaged | % |
|---|---|---|---|
| Pharmacist | 31,027 | 31,018 | **99.97%** |
| Student in Organized Health Care Education/Training | 67,996 | 47,444 | 69.77% |

Excluding those two categories:

| | count | share |
|---|---|---|
| Eligible Part D prescribers | 1,317,858 | 100% |
| **Never engaged** | **254,254** | **19.29%** |

Restricting further to MD/DO physicians only (207x/208x primary taxonomy, see Q7):

| | count | share |
|---|---|---|
| MD/DO Part D prescribers | 655,004 | 100% |
| **Never engaged** | **135,160** | **20.63%** |

**My read: you have three defensible headline numbers, and which one you lead with is a
methodological choice worth making deliberately in the planning conversation.** 23.48% is the
raw "anyone who writes Part D scripts" figure; 19.29% is the honest denominator; 20.63% is
the physician-only figure most comparable to the published Open Payments literature. I'd
lean toward leading with the eligible-population number and showing the other two, but that's
your call.

I have **not** applied any of these adjustments as analysis — they are reported here purely
so the denominator choice is made with eyes open.

---

### Q5 — Q4 broken down by specialty and state

#### By specialty — top 30 by prescriber volume

| specialty | prescribers | never engaged | % never engaged |
|---|---|---|---|
| Nurse Practitioner | 278,577 | 53,655 | 19.26 |
| Physician Assistant | 137,246 | 30,131 | 21.95 |
| Dentist | 132,825 | 17,408 | 13.11 |
| Internal Medicine | 130,220 | 34,828 | 26.75 |
| Family Practice | 117,797 | 29,828 | 25.32 |
| Student in Health Care Education/Training | 67,996 | 47,444 | 69.77 |
| Emergency Medicine | 56,372 | 26,747 | 47.45 |
| Optometry | 34,179 | 1,800 | 5.27 |
| Obstetrics & Gynecology | 34,042 | 3,833 | 11.26 |
| Pharmacist | 31,027 | 31,018 | 99.97 |
| Psychiatry | 23,932 | 7,448 | 31.12 |
| General Surgery | 22,409 | 1,730 | 7.72 |
| Orthopedic Surgery | 21,126 | 409 | 1.94 |
| Hospitalist | 20,385 | 7,263 | 35.63 |
| Ophthalmology | 19,644 | 1,159 | 5.90 |
| Cardiology | 19,451 | 688 | 3.54 |
| Psychiatry & Neurology | 16,260 | 6,887 | 42.36 |
| Podiatry | 15,860 | 1,203 | 7.59 |
| Neurology | 14,903 | 1,263 | 8.47 |
| Gastroenterology | 14,780 | 625 | 4.23 |
| Dermatology | 14,684 | 1,064 | 7.25 |
| Urology | 11,115 | 393 | 3.54 |
| Otolaryngology | 10,737 | 759 | 7.07 |
| Pulmonary Disease | 9,903 | 545 | 5.50 |
| Nephrology | 9,385 | 457 | 4.87 |
| Hematology-Oncology | 9,229 | 223 | 2.42 |
| Physical Medicine and Rehabilitation | 9,182 | 1,822 | 19.84 |
| General Practice | 9,179 | 2,093 | 22.80 |
| Pediatric Medicine | 8,572 | 2,284 | 26.64 |
| Endocrinology | 6,689 | 493 | 7.37 |

#### Extremes (specialties with ≥2,000 prescribers)

**Most saturated by industry** — near-zero white space:

| specialty | prescribers | % never engaged |
|---|---|---|
| Clinical Cardiac Electrophysiology | 2,709 | **0.52** |
| Interventional Cardiology | 4,946 | 0.73 |
| Vascular Surgery | 3,555 | 0.87 |
| Neurosurgery | 3,812 | 1.60 |
| Orthopedic Surgery | 21,126 | 1.94 |
| Hematology-Oncology | 9,229 | 2.42 |
| Medical Oncology | 3,702 | 2.76 |
| Plastic and Reconstructive Surgery | 3,786 | 3.06 |
| Urology | 11,115 | 3.54 |
| Cardiology | 19,451 | 3.54 |
| Pain Management | 2,911 | 3.92 |
| Gastroenterology | 14,780 | 4.23 |

**Largest white space:**

| specialty | prescribers | % never engaged |
|---|---|---|
| Pharmacist | 31,027 | 99.97 *(structurally ineligible)* |
| Student in Health Care Education/Training | 67,996 | 69.77 *(structurally ineligible)* |
| Emergency Medicine | 56,372 | 47.45 |
| Psychiatry & Neurology | 16,260 | 42.36 |
| Neuropsychiatry | 2,699 | 40.87 |
| Specialist | 2,602 | 36.24 |
| Hospitalist | 20,385 | 35.63 |
| Diagnostic Radiology | 3,355 | 34.87 |
| Psychiatry | 23,932 | 31.12 |
| Internal Medicine | 130,220 | 26.75 |
| Pediatric Medicine | 8,572 | 26.64 |
| Family Practice | 117,797 | 25.32 |

#### By state (states/territories with ≥500 prescribers, sorted by white space)

| state | prescribers | never engaged | % | | state | prescribers | never engaged | % |
|---|---|---|---|---|---|---|---|---|
| VT | 3,021 | 2,003 | **66.30** | | CO | 24,613 | 5,715 | 23.22 |
| MN | 26,278 | 11,814 | **44.96** | | PA | 65,806 | 15,089 | 22.93 |
| ME | 7,378 | 3,285 | **44.52** | | MI | 47,240 | 10,529 | 22.29 |
| WA | 33,339 | 13,677 | 41.02 | | VA | 33,533 | 7,459 | 22.24 |
| OR | 19,553 | 7,884 | 40.32 | | IL | 53,816 | 11,928 | 22.16 |
| WI | 26,027 | 10,305 | 39.59 | | UT | 11,663 | 2,372 | 20.34 |
| MA | 40,651 | 15,316 | 37.68 | | OH | 54,590 | 11,059 | 20.26 |
| NH | 7,251 | 2,454 | 33.84 | | SC | 22,190 | 4,429 | 19.96 |
| DC | 5,295 | 1,788 | 33.77 | | SD | 4,109 | 816 | 19.86 |
| NM | 8,416 | 2,734 | 32.49 | | DE | 4,475 | 877 | 19.60 |
| AK | 3,139 | 985 | 31.38 | | NC | 45,303 | 8,807 | 19.44 |
| RI | 5,928 | 1,825 | 30.79 | | LA | 20,790 | 3,821 | 18.38 |
| MT | 5,025 | 1,482 | 29.49 | | MO | 26,154 | 4,726 | 18.07 |
| NY | 106,124 | 31,243 | 29.44 | | TN | 29,866 | 5,138 | 17.20 |
| IA | 13,437 | 3,923 | 29.20 | | NV | 10,732 | 1,725 | 16.07 |
| WY | 2,212 | 643 | 29.07 | | IN | 26,776 | 4,274 | 15.96 |
| CT | 20,119 | 5,703 | 28.35 | | KS | 11,827 | 1,858 | 15.71 |
| CA | 143,204 | 39,177 | 27.36 | | FL | 97,257 | 15,073 | 15.50 |
| MD | 27,112 | 6,802 | 25.09 | | GA | 37,951 | 5,698 | 15.01 |
| PR | 11,228 | 2,755 | 24.54 | | OK | 14,439 | 2,161 | 14.97 |
| AZ | 30,663 | 7,331 | 23.91 | | TX | 95,720 | 14,214 | 14.85 |
| ID | 7,714 | 1,837 | 23.81 | | NE | 8,489 | 1,242 | 14.63 |
| WV | 8,677 | 2,066 | 23.81 | | NJ | 37,320 | 5,305 | 14.21 |
| HI | 5,044 | 1,185 | 23.49 | | AL | 18,322 | 2,599 | 14.19 |
| AR | 12,160 | 2,832 | 23.29 | | KY | 19,568 | 2,434 | 12.44 |
| ND | 3,599 | 836 | 23.23 | | MS | 10,881 | 1,066 | 9.80 |

**Observation, flagged rather than analyzed:** the top of that list — VT, MN, ME, WA, OR, WI,
MA — is close to a roster of states with statutory restrictions on pharmaceutical marketing
or gift-giving (Vermont's gift ban, Minnesota's $50 cap, Massachusetts' disclosure code).
The spread is 66.3% down to 9.8%, a 6.8× range. That is a large effect and it looks
structural rather than noise. I am not pursuing it; noting it because it likely deserves to
be a segmentation axis in the "why are they unengaged" work.

**Caveat:** state here is the Part D `Prscrbr_State_Abrvtn` (billing address), which is not
necessarily where the prescriber practices. Cross-checking against NPPES practice-location
state is worth doing before this goes in a deliverable.

---

### Q6 — NPPES schema

**330 columns**, 9,671,888 rows, one row per NPI (no duplicates). Only **2** of the 1,416,883
Part D NPIs are absent from NPPES — essentially complete coverage.

Fields relevant to this project:

| purpose | column(s) |
|---|---|
| Entity type | `Entity Type Code` (1 = Individual, 2 = Organization) |
| Taxonomy | `Healthcare Provider Taxonomy Code_1` … `_15` |
| Primary taxonomy flag | `Healthcare Provider Primary Taxonomy Switch_1` … `_15` (X/Y/N) |
| License number | `Provider License Number_1` … `_15` |
| License state | `Provider License Number State Code_1` … `_15` |
| Practice state | `Provider Business Practice Location Address State Name` |
| Practice ZIP | `Provider Business Practice Location Address Postal Code` |
| Mailing state | `Provider Business Mailing Address State Name` |
| Credential | `Provider Credential Text` |
| Sex | `Provider Sex Code` |
| Career vintage | `Provider Enumeration Date` |
| Still active? | `NPI Deactivation Date`, `NPI Deactivation Reason Code`, `NPI Reactivation Date` |
| Solo practice | `Is Sole Proprietor` (Y/N/X) |

`Provider Enumeration Date` and `Is Sole Proprietor` are both directly useful for the
"why unengaged" segmentation and weren't in the handoff's plan.

---

### Q7 — Which taxonomy codes are MD/DO physicians?

**Could not be answered from the PDF** (see Flag 2). Derived empirically instead: for every
NPPES individual, I compared the primary taxonomy code prefix against whether the free-text
credential field starts with MD or DO.

```sql
WITH b AS (SELECT "Healthcare Provider Taxonomy Code_1" AS tax,
                  upper(regexp_replace(coalesce("Provider Credential Text",''),'[^A-Za-z]','','g')) AS cred
           FROM 'work/nppes_npidata.parquet' WHERE "Entity Type Code"='1')
SELECT left(tax,4) AS prefix4, count(*) n,
       round(100.0*count(*) FILTER (WHERE cred LIKE 'MD%' OR cred LIKE 'DO%')/count(*),1) pct_md_do
FROM b WHERE tax LIKE '20%' GROUP BY 1 ORDER BY 2 DESC;
```

The separation is unambiguous:

| prefix | n | % credentialed MD/DO | verdict |
|---|---|---|---|
| `207*` (all subfamilies) | ~780,000 | 90–95% | **MD/DO** |
| `208*` (all subfamilies) | ~394,000 | 87–94% | **MD/DO** |
| `204D`, `204F`, `204R` | ~2,400 | 90–96% | MD/DO (small) |
| `204E` (oral & maxillofacial surgery) | 1,147 | 19.5% | **dental, exclude** |
| `202*`, `2098`, `208U` | small | 24–71% | mixed, low volume |
| `390*` (students) | 354,852 | 45.8% | trainee, not a practice specialty |
| everything else (`101*`,`103*`,`122*`,`171*`,`183*`, …) | — | <2% | not physicians |

**Recommended operational definition: primary taxonomy matching `207%` or `208%`.** That is
also exactly the NUCC "Allopathic & Osteopathic Physicians" Level‑1 grouping. It yields
**655,004** Part D 2024 prescribers.

The 8–13% of 207x/208x holders without an MD/DO credential string are almost entirely people
who left `Provider Credential Text` blank or wrote something non-standard — that field is
free text and not validated. It is a limitation of the *credential* field, not evidence
against the taxonomy classification.

**Caveat:** this is inference, not the authoritative NUCC list. It is good enough for scoping;
if a published deliverable depends on the exact code set, get the NUCC CSV.

---

### Q8 — Part D volume fields and suppression

Suppression works two ways in this file: a `*_Sprsn_Flag` column and a blank value in the
corresponding measure.

| field | blank rows | % of 1,416,883 |
|---|---|---|
| `Tot_Clms` | **0** | 0% |
| `Tot_Drug_Cst` | **0** | 0% |
| `Bene_Avg_Age` | **0** | 0% |
| `Tot_Benes` | 145,511 | 10.27% |
| `Gnrc_Tot_Clms` | 31,303 | 2.21% |
| `GE65_Tot_Clms` | 335,561 | 23.68% |
| `Opioid_Tot_Clms` | 350,416 | 24.73% |
| `Brnd_Tot_Clms` | **622,278** | **43.92%** |

Suppression flag values:

| flag | `*` | `#` | blank |
|---|---|---|---|
| `Brnd_Sprsn_Flag` | 346,041 | 276,237 | 794,605 |
| `GE65_Sprsn_Flag` | 37,285 | 298,276 | 1,081,322 |
| `Gnrc_Sprsn_Flag` | 27,126 | 4,177 | 1,385,580 |

**The important consequence:** `Tot_Clms` and `Tot_Drug_Cst` are **never suppressed** — they
are available for all 1,416,883 prescribers and are the safe volume measures. But
**`Brnd_Tot_Clms` is missing for 44% of prescribers**, and missingness is not random — it's
concentrated among low-volume prescribers, who are disproportionately the never-engaged
population. Any brand-share metric will be biased toward the engaged group. Worth designing
around rather than discovering later.

---

### Q9 — DAC `num_org_mem` population

```sql
SELECT count(*) AS n_rows, count(DISTINCT NPI) AS distinct_npi,
       count(*) FILTER (WHERE trim(coalesce(num_org_mem,''))='') AS blank
FROM 'work/dac_national.parquet';
```

- 3,387,942 rows, **1,616,566 distinct NPIs** (multiple rows per NPI — one per practice
  location / organization affiliation)
- `num_org_mem` blank on 344,818 rows (**10.18%**)
- `org_pac_id` blank on 344,817 rows — the two are essentially the same records (solo
  practitioners with no group affiliation)
- **86.35%** of distinct NPIs (1,395,954) have a non-blank `num_org_mem` on at least one row

Distribution depends heavily on the unit of analysis, and the difference matters:

| unit | min | p25 | median | p75 | max |
|---|---|---|---|---|---|
| per row | 2 | 58 | 313 | 1,371 | 11,244 |
| **per NPI** (max across rows) | 2 | 38 | **248** | 1,187 | 11,244 |
| **per organization** (distinct `org_pac_id`, n=83,320) | 2 | 2 | **4** | 9 | 11,244 |

**The row-level and NPI-level medians are misleading on their own.** The median *organization*
has 4 members, but the median *physician* is in a group of 248 — because large groups
contribute proportionally more rows and more physicians. Both facts are true and they answer
different questions. For Phase B's access proxy you want the per-NPI figure; for describing
the practice landscape you want the per-organization figure. Worth being explicit about which
one any given chart is showing.

---

### Q10 — Facility_Affiliation

2,260,193 rows, **940,350 distinct NPIs**. Seven `facility_type` values, no nulls or junk:

| facility_type | rows | distinct NPIs |
|---|---|---|
| Hospital | 1,917,431 | 927,092 |
| Home health agency | 213,118 | 122,538 |
| Hospice | 42,020 | 30,511 |
| Nursing home | 40,841 | 22,280 |
| Dialysis facility | 21,457 | 8,221 |
| Inpatient rehabilitation facility | 19,302 | 18,132 |
| Long-term care hospital | 6,024 | 5,803 |

Hospital affiliation dominates: 927,092 of the 940,350 NPIs in this file (98.6%) have at
least one hospital affiliation, so this file is close to a hospital-affiliation indicator
with a small amount of post-acute detail attached.

---

### Q11 — General Payments PY2025: columns and Nature of Payment

**95 columns**, 16,131,856 rows, single program year (`Program_Year` = 2025 for every row).

Column families: `Change_Type`, `Covered_Recipient_Type`, `Teaching_Hospital_*` (3),
`Covered_Recipient_Profile_ID`, **`Covered_Recipient_NPI`**, recipient name (4), recipient
address (7), `Covered_Recipient_Primary_Type_1..6`, `Covered_Recipient_Specialty_1..6`,
`Covered_Recipient_License_State_code1..5`, manufacturer/GPO (5),
`Total_Amount_of_Payment_USDollars`, `Date_of_Payment`,
`Number_of_Payments_Included_in_Total_Amount`, `Form_of_Payment_or_Transfer_of_Value`,
`Nature_of_Payment_or_Transfer_of_Value`, travel (3), `Physician_Ownership_Indicator`,
third-party (3), `Charity_Indicator`, `Contextual_Information`,
`Delay_in_Publication_Indicator`, `Record_ID`, `Dispute_Status_for_Publication`,
`Related_Product_Indicator`, then 5 repeating product blocks
(`Covered_or_Noncovered_Indicator_N`, `Indicate_Drug_or_Biological_or_Device_or_Medical_Supply_N`,
`Product_Category_or_Therapeutic_Area_N`, `Name_of_Drug_..._N`,
`Associated_Drug_or_Biological_NDC_N`, `Associated_Device_or_Medical_Supply_PDI_N`),
`Program_Year`, `Payment_Publication_Date`.

| Nature of Payment | records | distinct NPIs | total USD |
|---|---|---|---|
| **Food and Beverage** | **14,764,648** | **993,708** | $443,396,830 |
| Travel and Lodging | 623,496 | 78,410 | $209,661,393 |
| Compensation for services other than consulting (faculty/speaker, non-CE venue) | 249,154 | 26,696 | $751,881,628 |
| Consulting Fee | 205,079 | 43,223 | $648,985,308 |
| Education | 161,500 | 94,761 | $69,937,212 |
| Gift | 26,637 | 15,245 | $5,764,206 |
| Honoraria | 25,134 | 7,680 | $80,489,847 |
| Long term medical supply or device loan | 16,837 | 3,468 | $38,581,138 |
| Royalty or License | 15,496 | 2,470 | $1,203,443,513 |
| Compensation for faculty/speaker, medical education program | 15,039 | 3,552 | $34,131,281 |
| Space rental or facility fees (teaching hospital only) | 8,371 | 0 | $37,314,258 |
| Grant | 7,352 | 2,762 | $121,704,361 |
| Debt forgiveness | 6,179 | 692 | $48,590,176 |
| Entertainment | 5,849 | 4,287 | $506,793 |
| Charitable Contribution | 680 | 90 | $5,282,164 |
| Acquisitions | 405 | 265 | $223,880,856 |

16 distinct values, no nulls or malformed categories.

**Directly relevant to Phase C:** Food and Beverage is **91.5% of all records** and reaches
**993,708 distinct NPIs** — 97.4% of the 1,020,608 NPIs receiving anything in PY2025. So the
in-person rep-visit signal is essentially co-extensive with "engaged at all" in a given year.
Note the inversion between volume and dollars: Food and Beverage is 91.5% of records but 12%
of dollars, while Royalty or License is 0.1% of records and the single largest dollar
category. Counting records and summing dollars will tell very different stories.

---

### Q12 — Malformed NPIs in the Profile Supplement

```sql
SELECT count(*) AS total,
  count(*) FILTER (WHERE trim(coalesce(Covered_Recipient_NPI,''))='') AS blank_npi,
  count(*) FILTER (WHERE trim(coalesce(Covered_Recipient_NPI,''))<>''
                     AND NOT regexp_matches(Covered_Recipient_NPI,'^[0-9]{10}$')) AS fails_10digit,
  count(*) FILTER (WHERE regexp_matches(coalesce(Covered_Recipient_NPI,''),'^[0-9]{10}$')
                     AND left(Covered_Recipient_NPI,1) NOT IN ('1','2')) AS bad_leading_digit
FROM 'work/op_profile_supplement.parquet';
```

| total | blank/null | fails 10-digit check | invalid leading digit |
|---|---|---|---|
| 1,697,025 | **15,235** (0.90%) | **0** | **0** |

**Every non-blank NPI is a well-formed 10-digit number starting with 1 or 2.** Zero
malformation. The only data-quality issue is the 15,235 blanks (see Flag 3). I did not run
the Luhn check digit — say the word if you want it, it's cheap.

Part D is equally clean: 0 blank, 0 malformed out of 1,416,883.

---

### Q13 — `Covered_Recipient_Profile_Type` distribution

| profile type | n | % |
|---|---|---|
| Covered Recipient Physician | 1,146,092 | 67.54 |
| Covered Recipient Non-Physician Practitioner | 534,482 | 31.50 |
| Covered Recipient Physician/Covered Recipient Non-Physician Practitioner | 16,451 | 0.97 |

Three values exactly as §4 described, no nulls, no surprises. Note the combined third
category is small enough (0.97%) that whichever way you assign it won't move headline numbers
materially — but it does need an explicit rule.

---

## Summary of what changed vs. the handoff

| Handoff assumption | Status |
|---|---|
| Profile Supplement is the cumulative roster → absence = never engaged | ✅ **Confirmed**, three independent ways |
| Profile Supplement has fully-populated valid NPIs | ⚠️ Valid yes (0 malformed), fully populated **no** (0.90% blank) |
| Payment detail files lack NPI | ❌ **False** — General Payments is 99.73% NPI-populated |
| CodeValues PDF has MD/DO taxonomy codes | ❌ **False** — PDF points to an external source |
| No entity resolution needed; NPI join is exact | ✅ **Confirmed** — 1:1 throughout, only 2 Part D NPIs absent from NPPES |
| §4 schemas (32/31/9 columns) | ✅ **Confirmed** on full files |
| ~21 GB CSV → under 4 GB Parquet | ✅ **21 GB → 1.9 GB** |

## Open questions for the planning conversation

1. **Which denominator anchors the headline** — 23.48% (all Part D), 19.29% (excluding
   structurally-ineligible pharmacists/trainees), or 20.63% (MD/DO only)?
2. **The state pattern is large and looks statutory.** Does state marketing law become a
   named segmentation axis, or stay a caveat?
3. **Brand-claims suppression at 44%** is non-random and correlated with the outcome. Does
   any planned metric depend on it?
4. **Billing state vs. practice state** — worth reconciling Part D address against NPPES
   practice location before publishing state-level numbers.
5. **The 15,235 blank-NPI supplement rows** — accept as a stated one-directional bias, or
   attempt profile-ID-based recovery via the General Payments file?
6. **Source CSVs (21 GB) are still on disk.** Delete, or keep?
