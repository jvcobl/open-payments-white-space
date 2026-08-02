# Project Handoff — Pharma Engagement White Space

**Read this first. It is self-contained. The user should not have to explain anything.**

---

## 1. Who and what

Jacob Lee, undergraduate at Emory (Neuroscience & Behavioral Biology). Strong on measurement methodology and data judgment; limited Python fluency — he reads and verifies code rather than writing it from scratch. Explain what you're doing in plain language and chunk your work so he can follow it.

**The project:** identify and characterize US Medicare Part D prescribers who have **never received anything from the pharmaceutical industry** — the "white space" population.

**Why it matters:** every published study linking Open Payments to prescribing has asked whether industry payments influence prescribing. The engaged physicians were the subject; the unengaged were the discarded control group. Nobody has turned around and characterized them. Meanwhile the entire HCP-engagement industry (IQVIA, Veeva, Doximity, Impiricus) is built on reaching exactly that population.

**Deliverable:** a national characterization of never-engaged prescribers, plus segmentation of *why* they're unengaged. Portfolio piece for health-tech / health-AI industry roles.

---

## 2. The key discovery — read carefully

We planned this project believing Open Payments does not publish NPIs, which is what CMS documentation, an HHS open-data ticket, and multiple published papers all state. **That is true of the payment detail files and false of the Covered Recipient Profile Supplement.**

The Profile Supplement contains `Covered_Recipient_NPI`, fully populated with valid 10-digit NPIs.

**Consequences:**
- No entity resolution, no fuzzy name matching, no crosswalk to build. **Do not build one.**
- Joins are exact on NPI. No match error, no recall ceiling, no bias correction needed.
- **The Profile Supplement is the roster of everyone who has ever received anything.** Therefore: *a prescriber absent from it has never been engaged.* This is the core logic of the entire project.

**Corollary:** the headline finding requires only Part D + Profile Supplement + NPPES. The 8.6 GB General Payments file is needed only for later enrichment.

---

## 3. Files on disk

All under `~/whitespace`:

| File | Approx size | Role |
|---|---|---|
| `OP_CVRD_RCPNT_PRFL_SPLMTL_*.csv` | 386 MB, ~1,697,028 lines | **Roster of all covered recipients.** Core file. |
| `OP_DTL_GNRL_PGYR2025_*.csv` | 8.6 GB | General Payments PY2025. Enrichment only — Phase C. |
| `nppes/npidata_pfile_*.csv` | 11 GB | NPI registry. Specialty, geography, entity type. |
| `nppes/npidata_pfile_*_fileheader.csv` | 12 KB | Header-only version |
| `nppes/othername_pfile_*.csv` | 48 MB | Alternate names |
| `nppes/pl_pfile_*.csv` | 112 MB | Non-primary practice locations |
| `nppes/NPPES_Data_Dissemination_CodeValues.pdf` | 2.7 MB | **Code lookups — read this** |
| `nppes/NPPES_Data_Dissemination_Readme_v.2.pdf` | 505 KB | Field documentation |
| `partd/.../2024/MUP_DPR_RY26_P04_V10_DY24_NPI.csv` | — | **Part D prescribers 2024. The denominator.** |
| `DAC_NationalDownloadableFile.csv` | 801 MB | Practice affiliation, group size |
| `Facility_Affiliation.csv` | 126 MB | Hospital/facility affiliation |

---

## 4. Verified schemas

Confirmed from actual file headers. Others are unknown — profile them.

**Profile Supplement (32 cols):**
```
Covered_Recipient_Profile_Type, Covered_Recipient_Profile_ID,
Associated_Covered_Recipient_Profile_ID_1..2, Covered_Recipient_NPI,
Covered_Recipient_Profile_First_Name, _Middle_Name, _Last_Name, _Suffix,
_Alternate_First_Name, _Alternate_Middle_Name, _Alternate_Last_Name, _Alternate_Suffix,
_Address_Line_1, _Address_Line_2, _City, _State, _Zipcode, _Country_Name, _Province_Name,
_Primary_Specialty, _OPS_Taxonomy_1..6, _License_State_Code_1..5
```
Profile types seen: `Covered Recipient Physician`, `Covered Recipient Non-Physician Practitioner`, and a combined value. The file also includes dentists.
`OPS_Taxonomy_*` are NUCC taxonomy codes — join directly to NPPES taxonomy.

