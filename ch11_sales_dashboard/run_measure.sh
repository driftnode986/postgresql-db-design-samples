#!/usr/bin/env bash
# 第11章の測定を最初から通しで実行し、results/ に保存する。
#
#   SIZE=S bash ch11_sales_dashboard/run_measure.sh
#
# 🔴 SQL とコメントを直したら、必ずこれを流し直す。
#    本文の数値は docs/chapter-src/values_ch11.py がここの出力から求めるので、
#    ログが古いまま本文を組み立てると、実測と本文が食い違う。
#
# 🔴 必ず reset-chapter から始める。案を作り直した直後に測ると、
#    別の案の古いテーブルが残ったまま比較される（第9章で 163 件の差が出た）。
#
# 🔴 実行の順序が大事:
#      サイズ → 読み取り → 検査 → （ここから先はデータを変える）→ drift → 変更 → pgbench
#    pgbench と drift はデータを増やす・書き換えるので、
#    サイズと読み取りより後に置く（第10章で案A が 64 MB でなく 156 MB になった）。
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
CH=ch11_sales_dashboard
R="$CH/results"
SIZE="${SIZE:-S}"
mkdir -p "$R"

save() {  # save <出力ファイル> <ロール> <スキーマ> <SQL> [追加の引数...]
  local out="$R/$1" role="$2" schema="$3" file="$4"; shift 4
  { bash scripts/collect-env.sh; echo "# SIZE=$SIZE"; echo
    SIZE="$SIZE" bash scripts/run-sql.sh "$role" "$schema" "$file" "$@"; } > "$out" 2>&1
  local rc=$?
  echo "  $file -> $out (rc=$rc)"
  return $rc
}

append() {  # append <出力ファイル> <ロール> <スキーマ> <SQL>
  local out="$R/$1" role="$2" schema="$3" file="$4"
  { echo; SIZE="$SIZE" bash scripts/run-sql.sh "$role" "$schema" "$file"; } >> "$out" 2>&1
  echo "  $file ->> $out (rc=$?)"
}

echo "■ やり直し"
bash scripts/reset-chapter.sh 11 >/dev/null 2>&1

echo "■ 元データ"
save "source_$SIZE.txt" book_owner ch11_r "$CH/r_source/schema_10_table.sql" || exit 1
append "source_$SIZE.txt" book_owner ch11_r "$CH/r_source/schema_20_generate.sql"

echo "■ 4 案のテーブルとデータ"
for s in a_on_the_fly:ch11_a b_matview:ch11_b c_summary_table:ch11_c d_hybrid:ch11_d; do
  d="${s%%:*}"; sc="${s##*:}"
  save "schema_${sc}.txt" book_owner "$sc" "$CH/$d/schema.sql" || exit 1
  append "schema_${sc}.txt" book_owner "$sc" "$CH/$d/load.sql"
done

echo "■ サイズ（実験の前に測る）"
save "sizes_$SIZE.txt" book_app ch11_a "$CH/queries/50_sizes.sql"

echo "■ 読み取り（4 案）"
save "read_$SIZE.txt" book_app ch11_a "$CH/a_on_the_fly/20_read_daily.sql"
append "read_$SIZE.txt" book_app ch11_b "$CH/b_matview/20_read_daily.sql"
append "read_$SIZE.txt" book_app ch11_c "$CH/c_summary_table/20_read_daily.sql"
append "read_$SIZE.txt" book_app ch11_d "$CH/d_hybrid/20_read_daily.sql"

echo "■ 検査（4 案の中身が一致するか）"
save "verify_$SIZE.txt" book_owner ch11_a "$CH/queries/90_verify.sql"

echo "■ マテリアライズドビューの更新（鮮度と CONCURRENTLY の条件）"
save "matview_$SIZE.txt" book_owner ch11_b "$CH/b_matview/20_staleness.sql"
append "matview_$SIZE.txt" book_owner ch11_b "$CH/b_matview/30_refresh_conditions.sql"

echo "■ REFRESH 中の読み取りの待ち（別プロセスが要るので専用スクリプト）"
{ bash scripts/collect-env.sh; echo "# SIZE=$SIZE"; echo
  bash "$CH/make_refresh_wait.sh"; } > "$R/refresh_wait_$SIZE.txt" 2>&1
echo "  make_refresh_wait.sh -> $R/refresh_wait_$SIZE.txt"

echo "■ ここから先はデータを変える"

echo "■ 差分更新の関数を作る"
save "incremental_$SIZE.txt" book_owner ch11_c "$CH/c_summary_table/30_incremental.sql"
append "incremental_$SIZE.txt" book_owner ch11_c "$CH/c_summary_table/40_shard.sql"

echo "■ ズレの検出と修復（わざとズラして検出できることを確かめる）"
save "drift_$SIZE.txt" book_owner ch11_c "$CH/c_summary_table/50_drift.sql"

echo "■ 変更の手数（集計の軸を足す）"
save "change_$SIZE.txt" book_owner ch11_c "$CH/change/10_add_dimension.sql"

echo "■ pgbench（集計行への集中。最後に回す＝データが増えるため）"
REPEAT="${REPEAT:-5}" bash "$CH/run_bench.sh" > "$R/bench_$SIZE.txt" 2>&1
echo "  run_bench.sh -> $R/bench_$SIZE.txt"

python3 - "$R/bench_$SIZE.txt" <<'PY' >> "$R/bench_$SIZE.txt"
import re, statistics, sys
txt = open(sys.argv[1], encoding='utf-8').read()
cur=None; d={}
for line in txt.split('\n'):
    m=re.match(r'=== (.+) ===', line)
    if m: cur=m.group(1); d[cur]=[]
    m=re.search(r'tps = ([\d.]+)', line)
    if m and cur: d[cur].append(float(m.group(1)))
print()
print('=== 中央値と振れ幅（5 回） ===')
print(' pattern | median_tps | spread_pct')
print('---------+------------+-----------')
for k,v in d.items():
    if not v: continue
    med=statistics.median(v); sp=(max(v)-min(v))/med*100
    print(f' {k} | {med:.0f} | {sp:.1f}')
PY

echo "■ 完了"
