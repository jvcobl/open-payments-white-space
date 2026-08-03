#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# 00_convert_to_parquet.sh
#
# PRODUCES : work/*.parquet — every CMS source CSV converted to Parquet
# SOURCE   : README.md; PHASE_R_FINDINGS.md §Files;
#            PHASE_W_FINDINGS.md §"Conversion and verification"
# INPUTS   : the CMS source CSVs in the repository root (see README for URLs).
#            None are in this repo — they are publicly redownloadable, ~35 GB.
#
# All CSVs are read with all_varchar=true. CMS files contain leading zeros,
# mixed types and embedded commas; type inference silently corrupts them.
# Casting happens deliberately in 01_build_analytic_population.sql.
#
# Row counts are verified against source after every conversion. A mismatch is
# fatal — the pipeline stops rather than proceed on a truncated file.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail
cd "$(dirname "$0")/.."
DUCKDB="${DUCKDB:-duckdb}"
mkdir -p work

MEM="${DUCKDB_MEMORY_LIMIT:-9GB}"
THREADS="${DUCKDB_THREADS:-3}"
PRELUDE="SET memory_limit='${MEM}'; SET threads=${THREADS}; SET preserve_insertion_order=false;"

convert () {                      # convert <source-csv-glob> <output-parquet>
  local src out a b
  src=$(ls $1 2>/dev/null | head -1) || true
  out="$2"
  if [ -z "${src:-}" ]; then echo "SKIP   $out (no source matching $1)"; return 0; fi
  if [ -f "$out" ];   then echo "EXISTS $out"; return 0; fi
  echo "BUILD  $out  <-  $src"
  $DUCKDB -c "${PRELUDE}
    COPY (SELECT * FROM read_csv('${src}', all_varchar=true, header=true))
    TO '${out}' (FORMAT PARQUET, COMPRESSION ZSTD, ROW_GROUP_SIZE 100000);"
  a=$($DUCKDB -csv -noheader -c "${PRELUDE} SELECT count(*) FROM read_csv('${src}', all_varchar=true, header=true);")
  b=$($DUCKDB -csv -noheader -c "SELECT count(*) FROM '${out}';")
  if [ "$a" != "$b" ]; then echo "FATAL row count mismatch $out: csv=$a parquet=$b" >&2; exit 1; fi
  echo "       verified $b rows"
}

# Largest first, while disk headroom is greatest.
convert "nppes/npidata_pfile_*[0-9].csv"   work/nppes_npidata.parquet
convert "OP_DTL_GNRL_PGYR2025_*.csv"       work/op_general_py2025.parquet
convert "OP_DTL_GNRL_PGYR2024_*.csv"       work/op_general_py2024.parquet
convert "OP_DTL_GNRL_PGYR2023_*.csv"       work/op_general_py2023.parquet
convert "OP_DTL_GNRL_PGYR2022_*.csv"       work/op_general_py2022.parquet
convert "OP_DTL_GNRL_PGYR2021_*.csv"       work/op_general_py2021.parquet
convert "DAC_NationalDownloadableFile.csv" work/dac_national.parquet
convert "OP_CVRD_RCPNT_PRFL_SPLMTL_*.csv"  work/op_profile_supplement.parquet
convert "Facility_Affiliation.csv"         work/facility_affiliation.parquet
convert "partd/*/2024/MUP_DPR_*_NPI.csv"   work/partd_2024.parquet

for y in 2021 2022 2023 2024 2025; do
  convert "OP_DTL_RSRCH_PGYR${y}_*.csv"   "work/op_rsrch_py${y}.parquet"
  convert "OP_DTL_OWNRSHP_PGYR${y}_*.csv" "work/op_ownrshp_py${y}.parquet"
done

echo "00_convert_to_parquet.sh complete."
