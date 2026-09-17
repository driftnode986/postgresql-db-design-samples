#!/usr/bin/env bash
# 第1章の results/ を取り直す。テーブルは schema_*.sql で作成済みであること。
#   bash ch01_environment/run_measure.sh          M で測る
#   WITH_L=1 bash ch01_environment/run_measure.sh  L（500 万行）の実行計画も取る
#   SKIP_BENCH=1 …                                  pgbench と extras を省く
# どの結果ファイルにも、先頭に環境の記録（collect-env.sh）を付ける。
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
D=ch01_environment
R=$D/results
run()  { bash scripts/run-sql.sh "$@"; }
save() { local out="$1"; shift; { bash scripts/collect-env.sh; "$@"; } > "$R/$out" 2>&1; echo "saved $out"; }

save settings.txt    run book_app ch01 $D/queries/01_settings.sql
rls() { run book_app ch01 $D/rls_count_app.sql; run book_owner ch01 $D/rls_count_owner.sql; }
save rls.txt rls

# データ生成を 2 回行い、内容が同じになることを確かめる（S）
twice() {
  for i in 1 2; do
    SIZE=S run book_owner ch01 $D/load_order_items.sql
    run book_app ch01 $D/queries/10_content_hash.sql
  done
}
save load_S_twice.txt twice

m_load() { SIZE=M run book_owner ch01 $D/load_order_items.sql; run book_app ch01 $D/queries/10_content_hash.sql; run book_app ch01 $D/queries/11_skew.sql; }
save load_M.txt m_load
explain() {
  for i in 1 2 3; do echo "## run $i"; run book_app ch01 $D/queries/20_explain_popular.sql; done
  for q in 21_explain_rare 22_explain_index_searches 23_explain_full 24_explain_estimate; do
    run book_app ch01 $D/queries/$q.sql
  done
}
save explain_M.txt explain
save sizes_M.txt run book_app ch01 $D/queries/30_sizes.sql

if [ "${WITH_L:-0}" = "1" ]; then
  l_explain() {
    SIZE=L run book_owner ch01 $D/load_order_items.sql
    run book_app ch01 $D/queries/30_sizes.sql
    for i in 1 2 3; do echo "## run $i"; run book_app ch01 $D/queries/23_explain_full.sql; done
  }
  save explain_L.txt l_explain
  SIZE=M run book_owner ch01 $D/load_order_items.sql > /dev/null
fi

SIZE=M run book_owner ch01 $D/load_pk_size.sql > /dev/null   # 親 20 万行を入れ直してから測る
save pk_size_M.txt run book_app ch01 $D/queries/40_pk_size.sql
save change.txt    run book_owner ch01 $D/change/01_add_columns.sql
SIZE=M run book_owner ch01 $D/load_order_items.sql > /dev/null   # 書き換えた後のテーブルを作り直す

[ "${SKIP_BENCH:-0}" = "1" ] && exit 0   # データに関係する結果だけを取り直すとき

abort() {
  docker cp $D/bench/insert_same_slot_fails.sql pgdbdesign:/tmp/insert_same_slot_fails.sql >/dev/null
  docker exec -e PGPASSWORD=book_app -e PGOPTIONS="-c search_path=ch01,public" pgdbdesign \
    pgbench -h 127.0.0.1 -U book_app -n -c 4 -j 2 -T 3 -f /tmp/insert_same_slot_fails.sql book 2>&1
}
save pgbench_abort.txt abort
bash $D/run_bench.sh > $R/reservation_bench.txt 2>&1; echo "saved reservation_bench.txt"
bash $D/extras/error_order.sh > $R/error_order.txt 2>&1; echo "saved error_order.txt"
bash $D/extras/ext_placement.sh > $R/ext_placement.txt 2>&1; echo "saved ext_placement.txt"
