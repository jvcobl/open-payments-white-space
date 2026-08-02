#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# run_all.sh
#
# PRODUCES : the full pipeline, then a pass/fail check of the seven headline
#            figures against their published values in findings/
# SOURCE   : PHASE_P_TASKS.md §P2
# INPUTS   : work/*.parquet (run 00_convert_to_parquet.sh first if absent)
#
# Requires: duckdb on PATH (or $DUCKDB), python3 with matplotlib + pandas.
#
#   ./scripts/run_all.sh              full pipeline + checks + figures
#   ./scripts/run_all.sh --check-only skip rebuild; just verify + figures
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail
cd "$(dirname "$0")/.."
DUCKDB="${DUCKDB:-duckdb}"
PY="${PYTHON:-python3}"
CHECK_ONLY="${1:-}"
mkdir -p figures/data logs

command -v "$DUCKDB" >/dev/null 2>&1 || { echo "FATAL: duckdb not found. Set \$DUCKDB." >&2; exit 1; }

START=$(date +%s)
run_sql () {
  echo ""; echo "═══ $1 ═══"
  $DUCKDB < "scripts/$1" | tee "logs/${1%.sql}.log"
}

if [ "$CHECK_ONLY" != "--check-only" ]; then
  [ -f work/analytic_population.parquet ] || echo "NOTE: run scripts/00_convert_to_parquet.sh first if this fails"
  run_sql 01_build_analytic_population.sql
  run_sql 02_channel_classification.sql
fi
run_sql 03_state_analysis.sql
run_sql 04_organization_analysis.sql
run_sql 05_discriminant.sql
run_sql 06_amc_validation.sql

# ── headline verification ────────────────────────────────────────────────────
echo ""; echo "═══ HEADLINE FIGURE VERIFICATION ═══"
q () { $DUCKDB -csv -noheader -c "$1"; }

MDDO=$(q "SELECT count(*) FROM 'work/analysis_base.parquet';")
NEVER=$(q "SELECT count(*) FROM 'work/analysis_base.parquet' WHERE never_base;")
NEVER_PCT=$(q "SELECT round(100.0*count(*) FILTER (WHERE never_base)/count(*),2) FROM 'work/analysis_base.parquet';")
S553=$(q "SELECT count(*) FROM 'work/analysis_base.parquet' WHERE never_base AND clms_decile>=9 AND cpc_decile>=9;")
S553M=$(q "SELECT CAST(round(sum(tot_drug_cst)/1e6,0) AS BIGINT) FROM 'work/analysis_base.parquet' WHERE never_base AND clms_decile>=9 AND cpc_decile>=9;")
MEALONLY=$(q "SELECT round(100.0*count(*) FILTER (WHERE n_nonfnb5=0)/count(*),1) FROM 'work/analysis_base.parquet' WHERE paid_5yr;")
RELONLY=$(q "SELECT count(*) FROM 'work/analysis_base.parquet' WHERE cell4='3 relationship-only';")
RELONLY_PCT=$(q "SELECT round(100.0*count(*) FILTER (WHERE cell4='3 relationship-only')/count(*),2) FROM 'work/analysis_base.parquet';")
AMC=$(sed -n '2,$p' figures/data/discriminant_amcs.csv | cut -d, -f7 | sort -g | \
      awk '{a[NR]=$1} END {printf "%.3f", (NR%2 ? a[(NR+1)/2] : (a[NR/2]+a[NR/2+1])/2)}')
KAISER=$(q "WITH k AS (SELECT *, (n_nonfnb5>0 OR has_research) AS any_non FROM 'work/analysis_base.parquet'),
  crS AS (SELECT coalesce(partd_specialty,'?') sp, clms_decile vd, coalesce(partd_state,'?') st,
          avg((n_fnb5>0)::INT) p_fnb, avg(any_non::INT) p_non FROM k GROUP BY 1,2,3)
  SELECT round(median(d),3) FROM (
    SELECT (avg(k.any_non::INT)/avg(crS.p_non))/(avg((k.n_fnb5>0)::INT)/avg(crS.p_fnb)) d
    FROM k JOIN crS ON coalesce(k.partd_specialty,'?')=crS.sp AND k.clms_decile=crS.vd
                   AND coalesce(k.partd_state,'?')=crS.st
    WHERE (k.org_primary_name ILIKE '%PERMANENTE%' OR k.org_primary_name ILIKE '%KAISER%')
      AND k.org_primary IS NOT NULL GROUP BY k.org_primary HAVING count(*)>=100);")

FAILED=0
check () {  # check <label> <published> <actual>   — exact match required
  if [ "$2" == "$3" ]; then printf "  PASS   %-38s %s\n" "$1" "$3"
  else printf "  FAIL   %-38s published %s, got %s\n" "$1" "$2" "$3"; FAILED=1; fi
}
checkf () { # checkf <label> <published> <actual> <tolerance> — see note below
  local d
  d=$($PY -c "print(f'{abs($2-$3):.4f}')")
  if $PY -c "import sys; sys.exit(0 if abs($2-$3)<=$4 else 1)"; then
    if [ "$2" == "$3" ]; then printf "  PASS   %-38s %s\n" "$1" "$3"
    else printf "  PASS*  %-38s published %s, got %s  (Δ%s ≤ %s)\n" "$1" "$2" "$3" "$d" "$4"; fi
  else printf "  FAIL   %-38s published %s, got %s  (Δ%s)\n" "$1" "$2" "$3" "$d"; FAILED=1; fi
}
check  "MD/DO Part D prescribers"      "696647" "$MDDO"
check  "Never-engaged (baseline)"      "146459" "$NEVER"
check  "Never-engaged %"               "21.02"  "$NEVER_PCT"
check  "Selection-robust group"        "553"    "$S553"
check  "Selection-robust group \$M"     "924"    "$S553M"
check  "Meal-only, 5-year %"           "58.7"   "$MEALONLY"
check  "Four-cell relationship-only"   "8715"   "$RELONLY"
check  "Four-cell relationship-only %" "1.25"   "$RELONLY_PCT"
# ── The two discriminant medians carry a documented ±0.002 tolerance. ─────────
# The published values (1.110, 0.727) were computed before NTILE was given a
# deterministic tiebreaker. 99.2% of MD/DOs share a tot_clms value with another
# physician, so the original decile assignment split tie groups by physical row
# order and varied between runs; ~1,838 physicians (0.26%) moved decile, shifting
# these medians by 0.001. This pipeline is now deterministic and returns
# 1.109 / 0.726 on every run. Substantive conclusions are unaffected: AMC min
# 0.933 still exceeds Kaiser max 0.791, so the separation remains complete.
# Full reconciliation in PHASE_P_NOTES.md.
checkf "AMC median discriminant"       "1.110"  "$AMC"    "0.002"
checkf "Kaiser median discriminant"    "0.727"  "$KAISER" "0.002"

echo ""; echo "═══ FIGURES ═══"
$PY figures/fig1_discriminant.py
$PY figures/fig2_state_channel.py
$PY figures/fig3_volume_gradient.py

echo ""
printf "Total runtime: %d seconds\n" "$(( $(date +%s) - START ))"
if [ "$FAILED" -ne 0 ]; then
  echo "RESULT: ONE OR MORE HEADLINE FIGURES DID NOT REPRODUCE — see FAIL lines above." >&2
  exit 1
fi
echo "RESULT: all headline figures reproduce."
