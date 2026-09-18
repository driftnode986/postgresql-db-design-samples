#!/usr/bin/env bash
# 第4章の results/ を取り直す。スキーマを消して作り直すところから始める。
#   bash ch04_category_and_comment_tree/run_measure.sh          M（スレッド 100 万ノード）で測る
#   SIZE=S bash ch04_category_and_comment_tree/run_measure.sh   S（1 万ノード）で測る
# 本文の図と数値は M を基本にする（案の差が M ではじめて桁で開く）。
# 読者の再現手順は S（M は元データの生成に 3 秒、3 案の投入に 2 分、ディスク 1.7GB を使う）。
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
D=ch04_category_and_comment_tree
R=$D/results
SIZE="${SIZE:-M}"
export SIZE
T="_$SIZE"
run()  { bash scripts/run-sql.sh "$@"; }
save() { local out="$1"; shift; { bash scripts/collect-env.sh; "$@"; } > "$R/$out" 2>&1; echo "saved $out"; }
dir_of() { case "$1" in a) echo a_adjacency ;; b) echo b_closure ;; c) echo c_ltree ;;
                        d) echo d_cat ;; f) echo f_first_idea ;; esac; }

bash scripts/reset-chapter.sh 04

source_data() {
  run book_owner ch04_r $D/r_source/schema_10_table.sql
  run book_owner ch04_r $D/r_source/schema_20_generate.sql
  run book_app   ch04_r $D/r_source/queries/10_content.sql
}
save "source$T.txt" source_data

build() { local p="$1" d; d="$(dir_of "$p")"
  run book_owner "ch04_$p" "$D/$d/schema.sql"
  run book_owner "ch04_$p" "$D/$d/load.sql"
  run book_owner "ch04_$p" "$D/$d/verify_content.sql"
}
# 実行計画は 3 回取る（本文に載せるのは Execution Time が中央値の回）
explain3() { local p="$1" d f; d="$(dir_of "$p")"
  for f in "$D/$d"/queries/1[0-9]_*.sql; do
    # 索引を落として測るものは book_owner で実行する
    local role=book_app
    case "$(basename "$f")" in 13_*) role=book_owner ;; esac
    for i in 1 2 3; do echo "## $(basename "$f") run $i"; run "$role" "ch04_$p" "$f"; done
  done
}

for p in a b c; do save "load_${p}$T.txt" build "$p"; done
all_sizes()   { local p; for p in a b c; do echo "#### ch04_$p"; run book_app "ch04_$p" "$D/queries/90_sizes.sql"; done; }
all_explain() { local p; for p in a b c; do echo "#### ch04_$p"; explain3 "$p"; done; }
# カテゴリ型（深さ 5）でも同じ操作を測る。木が浅いと結論がどう変わるかを見る
cat_build() {
  run book_owner ch04_d $D/d_cat/schema.sql
  run book_owner ch04_d $D/d_cat/load.sql
}
cat_explain() { local f
  for f in "$D"/d_cat/queries/1[0-9]_*.sql; do
    for i in 1 2 3; do echo "## $(basename "$f") run $i"; run book_app ch04_d "$f"; done
  done
}
save "cat_load$T.txt"    cat_build
save "cat_explain$T.txt" cat_explain
save "cat_move$T.txt"    run book_owner ch04_d $D/d_cat/change/10_move_summary.sql

save "sizes$T.txt"   all_sizes
save "explain$T.txt" all_explain

# 循環の検査と、検査そのものの検証（わざと輪を作って 0 以外が返ることを確かめる）
cycle_check() {
  echo "## verify.sql（正常時は 0）"
  run book_owner ch04_a "$D/a_adjacency/verify.sql"
  echo "## 20_cycle_check_timed.sql（所要時間）"
  run book_owner ch04_a "$D/a_adjacency/queries/20_cycle_check_timed.sql"
  echo "## 20_cycle_canary.sql（輪を入れると 0 以外）"
  run book_owner ch04_a "$D/a_adjacency/change/20_cycle_canary.sql"
}
save "cycle_check$T.txt" cycle_check

# 制約の実験（データ量に依存しないので S・M で同じ結果になる）
constraints() { local f
  for f in "$D"/x_constraints/*.sql; do
    echo "## $(basename "$f")"; run book_owner ch04_x "$f"
  done
}
save "constraints.txt" constraints

# 3 案の移動を 1 つのログにまとめて測る（比較図はこのログを出典にする）
save "move_summary$T.txt" run book_owner ch04_a $D/change_move_summary.sql

# 部分木の移動。テーブルを書き換えるので ROLLBACK で戻す（各ファイルの中で閉じている）
for p in a b c; do
  d="$(dir_of "$p")"
  for f in "$D/$d"/change/[13]0_*.sql; do
    save "change_${p}_$(basename "$f" .sql)$T.txt" run book_owner "ch04_$p" "$f"
  done
done
