#!/usr/bin/env bash
# 予約の 2 つの方式を、同じ条件で 5 回ずつ測る。
#   bash ch01_environment/run_bench.sh > ch01_environment/results/reservation_bench.txt
# 各回の前にテーブルを空にし、測定のあとに重なった予約の組を数える。
# 測定の順序は固定（毎回 book_check のあとに book_excl）。
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
C="${PG_CONTAINER:-pgdbdesign}"
bash scripts/collect-env.sh
docker cp ch01_environment/bench "$C:/tmp/ch01_bench" >/dev/null
for run in 1 2 3 4 5; do
  docker exec -e PGPASSWORD=book_owner "$C" psql -h 127.0.0.1 -U book_owner -d book -X -q \
    -c "TRUNCATE ch01.resv_check, ch01.resv_excl"
  for script in book_check book_excl; do
    echo "## run $run / $script"
    docker exec -e PGPASSWORD=book_app -e PGOPTIONS="-c search_path=ch01,public" "$C" \
      pgbench -h 127.0.0.1 -U book_app -n -c 16 -j 4 -T 20 --failures-detailed \
      -f "/tmp/ch01_bench/$script.sql" book 2>&1 | grep -v '^pgbench (PostgreSQL)'
  done
  echo "## run $run / overlaps"
  # 検査は book_owner で行う（行レベルセキュリティのあるテーブルでも全部の行を数えるための規約）
  bash scripts/run-sql.sh book_owner ch01 ch01_environment/queries/count_overlaps.sql | tail -4
done
