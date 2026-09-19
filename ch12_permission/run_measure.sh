#!/usr/bin/env bash
# 第12章の測定を最初から通しで実行し、results/ に保存する。
#
#   SIZE=S bash ch12_permission/run_measure.sh
#
# 🔴 SQL とコメントを直したら、必ずこれを流し直す。
#    本文の数値はここの出力から引用するので、ログが古いまま本文を書くと実測と食い違う。
#
# 🔴 必ず reset-chapter から始める。案を作り直した直後に測ると、
#    別の案の古いテーブルが残ったまま比較される（第9章で 163 件の差が出た）。
#
# 🔴 実行の順序が大事:
#      元データ → 3 案 → サイズ → 読み取り（4 通り）→ 一致の検査
#      → RLS（ポリシーを付ける）→ RLS の測定 → **ポリシーを外す**
#      → 案C の初期構築 → 案C の読み取り → ここから先はデータを変える
#      → 変更の手数 → ズレの検出 → 深さ → GRANT → 期限つき招待
#
#    - サイズと読み取りは、データを変える実験より**前**（第10章・第11章の教訓）
#    - 🔴 RLS のポリシーは、その測定が終わったら**必ず外す**。
#      残すと案A の関数方式が「ポリシーが絞ったあとの行」にしか適用されず、
#      235 ms が 4 ms に見える（確認記録 §6 で実際に踏んだ）
#    - 案C の初期構築は 30 秒以上かかり、ズレの検査は 1 回 45 秒以上かかる。
#      全体で 10 分ほどかかる
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
CH=ch12_permission
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

# 🔴 *_fails.sql は「失敗するのが正しい」ファイルである。
#    成功したら、制約や権限が効いていないということなので、そこで止める。
#    （成功を黙って通すと、検査が無いのと同じになる）
append_expect_fail() {  # append_expect_fail <出力> <ロール> <スキーマ> <SQL> <期待する文面>
  local out="$R/$1" role="$2" schema="$3" file="$4" want="$5"
  { echo; SIZE="$SIZE" bash scripts/run-sql.sh "$role" "$schema" "$file"; } >> "$out" 2>&1
  local rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "  ❌ $file は失敗するはずなのに成功した（制約か権限が効いていない）"
    echo "     期待した文面: $want"
    return 1
  fi
  if ! tail -20 "$out" | grep -q "$want"; then
    echo "  ❌ $file は失敗したが、期待した文面が出ていない"
    echo "     期待した文面: $want"
    return 1
  fi
  # 🔴 ${rc} と波括弧で囲む。$rc・ と書くと、bash が全角の「・」を
  #    変数名の一部として読み、「rc・: 未割り当ての変数です」で止まる（実際に踏んだ）。
  echo "  $file ->> $out (rc=${rc} 期待どおり失敗)"
}

echo "■ やり直し"
bash scripts/reset-chapter.sh 12 >/dev/null 2>&1

echo "■ 元データ"
save "source_$SIZE.txt" book_owner ch12_r "$CH/r_source/schema_10_table.sql" || exit 1
append "source_$SIZE.txt" book_owner ch12_r "$CH/r_source/schema_20_generate.sql"

echo "■ 3 案のテーブルとデータ"
for s in a_traverse:ch12_a b_rbac:ch12_b c_materialized:ch12_c; do
  d="${s%%:*}"; sc="${s##*:}"
  save "schema_${sc}.txt" book_owner "$sc" "$CH/$d/schema.sql" || exit 1
  append "schema_${sc}.txt" book_owner "$sc" "$CH/$d/load.sql"
  append "schema_${sc}.txt" book_owner "$sc" "$CH/$d/verify_content.sql"
done

echo "■ 読み取り: 案A の 3 つの書き方（関数 / 集合 / ltree）"
save "func_vs_set_$SIZE.txt" book_app ch12_a "$CH/a_traverse/20_read_func.sql"
append "func_vs_set_$SIZE.txt" book_app ch12_a "$CH/a_traverse/21_read_set.sql"
append "func_vs_set_$SIZE.txt" book_app ch12_a "$CH/a_traverse/22_read_ltree.sql"

