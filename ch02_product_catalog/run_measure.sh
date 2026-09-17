#!/usr/bin/env bash
# 第2章の results/ を取り直す。スキーマを消して作り直すところから始める。
#   bash ch02_product_catalog/run_measure.sh            M（100 万商品）で測る。案D（EAV）だけは S
#   SIZE=S bash ch02_product_catalog/run_measure.sh     S（10 万商品）で測る
# どの結果ファイルにも、先頭に環境の記録（collect-env.sh）を付ける。
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
D=ch02_product_catalog
R=$D/results
SIZE="${SIZE:-M}"
export SIZE
T="_$SIZE"
run()  { bash scripts/run-sql.sh "$@"; }
save() { local out="$1"; shift; { bash scripts/collect-env.sh; "$@"; } > "$R/$out" 2>&1; echo "saved $out"; }
dir_of() { case "$1" in a) echo a_columns ;; b) echo b_jsonb ;; c) echo c_child_tables ;;
                        d) echo d_eav ;; r) echo r_source ;; esac; }

bash scripts/reset-chapter.sh 02

source_data() {
  run book_owner ch02_r $D/r_source/schema_10_table.sql
  run book_owner ch02_r $D/r_source/schema_20_generate.sql
  run book_app   ch02_r $D/r_source/queries/10_content.sql
}
save "source$T.txt" source_data

build() { local p="$1" d; d="$(dir_of "$p")"
  run book_owner "ch02_$p" "$D/$d/schema.sql"
  run book_owner "ch02_$p" "$D/$d/load.sql"
}
# 実行計画は 3 回取る（本文に載せるのは Execution Time が中央値の回）
explain3() { local p="$1" d f; d="$(dir_of "$p")"
  for f in "$D/$d"/queries/1[0-9]_*.sql; do
    for i in 1 2 3; do echo "## $(basename "$f") run $i"; run book_app "ch02_$p" "$f"; done
  done
  for f in "$D/$d"/queries/2[01]_*.sql; do run book_app "ch02_$p" "$f"; done
}

# 案A〜C の結果は 1 つのファイルにまとめる（比較図が、1 つの測定ログから数値を取るため）
for p in a b c; do save "load_${p}$T.txt" build "$p"; done
all_sizes()   { local p; for p in a b c; do echo "#### ch02_$p"; run book_app "ch02_$p" "$D/queries/90_sizes.sql"; done; }
all_explain() { local p; for p in a b c; do echo "#### ch02_$p"; explain3 "$p"; done; }
save "sizes$T.txt"   all_sizes
save "explain$T.txt" all_explain
all_stability() { local p; for p in a b c; do echo "#### ch02_$p"; run book_owner "ch02_$p" "$D/$(dir_of "$p")/queries/25_estimate_stability.sql"; done; }
save "stability$T.txt" all_stability
save "statistics_a$T.txt" run book_owner ch02_a $D/a_columns/queries/30_extended_statistics.sql
save "statistics_b$T.txt" run book_owner ch02_b $D/b_jsonb/queries/30_extended_statistics.sql
save "copy_created_at_c$T.txt" run book_owner ch02_c $D/c_child_tables/queries/40_copy_created_at.sql
save "gin_sizes$T.txt"    run book_owner ch02_b $D/b_jsonb/queries/40_gin_sizes.sql

generated() {
  for f in "$D"/b_jsonb/gen/0*.sql; do run book_owner ch02_b "$f"; done
  for f in "$D"/b_jsonb/gen/[12]*.sql; do run book_app ch02_b "$f"; done
}
save "generated_and_checks$T.txt" generated
save "first_idea_check.txt" run book_owner ch02_c $D/c_child_tables/first_idea_check_subquery_fails.sql

# WAL の量と変更の手数は、テーブルを書き換える。案ごとに、測ったらデータを入れ直す
for p in a b c; do
  d="$(dir_of "$p")"
  save "wal_${p}$T.txt"    run book_owner "ch02_$p" "$D/$d/change/10_wal_update.sql"
  run book_owner "ch02_$p" "$D/$d/load.sql" > /dev/null
  save "change_${p}$T.txt" run book_owner "ch02_$p" "$D/$d/change/01_add_attribute.sql"
  run book_owner "ch02_$p" "$D/$d/load.sql" > /dev/null
done
save "extract_b$T.txt" run book_owner ch02_b $D/b_jsonb/change/02_extract_to_column.sql
run book_owner ch02_b $D/b_jsonb/load.sql > /dev/null

# 参考の案D（EAV）は S だけで測る。元データを S で作り直すので、最後に行う
eav() {
  SIZE=S run book_owner ch02_r $D/r_source/schema_20_generate.sql
  SIZE=S build d
  SIZE=S run book_app ch02_d "$D/queries/90_sizes.sql"
  SIZE=S explain3 d
}
save "eav_S.txt" eav
