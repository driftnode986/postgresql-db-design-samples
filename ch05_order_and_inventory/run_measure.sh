#!/usr/bin/env bash
# 第5章の results/ を取り直す。スキーマを消して作り直すところから始める。
#   bash ch05_order_and_inventory/run_measure.sh          M（10,000 商品）で測る
#   SIZE=S bash ch05_order_and_inventory/run_measure.sh   S（1,000 商品）で測る
#
# この章は同時実行を測るので、pgbench の測定は run_bench.sh に分けてある。
# こちらは構築・単一接続での振る舞い・案C の集計の伸び方を取る。
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
D=ch05_order_and_inventory
R=$D/results
SIZE="${SIZE:-M}"
export SIZE
T="_$SIZE"
run()  { bash scripts/run-sql.sh "$@"; }
save() { local out="$1"; shift; { bash scripts/collect-env.sh; "$@"; } > "$R/$out" 2>&1; echo "saved $out"; }
dir_of() { case "$1" in a) echo a_forupdate ;; b) echo b_condupdate ;; c) echo c_ledger ;;
                        f) echo f_naive ;; esac; }

TMPD="$(mktemp -d)"; trap 'rm -rf "$TMPD"' EXIT
bash scripts/reset-chapter.sh 05

source_data() {
  run book_owner ch05_r $D/r_source/schema_10_table.sql
  run book_owner ch05_r $D/r_source/schema_20_generate.sql
}
save "source$T.txt" source_data

build() { local p="$1" d; d="$(dir_of "$p")"
  run book_owner "ch05_$p" "$D/$d/schema.sql"
  run book_owner "ch05_$p" "$D/$d/schema_50_function.sql"
  run book_owner "ch05_$p" "$D/$d/load.sql"
  run book_owner "ch05_$p" "$D/$d/verify_content.sql"
}
for p in a b c; do save "load_${p}$T.txt" build "$p"; done
# 保存サイズ。🔴 load 直後に測る（同時実行の測定のあとだと、不要になった行が残って
# 数倍に膨らむ。実測で案A が 0.8 MB → 3.1 MB になった）。
# 🔴 ledger_scale（商品 1 に引当を 10 万行積む）より前に置く。以前はこの行が末尾にあり、
#    案C のサイズを 11 万行の状態で測って「入れた直後」と書いていた（2026-09-26 最終レビューで検出）
save "sizes$T.txt" run book_app ch05_a $D/queries/90_sizes.sql

# 検算用（読んだ値を書き戻す案）。verify_content は無く、載せるのは verify.sql のほう
build_naive() {
  run book_owner ch05_f "$D/f_naive/schema.sql"
  run book_owner ch05_f "$D/f_naive/load.sql"
}
save "load_f$T.txt" build_naive

# 単一接続では 3 案の区別が付かないことを示す
save "single_connection$T.txt" run book_app ch05_a $D/queries/10_single_connection.sql

# 機能の確認（MERGE は 17、RETURNING old/new は 18、SKIP LOCKED）
# スキーマはここで作る（問い合わせ側に CREATE SCHEMA を持たせると、
# database への CREATE 権限が無い環境で流せなくなる）
features() {
  printf 'CREATE SCHEMA IF NOT EXISTS ch05_x;\n' > "$TMPD/mk_x.sql"
  run book_owner public "$TMPD/mk_x.sql"
  run book_owner ch05_x $D/queries/20_pg18_features.sql
}
save "pg18_features$T.txt" features

# 案C の集計が、その商品の履歴の長さに比例すること
save "ledger_scale$T.txt" run book_owner ch05_c $D/queries/30_ledger_scale.sql

# 変更の手数（案B → 案C の移行）。ROLLBACK で終わるのでサイズは変わらない
save "change_b_to_c$T.txt" run book_owner ch05_b $D/change/10_b_to_c.sql


echo "done. 同時実行の測定は run_bench.sh で取る"
