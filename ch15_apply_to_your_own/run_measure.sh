#!/usr/bin/env bash
# 第15章の実行例を最初から通しで実行し、results/ に保存する。
#
#   bash ch15_apply_to_your_own/run_measure.sh
#
# この章は案どうしの比較をしない。本文に載せる実行例（衝突の再現・18 の変更手順）の出力を取る。
# データ量は固定で、SIZE は使わない。
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
CH=ch15_apply_to_your_own
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
bash scripts/reset-chapter.sh 15 >/dev/null 2>&1

echo "■ 衝突1: 追記のみの履歴と個人情報の削除"
save history_a.txt book_owner ch15_a $CH/a_history/schema.sql
append history_a.txt book_owner ch15_a $CH/a_history/load.sql
append history_a.txt book_owner ch15_a $CH/a_history/20_withdraw.sql
append_expect_fail history_a.txt book_owner ch15_a $CH/a_history/30_erase_history_fails.sql 'append-only' || exit 1
append history_a.txt book_app ch15_a $CH/a_history/40_pii_left.sql
save history_b.txt book_owner ch15_b $CH/b_split/schema.sql
append history_b.txt book_owner ch15_b $CH/b_split/load.sql
append history_b.txt book_owner ch15_b $CH/b_split/20_withdraw.sql
append history_b.txt book_owner ch15_b $CH/b_split/verify_pii.sql

echo "■ 衝突3: 期間つき外部キー"
save period.txt book_owner ch15_c $CH/c_period/schema.sql
append period.txt book_owner ch15_c $CH/c_period/load.sql
append_expect_fail period.txt book_owner ch15_c $CH/c_period/20_shrink_fails.sql 'violates foreign key constraint' || exit 1
append_expect_fail period.txt book_owner ch15_c $CH/c_period/30_restrict_fails.sql 'unsupported ON DELETE action' || exit 1
append period.txt book_owner ch15_c $CH/c_period/40_delete_child_first.sql

echo "■ NOT NULL の NOT VALID"
save notnull.txt book_owner ch15_d $CH/d_notnull/schema.sql
append notnull.txt book_owner ch15_d $CH/d_notnull/load.sql
append notnull.txt book_owner ch15_d $CH/d_notnull/10_add_not_valid.sql
append_expect_fail notnull.txt book_owner ch15_d $CH/d_notnull/20_insert_null_fails.sql 'violates not-null constraint' || exit 1
append_expect_fail notnull.txt book_owner ch15_d $CH/d_notnull/30_validate_fails.sql 'contains null values' || exit 1
append notnull.txt book_app ch15_d $CH/d_notnull/40_find_nulls.sql
append notnull.txt book_owner ch15_d $CH/d_notnull/50_fill_and_validate.sql
append notnull.txt book_app ch15_d $CH/d_notnull/60_find_nulls_after.sql

echo "■ NOT ENFORCED"
save enforced.txt book_owner ch15_e $CH/e_enforced/schema.sql
append enforced.txt book_owner ch15_e $CH/e_enforced/load.sql
append enforced.txt book_owner ch15_e $CH/e_enforced/20_bulk_insert.sql
append enforced.txt book_owner ch15_e $CH/e_enforced/30_accepts_violation.sql
append_expect_fail enforced.txt book_owner ch15_e $CH/e_enforced/40_fk_enforce_fails.sql 'violates foreign key constraint' || exit 1
append_expect_fail enforced.txt book_owner ch15_e $CH/e_enforced/50_check_enforce_fails.sql 'cannot alter enforceability' || exit 1
append enforced.txt book_owner ch15_e $CH/e_enforced/60_fk_enforce.sql
append enforced.txt book_owner ch15_e $CH/e_enforced/70_enforce_locks.sql

echo "■ 欠番のない連番"
save serial.txt book_owner ch15_f $CH/f_serial/schema.sql
append serial.txt book_owner ch15_f $CH/f_serial/load.sql
append serial.txt book_app ch15_f $CH/f_serial/20_gap.sql
