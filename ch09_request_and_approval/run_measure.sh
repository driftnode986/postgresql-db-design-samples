#!/usr/bin/env bash
# 第9章の測定を最初から通しで実行し、results/ に保存する。
#
#   SIZE=S bash ch09_request_and_approval/run_measure.sh
#
# 🔴 SQL とコメントを直したら、必ずこれを流し直す。
#    本文の数値は docs/chapter-src/values_ch09.py がここの出力から求めるので、
#    ログが古いまま本文を組み立てると、実測と本文が食い違う。
#
# 🔴 必ず reset-chapter から始める。案を作り直した直後に測ると、
#    別の案の古いテーブルが残ったまま比較され、検査が食い違う（実際に 163 件の差が出た）。
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
CH=ch09_request_and_approval
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

echo "■ やり直し"
bash scripts/reset-chapter.sh 09 >/dev/null 2>&1

echo "■ 元データ"
save "source_$SIZE.txt" book_owner ch09_r "$CH/r_source/schema_10_table.sql" || exit 1
{ bash scripts/collect-env.sh; echo "# SIZE=$SIZE"; echo
  SIZE="$SIZE" bash scripts/run-sql.sh book_owner ch09_r "$CH/r_source/schema_20_generate.sql"; } \
  >> "$R/source_$SIZE.txt" 2>&1 || exit 1

echo "■ 採取された案の検算（期間を 2 列で持つと重なりとすき間が入る）"
save "schema_ch09_x.txt" book_owner ch09_x "$CH/x_first_idea/schema.sql" || exit 1
save "first_idea_$SIZE.txt" book_owner ch09_x "$CH/x_first_idea/load.sql" || exit 1

echo "■ 4 案のテーブルとデータ"
for s in a_status_column:ch09_a b_events_only:ch09_b \
         c_current_plus_history:ch09_c d_range_pk:ch09_d; do
  d="${s%%:*}"; sc="${s##*:}"
  save "schema_${sc}.txt" book_owner "$sc" "$CH/$d/schema.sql" || exit 1
  save "load_${sc}_$SIZE.txt" book_owner "$sc" "$CH/$d/load.sql" || exit 1
done

echo "■ WITHOUT OVERLAPS が拒否する 2 つの形（どちらもエラーになるのが正常）"
save "overlap_fails_$SIZE.txt" book_owner ch09_d "$CH/d_range_pk/20_overlap_fails.sql"
save "empty_range_fails_$SIZE.txt" book_owner ch09_d "$CH/d_range_pk/21_empty_range_fails.sql"

echo "■ 一覧「申請中を新しい順に 20 件」（3 回）"
{ bash scripts/collect-env.sh; echo "# SIZE=$SIZE"; echo; } > "$R/inbox_$SIZE.txt"
for n in 1 2 3; do
  echo "## 10_inbox.sql run $n" >> "$R/inbox_$SIZE.txt"
  SIZE="$SIZE" bash scripts/run-sql.sh book_app ch09_a \
    "$CH/queries/10_inbox.sql" >> "$R/inbox_$SIZE.txt" 2>&1
done
echo "  10_inbox.sql -> $R/inbox_$SIZE.txt"

echo "■ 現在の内容と、ある時点の全件（3 回）"
{ bash scripts/collect-env.sh; echo "# SIZE=$SIZE"; echo; } > "$R/asof_$SIZE.txt"
for n in 1 2 3; do
  echo "## 20_asof.sql run $n" >> "$R/asof_$SIZE.txt"
  SIZE="$SIZE" bash scripts/run-sql.sh book_app ch09_c \
    "$CH/queries/20_asof.sql" >> "$R/asof_$SIZE.txt" 2>&1
done
echo "  20_asof.sql -> $R/asof_$SIZE.txt"

echo "■ 状態の型を変えるときに取るロック"
save "locks_$SIZE.txt" book_owner ch09_a "$CH/a_status_column/30_status_type_locks.sql" || exit 1

echo "■ 18 の RETURNING old/new で履歴を書く"
save "returning_$SIZE.txt" book_owner ch09_c "$CH/c_current_plus_history/40_returning_old.sql" || exit 1

echo "■ サイズ"
save "sizes_$SIZE.txt" book_app ch09_a "$CH/queries/50_sizes.sql" || exit 1

echo "■ 変更の手数（案C から案D へ移す）"
save "change_$SIZE.txt" book_owner ch09_d "$CH/change/10_migrate_c_to_d.sql" || exit 1

echo "■ 検査（すべて先頭列が 0 で正常）"
save "verify_$SIZE.txt" book_owner ch09_a "$CH/queries/90_verify.sql"

echo "完了。SIZE=$SIZE の結果は $R/ にある。"
