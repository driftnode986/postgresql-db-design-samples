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
dir_of() { case "$1" in b) echo b_exclude2col ;; c) echo c_exclude_range ;;
                        d) echo d_without_overlaps ;; e) echo e_slot ;;
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
for p in b c d e f; do save "load_${p}$T.txt" build "$p"; done

# 1 接続では、検算の対象の案も要件どおりに動く
save "single_connection$T.txt" run book_owner ch06_f $D/queries/10_single_connection.sql

# 18 の機能の確認（WITHOUT OVERLAPS に WHERE が付かない・空の範囲の扱いの違い）
save "pg18_features$T.txt" run book_owner ch06_d $D/queries/20_pg18_features.sql

# 保存サイズ。🔴 load 直後に測る（同時実行の測定のあとだと不要になった行が残る）
save "sizes$T.txt" run book_app ch06_b $D/queries/90_sizes.sql

# 空き時間の検索（range_agg と multirange の差）
save "find_free$T.txt" run book_owner ch06_c $D/queries/30_find_free.sql

# 制約のインデックスは「探す」ためには使われない。検索用の B-tree を足した前後を測る
save "search_index$T.txt" run book_owner ch06_c $D/queries/40_search_index.sql

# 変更の手数（2 列の案B を範囲型の案C へ移す）。ROLLBACK で終わる
save "change_b_to_c$T.txt" run book_owner ch06_b $D/change/10_b_to_c.sql

echo "done. 同時実行の測定は run_bench.sh で取る"
