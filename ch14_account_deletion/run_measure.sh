#!/usr/bin/env bash
# 第14章の測定を最初から通しで実行し、results/ に保存する。
#
#   SIZE=S bash ch14_account_deletion/run_measure.sh
#
# 🔴 SQL とコメントを直したら、必ずこれを流し直す。
#
# 🔴 必ず reset-chapter から始める。案を作り直した直後に測ると、
#    別の案の古い表が残ったまま比較される（第9章の教訓）。
#
# 🔴 実行の順序が大事:
#      元データ → 3 案 → サイズ → 一致の検査 → 個人情報の残り → 一覧の読み取り
#      → ここから先はデータを壊す → 退会 → 変更の手数 → VACUUM
#
#    - サイズと一致の検査は、データを変える実験より**前**（第10章・第11章の教訓）
#    - 退会（40_withdraw）は利用者 1・3 の行を変えるので、それより後の
#      測定ではこの利用者の値が変わる。一覧と個人情報の観測は退会より前に置く
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
CH=ch14_account_deletion
R="$CH/results"
SIZE="${SIZE:-S}"
mkdir -p "$R"

save() {  # save <出力ファイル> <ロール> <スキーマ> <SQL> [psql の追加引数...]
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
#    成功したら、制約が効いていないということなので、そこで止める。
append_expect_fail() {  # append_expect_fail <出力> <ロール> <スキーマ> <SQL> <期待する文面>
  local out="$R/$1" role="$2" schema="$3" file="$4" want="$5"
  { echo; SIZE="$SIZE" bash scripts/run-sql.sh "$role" "$schema" "$file"; } >> "$out" 2>&1
  local rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "  ❌ $file は失敗するはずなのに成功した"
    echo "     期待した文面: $want"
    return 1
  fi
  if ! tail -40 "$out" | grep -q "$want"; then
    echo "  ❌ $file は失敗したが、期待した文面が出ていない"
    echo "     期待した文面: $want"
    return 1
  fi
  echo "  $file ->> $out (rc=${rc} 期待どおり失敗)"
}

echo "■ やり直し"
bash scripts/reset-chapter.sh 14 >/dev/null 2>&1

echo "■ 元データ"
save "source_$SIZE.txt" book_owner ch14_r "$CH/r_source/schema_10_table.sql" || exit 1
append "source_$SIZE.txt" book_owner ch14_r "$CH/r_source/schema_20_generate.sql"

echo "■ 🔴 採取した案の検算（3 つとも失敗するのが正しい）"
append_expect_fail "firstidea_$SIZE.txt" book_owner ch14_x \
  "$CH/x_firstidea/10_haiku_ddl_fails.sql" 'syntax error at or near "WHERE"' || exit 1
append_expect_fail "firstidea_$SIZE.txt" book_owner ch14_x \
  "$CH/x_firstidea/20_plain_unique_fails.sql" \
  'duplicate key value violates unique constraint' || exit 1
append_expect_fail "firstidea_$SIZE.txt" book_owner ch14_x \
  "$CH/x_firstidea/30_restore_collision_fails.sql" \
  'duplicate key value violates unique constraint "x_email_active"' || exit 1

echo "■ 案A（論理削除 + 部分一意インデックス）"
save "schema_ch14_a.txt" book_owner ch14_a "$CH/a_soft/schema.sql" || exit 1
append "schema_ch14_a.txt" book_owner ch14_a "$CH/a_soft/load.sql"

echo "■ 案B（物理削除 + 復元用の控え）"
save "schema_ch14_b.txt" book_owner ch14_b "$CH/b_purge/schema.sql" || exit 1
append "schema_ch14_b.txt" book_owner ch14_b "$CH/b_purge/load.sql"

echo "■ 案C（個人情報を別のテーブルに分ける）"
save "schema_ch14_c.txt" book_owner ch14_c "$CH/c_split/schema.sql" || exit 1
append "schema_ch14_c.txt" book_owner ch14_c "$CH/c_split/load.sql"

echo "■ サイズ（データを変える実験の前に測る）"
save "sizes_$SIZE.txt" book_app ch14_a "$CH/compare/50_sizes.sql"

echo "■ 一致の検査（売上と注文とコメントが 3 案で同じ）"
save "verify_$SIZE.txt" book_owner ch14_a "$CH/compare/90_verify.sql"

echo "■ 個人情報がどこに残っているか（3 案）"
save "pii_$SIZE.txt"   book_owner ch14_a "$CH/a_soft/20_pii_leftover.sql"
append "pii_$SIZE.txt" book_owner ch14_b "$CH/b_purge/20_pii_leftover.sql"
append "pii_$SIZE.txt" book_owner ch14_c "$CH/c_split/20_pii_leftover.sql"

echo "■ 一覧の読み取り（各案 3 回）"
save "list_a_$SIZE.txt" book_app ch14_a "$CH/a_soft/30_active_list.sql"
save "list_b_$SIZE.txt" book_app ch14_b "$CH/b_purge/30_active_list.sql"
save "list_c_$SIZE.txt" book_app ch14_c "$CH/c_split/30_active_list.sql"

echo "■ 削除済みの割合ごとのインデックスのサイズ"
save "idxsize_$SIZE.txt" book_owner ch14_z "$CH/change/15_index_size_by_ratio.sql"

echo "■ 外部キーの列に索引が無いときの連鎖削除"
save "fkidx_$SIZE.txt" book_owner ch14_z "$CH/change/40_fk_index_delete.sql"

echo "■ ここから先はデータを壊す"

echo "■ 退会 1 件の処理（3 案）"
save "withdraw_a_$SIZE.txt" book_owner ch14_a "$CH/a_soft/40_withdraw.sql"
save "withdraw_b_$SIZE.txt" book_owner ch14_b "$CH/b_purge/40_withdraw.sql"
save "withdraw_c_$SIZE.txt" book_owner ch14_c "$CH/c_split/40_withdraw.sql"

echo "■ 変更の手数（個人情報の列を 1 つ足す）"
save "change_$SIZE.txt" book_owner ch14_a "$CH/change/10_add_pii_column.sql"

echo "■ 大量の物理削除のあとのサイズと VACUUM"
save "vacuum_$SIZE.txt" book_owner ch14_z "$CH/change/20_vacuum_after_purge.sql"

echo "■ NOT NULL の NOT VALID と VALIDATE のロック"
save "validate_$SIZE.txt" book_owner ch14_z "$CH/change/30_validate_lock.sql"

echo "■ 🔴 期間つき外部キーに退会の連鎖を付ける（2 つとも失敗するのが正しい）"
{ bash scripts/collect-env.sh; echo "# SIZE=$SIZE"; } > "$R/period_$SIZE.txt"
append_expect_fail "period_$SIZE.txt" book_owner ch14_z \
  "$CH/change/50_period_fk_cascade_fails.sql" \
  'unsupported ON DELETE action for foreign key constraint using PERIOD' || exit 1
append_expect_fail "period_$SIZE.txt" book_owner ch14_z \
  "$CH/change/60_period_fk_set_null_fails.sql" \
  'unsupported ON DELETE action for foreign key constraint using PERIOD' || exit 1

echo "完了: $R"
