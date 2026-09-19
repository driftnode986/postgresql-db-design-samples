#!/usr/bin/env bash
# 集計行への更新の集中を測る。この章の最重要の測定。
#
#   bash ch11_sales_dashboard/run_bench.sh
#
# 🔴 規約（docs/measurement-rules.yml）: -n -c 16 -j 4 -T 20 --failures-detailed を 5 回。
#    中央値と (最大-最小)/中央値 を記録する。振れ幅より小さい差は主張しない。
#
# 🔴 failed transactions: 0 を合否の判定に使わない（第1章の規約）。
#    正しさは verify.sql で見る。
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
CH=ch11_sales_dashboard
REPEAT="${REPEAT:-5}"

bench() {  # bench <名前> <スクリプト>
  echo "=== $1 ==="
  for i in $(seq 1 "$REPEAT"); do
    docker exec -i pgdbdesign pgbench -U book_app -d book \
      -n -c 16 -j 4 -T 20 --failures-detailed \
      -f "/bench/$2" 2>&1 \
      | grep -E "^tps|number of failed|number of deadlock|number of serialization" \
      | sed "s/^/  [$i] /"
  done
  echo
}

# pgbench のスクリプトをコンテナへ渡す
docker exec pgdbdesign mkdir -p /bench
for f in "$CH"/bench/*.sql; do
  docker cp "$f" "pgdbdesign:/bench/$(basename "$f")" >/dev/null
done

bash scripts/collect-env.sh
echo

bench "集計を更新しない（基準）"                 no_summary.sql
bench "集計あり・商品が散る（1,000 商品）"       spread.sql
bench "集計あり・1 商品に集中"                   hot.sql
bench "集計あり・1 商品に集中・集計行を 16 分割" hot_sharded.sql