**DAC_NationalDownloadableFile (31 cols):**
```
NPI, Ind_PAC_ID, Ind_enrl_ID, Provider Last Name, Provider First Name,
Provider Middle Name, suff, gndr, Cred, Med_sch, Grd_yr, pri_spec,
sec_spec_1..4, sec_spec_all, Telehlth, Facility Name, org_pac_id,
num_org_mem, adr_ln_1, adr_ln_2, ln_2_sprs, City/Town, State, ZIP Code,
Telephone Number, ind_assgn, grp_assgn, adrs_id
```
`num_org_mem` = group size. `org_pac_id` = organization identifier. Both are the access proxy.

**Facility_Affiliation (9 cols):**
```
NPI, Ind_PAC_ID, Provider Last Name, Provider First Name, Provider Middle Name,
suff, facility_type, Facility Affiliations Certification Number,
Facility Type Certification Number
```

---

## 5. TASK ONE: convert to Parquet

**Do this before any profiling.**

Convert every CSV to Parquet in `work/`, using DuckDB. Parquet is typically 5–10× smaller and dramatically faster to query. Expected: ~21 GB of CSV becomes under 4 GB.

Order matters — start with the largest file while disk headroom is greatest:

1. `nppes/npidata_pfile_*.csv` (11 GB)
2. `OP_DTL_GNRL_PGYR2025_*.csv` (8.6 GB)
3. `DAC_NationalDownloadableFile.csv`
4. `OP_CVRD_RCPNT_PRFL_SPLMTL_*.csv`
5. `Facility_Affiliation.csv`
6. Part D 2024 CSV

**After each conversion:** verify the row count matches the source, then **ask Jacob before deleting the original CSV.** Never delete without confirmation.

Read all CSVs with `all_varchar=true` on first pass. CMS files contain leading zeros, mixed types, and embedded commas — type inference will silently corrupt them. Cast deliberately afterward.

Report disk usage before and after.

---

## 6. TASK TWO: reconnaissance

**Profile the data and report back. Do not produce analysis or findings yet.**

### Critical — the project depends on Q1
1. **Is the Profile Supplement cumulative across all program years, or only PY2025?** There is no program-year column, which suggests cumulative. Confirm it. Suggested approach: check whether the supplement contains NPIs *absent* from the PY2025 General Payments file — if so, it's cumulative. **If it is not cumulative, the entire never-engaged logic breaks and we must replan.**

### Sizing
2. Part D 2024: total rows, unique NPIs, full column list.
3. Profile Supplement: unique NPIs vs. total rows. Duplicate NPIs across multiple profile IDs?
4. **The headline number:** of Part D prescribers, what share appear in the Profile Supplement and what share do not? Raw counts and percentage.
5. Break Q4 down by Part D prescriber specialty field and by state.

### Schema profiling
6. NPPES: column list from the fileheader file. Identify entity type, taxonomy codes, license number/state, practice state.
7. NPPES: which taxonomy codes are MD/DO physicians? Consult `NPPES_Data_Dissemination_CodeValues.pdf`.
8. Part D: which volume fields exist, and how many rows have suppressed (blank) values?
9. DAC: how populated is `num_org_mem`? Median, quartiles, share missing.
10. Facility_Affiliation: distinct `facility_type` values, and how many NPIs appear?
11. General Payments PY2025: column list, and distinct values of the Nature of Payment field with counts.

### Data quality
12. Any Profile Supplement NPIs that are malformed, blank, or fail a 10-digit check?
13. Profile Supplement: distribution of `Covered_Recipient_Profile_Type`.

---

## 7. Rules

- **Do not download anything.** Every file needed is on disk.
- **Do not build a name matcher or crosswalk.** The NPI join is exact.
- **Do not delete anything** without asking.
- **Query large files in place with DuckDB.** Never `pandas.read_csv` an 11 GB file.
- **Show your SQL.** Jacob verifies rather than trusting.
- If a number looks implausible, say so rather than reporting it flat.

---

## 8. Output

Write findings to `RECON_FINDINGS.md`, organized by the question numbers in Section 6. For each: the answer, the query used, any caveat.

Flag loudly, at the top, anything contradicting Sections 2 or 4. **Those were verified on 100-row samples, not full files.** If the full data disagrees, that is the most important thing you can report.

---

## 9. What happens next

Jacob brings `RECON_FINDINGS.md` to a planning conversation. We revise against what the data actually contains, then return with specific analysis tasks.

Phases sketched for context only — **do not start these:**

- **Phase A** — national never-engaged population by specialty and state. Part D + Profile Supplement + NPPES only.
- **Phase B** — access proxy. Does group size (`num_org_mem`) and hospital affiliation predict non-engagement, stratified by specialty?
- **Phase C** — channel map. Food-and-beverage payments as the in-person rep-visit signal, separating physicians reached in person from those reached only non-personally. Requires General Payments, one year at a time.
