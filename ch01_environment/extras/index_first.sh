#!/usr/bin/env bash
# インデックスを付けたままデータを入れると、サイズがどう変わるかを確かめる。
#   bash ch01_environment/extras/index_first.sh > ch01_environment/results/sizes_M_index_first.txt
# 確かめたあとで、通常の手順（データを入れてからインデックスを作る）で入れ直す。
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
D=ch01_environment
F="$(mktemp)"; trap 'rm -f "$F"' EXIT
# 投入スクリプトから、インデックスを消す文と作る文を除いたもの
grep -vE '^DROP INDEX|^CREATE INDEX|^  ON ch01.order_items \(product_id' $D/load_order_items.sql > "$F"
bash scripts/collect-env.sh
echo "## インデックスを付けたまま、100 万行を入れ直す"
SIZE=M bash scripts/run-sql.sh book_owner ch01 "$F" > /dev/null
bash scripts/run-sql.sh book_app ch01 $D/queries/30_sizes.sql
SIZE=M bash scripts/run-sql.sh book_owner ch01 $D/load_order_items.sql > /dev/null
