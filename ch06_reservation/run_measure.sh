#!/usr/bin/env bash
# 第6章の results/ を取り直す。スキーマを消して作り直すところから始める。
#   bash ch06_reservation/run_measure.sh          M（10,000 部屋）で測る
#   SIZE=S bash ch06_reservation/run_measure.sh   S（1,000 部屋）で測る
#
# この章は同時実行を測るので、pgbench の測定は run_bench.sh に分けてある。
# こちらは構築・単一接続での振る舞い・機能の違い・保存サイズ・空き時間の検索を取る。
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
D=ch06_reservation
R=$D/results
SIZE="${SIZE:-M}"
export SIZE
T="_$SIZE"
run()  { bash scripts/run-sql.sh "$@"; }
save() { local out="$1"; shift; { bash scripts/collect-env.sh; "$@"; } > "$R/$out" 2>&1; echo "saved $out"; }
dir_of() { case "$1" in a) echo a_exclude2col ;; b) echo b_exclude_range ;;
                        c) echo c_without_overlaps ;; d) echo d_slot ;;
                        f) echo f_forupdate ;; esac; }

bash scripts/reset-chapter.sh 06

source_data() {
  run book_owner ch06_r $D/r_source/schema_10_table.sql
  run book_owner ch06_r $D/r_source/schema_20_generate.sql
}
save "source$T.txt" source_data

build() { local p="$1" d; d="$(dir_of "$p")"
  run book_owner "ch06_$p" "$D/$d/schema.sql"
  run book_owner "ch06_$p" "$D/$d/schema_50_function.sql"
  run book_owner "ch06_$p" "$D/$d/load.sql"
  [ -f "$D/$d/verify.sql" ] && run book_owner "ch06_$p" "$D/$d/verify.sql"
}
for p in a b c d f; do save "load_${p}$T.txt" build "$p"; done

# 1 接続では、検算の対象の案も要件どおりに動く
save "single_connection$T.txt" run book_owner ch06_f $D/queries/10_single_connection.sql

# 18 の機能の確認（WITHOUT OVERLAPS に WHERE が付かない・空の範囲の扱いの違い）
save "pg18_features$T.txt" run book_owner ch06_c $D/queries/20_pg18_features.sql

# WITHOUT OVERLAPS に WHERE は付けられない（構文エラーで終わるのが期待どおり）。
# 本文はこのエラー文をそのまま引くので、ログとして残す
save "where_fails$T.txt" run book_owner ch06_c $D/c_without_overlaps/20_where_fails.sql

# 保存サイズ。🔴 load 直後に測る（同時実行の測定のあとだと不要になった行が残る）
save "sizes$T.txt" run book_app ch06_a $D/queries/90_sizes.sql

# 空き時間の検索（range_agg と multirange の差）
save "find_free$T.txt" run book_owner ch06_b $D/queries/30_find_free.sql

# 制約のインデックスは「探す」ためには使われない。検索用の B-tree を足した前後を測る
save "search_index$T.txt" run book_owner ch06_b $D/queries/40_search_index.sql

# 変更の手数（2 列の案B を範囲型の案C へ移す）。ROLLBACK で終わる
save "change_a_to_b$T.txt" run book_owner ch06_a $D/change/10_a_to_b.sql

# 排他制約は NOT VALID で足せない（止めずに移す逃げ道が無いことの確認）。
# エラーで終わるのが期待どおりなので、save の戻り値は見ない
save "lock_modes$T.txt" run book_owner ch06_a $D/change/30_lock_modes.sql

# 排他制約は NOT VALID で足せない
save "not_valid$T.txt" run book_owner ch06_a $D/change/20_not_valid_fails.sql

echo "done. 同時実行の測定は run_bench.sh で取る"
