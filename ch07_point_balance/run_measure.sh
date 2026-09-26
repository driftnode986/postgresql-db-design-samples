#!/usr/bin/env bash
# 第7章の results/ を取り直す。スキーマを消して作り直すところから始める。
#   bash ch07_point_balance/run_measure.sh          S（会員 1,000・取引 101,000）で測る
#   SIZE=M bash ch07_point_balance/run_measure.sh   M（会員 10,000・取引 1,001,000）で測る
#
# 同時実行の測定は run_bench.sh に分けてある。
# こちらは構築・残高照会の実行計画・消し込みの順序・不足時の挙動・保存サイズを取る。
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
D=ch07_point_balance
R=$D/results
SIZE="${SIZE:-S}"
export SIZE
T="_$SIZE"
run()  { bash scripts/run-sql.sh "$@" -v size="$SIZE"; }
save() { local out="$1"; shift; { bash scripts/collect-env.sh; "$@"; } > "$R/$out" 2>&1; echo "saved $out"; }
dir_of() { case "$1" in a) echo a_lots ;; b) echo b_balance ;;
                        c) echo c_sum ;; d) echo d_snapshot ;; f) echo f_rmw ;; esac; }

bash scripts/reset-chapter.sh 07

source_data() {
  run book_owner ch07_r $D/r_source/schema_10_table.sql
  run book_owner ch07_r $D/r_source/schema_20_generate.sql
}
save "source$T.txt" source_data

# 案を作り、元データを写す。
# 🔴 案A・案B は写したあとに利用を消し込む（load_20_consume.sql）。
#    これをやらないとロットが付与したままになり、案C と残高が食い違う
build() { local p="$1" d; d="$(dir_of "$p")"
  run book_owner "ch07_$p" "$D/$d/schema.sql"
  [ -f "$D/$d/schema_50_function.sql" ] && run book_owner "ch07_$p" "$D/$d/schema_50_function.sql"
  run book_owner "ch07_$p" "$D/$d/load.sql"
  [ -f "$D/$d/load_20_consume.sql" ] && run book_owner "ch07_$p" "$D/$d/load_20_consume.sql"
  [ -f "$D/$d/verify.sql" ] && run book_owner "ch07_$p" "$D/$d/verify.sql"
  return 0
}
for p in a b c d f; do save "load_${p}$T.txt" build "$p"; done

# 4 案が同じ残高を返すか。🔴 案A だけが期限切れを自動で落とすので、差が出る
save "balance_agreement$T.txt" run book_app ch07_a $D/queries/05_balance_agreement.sql

# 残高照会の実行計画。時間ではなく、ノードの種類と読んだページ数を読む
save "balance_plans$T.txt" run book_app ch07_a $D/queries/10_balance_plans.sql

# 消し込みの順序（付与の古い順と、期限の近い順の違い）
save "fefo_vs_fifo$T.txt" run book_app ch07_a $D/queries/20_fefo_vs_fifo.sql

# 残高が足りないとき、検査を持たない消し込みはエラーにならない
save "shortage$T.txt" run book_owner ch07_a $D/a_lots/30_shortage.sql

# 保存サイズ。🔴 消し込みのあとに測る（案の構築直後に測ると案A・案B のロットが満額のまま）
save "sizes$T.txt" run book_app ch07_a $D/queries/90_sizes.sql

# 変更の手数（案A に残高の列を足して案B の形にする）。ROLLBACK で終わる
save "change_a_to_b$T.txt" run book_owner ch07_a $D/change/10_a_to_b.sql
# 検算が、期限切れを含めた誤った移行を見つけられるか（canary）
save "change_canary$T.txt" run book_owner ch07_a $D/change/11_a_to_b_expired_included.sql

echo "done. 同時実行の測定は run_bench.sh で取る"
