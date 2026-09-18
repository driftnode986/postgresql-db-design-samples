#!/usr/bin/env bash
# 第3章の results/ を取り直す。スキーマを消して作り直すところから始める。
#   bash ch03_articles_and_tags/run_measure.sh            L（1,000 万記事）で測る
#   SIZE=S bash ch03_articles_and_tags/run_measure.sh     S（10 万記事）で測る
# 本文の図と数値は L を基本にする（案A の書き方の差が L ではじめて桁で開く）。
# 読者の再現手順は S（L は元データの生成に 6 分、3 案の投入に 5 分、ディスク 6GB を使う）。
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
D=ch03_articles_and_tags
R=$D/results
SIZE="${SIZE:-L}"
export SIZE
T="_$SIZE"
run()  { bash scripts/run-sql.sh "$@"; }
save() { local out="$1"; shift; { bash scripts/collect-env.sh; "$@"; } > "$R/$out" 2>&1; echo "saved $out"; }
dir_of() { case "$1" in a) echo a_junction ;; b) echo b_array ;; c) echo c_jsonb ;;
                        f) echo f_first_idea ;; r) echo r_source ;; esac; }

bash scripts/reset-chapter.sh 03

source_data() {
  run book_owner ch03_r $D/r_source/schema_10_table.sql
  run book_owner ch03_r $D/r_source/schema_20_generate.sql
  run book_app   ch03_r $D/r_source/queries/10_content.sql
}
save "source$T.txt" source_data

build() { local p="$1" d; d="$(dir_of "$p")"
  run book_owner "ch03_$p" "$D/$d/schema.sql"
  run book_owner "ch03_$p" "$D/$d/load.sql"
  run book_owner "ch03_$p" "$D/$d/verify_content.sql"
}
# 実行計画は 3 回取る（本文に載せるのは Execution Time が中央値の回）
explain3() { local p="$1" d f; d="$(dir_of "$p")"
  for f in "$D/$d"/queries/1[0-9]_*.sql; do
    for i in 1 2 3; do echo "## $(basename "$f") run $i"; run book_app "ch03_$p" "$f"; done
  done
}

for p in a b c; do save "load_${p}$T.txt" build "$p"; done
all_sizes()   { local p; for p in a b c; do echo "#### ch03_$p"; run book_app "ch03_$p" "$D/queries/90_sizes.sql"; done; }
all_explain() { local p; for p in a b c; do echo "#### ch03_$p"; explain3 "$p"; done; }
save "sizes$T.txt"   all_sizes
save "explain$T.txt" all_explain

all_stability() { local p; for p in b c; do echo "#### ch03_$p"; run book_owner "ch03_$p" "$D/$(dir_of "$p")/queries/25_estimate_stability.sql"; done; }
save "stability$T.txt" all_stability

# 「最初に思いつく案」の検算。案A とは別のスキーマ（ch03_f）で作る
first_idea() {
  run book_owner ch03_f $D/f_first_idea/schema.sql
  run book_owner ch03_f $D/f_first_idea/load.sql
  local f
  for f in "$D"/f_first_idea/queries/*.sql; do
    for i in 1 2 3; do echo "## $(basename "$f") run $i"; run book_app ch03_f "$f"; done
  done
}
save "first_idea$T.txt" first_idea

# 制約の実験（データ量に依存しないので S・L で同じ結果になる）
constraints() { local f
  for f in "$D"/constraints/*.sql; do
    echo "## $(basename "$f")"; run book_owner ch03_k "$f"
  done
}
save "constraints.txt" constraints

# GIN の作成時間（案B・案C）
gin_build() { local p; for p in b c; do echo "#### ch03_$p"; run book_owner "ch03_$p" "$D/queries/91_gin_build.sql"; done; }
save "gin_build$T.txt" gin_build

# 変更の手数。テーブルを書き換えるので ROLLBACK で戻す（各ファイルの中で閉じている）
for p in a b c; do
  d="$(dir_of "$p")"
  for f in "$D/$d"/change/*.sql; do
    save "change_${p}_$(basename "$f" .sql)$T.txt" run book_owner "ch03_$p" "$f"
  done
done