echo "■ 読み取り: 案B（役割と権限を表に持つ）"
save "read_b_$SIZE.txt" book_app ch12_b "$CH/b_rbac/20_read_list.sql"

echo "■ 行レベルセキュリティ（ポリシーを付けて測り、必ず外す）"
save "rls_$SIZE.txt" book_owner ch12_a "$CH/a_traverse/30_rls_enable.sql"
append "rls_$SIZE.txt" book_app ch12_a "$CH/a_traverse/31_rls_read.sql"
append "rls_$SIZE.txt" book_app ch12_a "$CH/a_traverse/32_rls_bulk.sql"
append "rls_$SIZE.txt" book_owner ch12_a "$CH/a_traverse/39_rls_disable.sql"

echo "■ 案C の初期構築（30 秒以上かかる）"
save "matview_$SIZE.txt" book_owner ch12_c "$CH/c_materialized/15_build.sql"

echo "■ 案C の読み取り"
save "read_c_$SIZE.txt" book_app ch12_c "$CH/c_materialized/20_read_list.sql"

echo "■ サイズ（3 案の合計。データを変える実験の前に測る）"
save "sizes_$SIZE.txt" book_app ch12_a "$CH/compare/50_sizes.sql"

echo "■ 一致の検査（4 通りが同じ文書を返すこと）"
save "verify_$SIZE.txt" book_owner ch12_a "$CH/compare/90_verify.sql"

echo "■ ここから先はデータを変える"

echo "■ 変更の手数（所属の追加・プロジェクトの移動・役割の追加）"
save "change_$SIZE.txt" book_owner ch12_c "$CH/change/10_membership_change.sql"

echo "■ ズレの検出（わざとズラして検出できることを確かめる。1 回 45 秒 × 3）"
save "drift_$SIZE.txt" book_owner ch12_c "$CH/c_materialized/50_drift.sql"

echo "■ 階層の深さ（各深さ 5 回）"
save "depth_$SIZE.txt" book_owner ch12_d "$CH/d_depth/schema.sql" || exit 1
append "depth_$SIZE.txt" book_owner ch12_d "$CH/d_depth/load.sql"
append "depth_$SIZE.txt" book_app ch12_d "$CH/d_depth/20_depth.sql"

echo "■ GRANT（serial と IDENTITY の差。book_guest で 2 ファイルに分けて流す）"
save "grant_$SIZE.txt" book_owner ch12_g "$CH/g_grant/schema.sql" || exit 1
# 🔴 serial 側は**失敗するのが正しい**。成功したら権限が効いていない
append_expect_fail "grant_$SIZE.txt" book_guest ch12_g \
  "$CH/g_grant/10_serial_insert_fails.sql" "permission denied for sequence"
# IDENTITY 側は成功するのが正しい
append "grant_$SIZE.txt" book_guest ch12_g "$CH/g_grant/11_identity_insert.sql"

echo "■ 期限つきの招待と、大文字小文字を区別しない一意性"
save "overlaps_$SIZE.txt" book_owner ch12_b "$CH/b_rbac/40_time_bounded.sql"
# 🔴 41・42 も**失敗するのが正しい**。成功したら制約が効いていない
append_expect_fail "overlaps_$SIZE.txt" book_owner ch12_b \
  "$CH/b_rbac/41_overlap_fails.sql" "violates exclusion constraint"
append_expect_fail "overlaps_$SIZE.txt" book_owner ch12_b \
  "$CH/b_rbac/42_collation_fails.sql" "violates unique constraint"

echo "■ 中央値と幅を計算する"
python3 "$CH/summarize.py" "$R" "$SIZE" > "$R/summary_$SIZE.txt" 2>&1
echo "  summarize.py -> $R/summary_$SIZE.txt"

echo "■ 完了"
