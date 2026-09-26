#!/usr/bin/env bash
# 第8章の測定を最初から通しで実行し、results/ に保存する。
#
#   SIZE=S bash ch08_subscription_pricing_and_billing/run_measure.sh
#
# 🔴 SQL とコメントを直したら、必ずこれを流し直す。
#    本文の数値は docs/chapter-src/values_ch08.py がここの出力から求めるので、
#    ログが古いまま本文を組み立てると、実測と本文が食い違う。
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
CH=ch08_subscription_pricing_and_billing
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
bash scripts/reset-chapter.sh 08 >/dev/null 2>&1

echo "■ 元データ"
save "source_$SIZE.txt" book_owner ch08_r "$CH/r_source/schema_10_table.sql" || exit 1
{ bash scripts/collect-env.sh; echo "# SIZE=$SIZE"; echo
  SIZE="$SIZE" bash scripts/run-sql.sh book_owner ch08_r "$CH/r_source/schema_20_generate.sql"; } \
  >> "$R/source_$SIZE.txt" 2>&1 || exit 1

echo "■ 採取された案の反例（UNIQUE では重なりが止まらない）"
save "schema_ch08_x.txt" book_owner ch08_x "$CH/x_first_idea/schema.sql" || exit 1
save "first_idea_$SIZE.txt" book_owner ch08_x "$CH/x_first_idea/load.sql" || exit 1

echo "■ 4 案のテーブルとデータ"
for s in a_overwrite:ch08_a b_snapshot:ch08_b c_temporal:ch08_c d_both:ch08_d; do
  d="${s%%:*}"; sc="${s##*:}"
  save "schema_${sc}.txt" book_owner "$sc" "$CH/$d/schema.sql" || exit 1
  save "load_${sc}_$SIZE.txt" book_owner "$sc" "$CH/$d/load.sql" || exit 1
done

echo "■ 4 月分の発行"
save "issue_$SIZE.txt" book_owner ch08_r "$CH/r_source/40_issue_april.sql" || exit 1

echo "■ 案C の改定を、検査を遅らせずに流す（どちらの順序でも失敗するのが正しい）"
# 🔴 失敗しなければ止める。本文の「1 文目で止まる」「順序を入れ替えると主キーに弾かれる」の根拠
#    （2026-09-26 最終レビュー: 以前は実行したログが無かった）
save "revise_fails_$SIZE.txt" book_owner ch08_c "$CH/c_temporal/45_revise_close_first_fails.sql" \
  && { echo "❌ 45 が成功した"; exit 1; }
grep -q 'violates foreign key constraint' "$R/revise_fails_$SIZE.txt" || { echo "❌ 45 の失敗理由が違う"; exit 1; }
{ echo; SIZE="$SIZE" bash scripts/run-sql.sh book_owner ch08_c "$CH/c_temporal/46_revise_insert_first_fails.sql"; } \
  >> "$R/revise_fails_$SIZE.txt" 2>&1 && { echo "❌ 46 が成功した"; exit 1; }
grep -q 'conflicting key value violates exclusion constraint' "$R/revise_fails_$SIZE.txt" || { echo "❌ 46 の失敗理由が違う"; exit 1; }

echo "■ 改定して再発行し、差額を出す"
save "revise_$SIZE.txt" book_owner ch08_r "$CH/r_source/50_revise_and_reissue.sql" || exit 1

echo "■ サイズと実行計画（3 回）"
{ bash scripts/collect-env.sh; echo "# SIZE=$SIZE"; echo; } > "$R/sizes_$SIZE.txt"
for n in 1 2 3; do
  echo "## 40_sizes_and_plan.sql run $n" >> "$R/sizes_$SIZE.txt"
  SIZE="$SIZE" bash scripts/run-sql.sh book_app ch08_b \
    "$CH/queries/40_sizes_and_plan.sql" >> "$R/sizes_$SIZE.txt" 2>&1
done
echo "  40_sizes_and_plan.sql -> $R/sizes_$SIZE.txt"

echo "■ 消費税の端数処理"
save "tax_$SIZE.txt" book_app ch08_b "$CH/queries/30_tax_rounding.sql" || exit 1

echo "■ 検査（すべて先頭列が 0 で正常）"
save "verify_$SIZE.txt" book_owner ch08_r "$CH/r_source/90_verify.sql"

echo "完了。SIZE=$SIZE の結果は $R/ にある。"
