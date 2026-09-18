#!/usr/bin/env bash
# 第7章の同時実行の測定。
#   bash ch07_point_balance/run_bench.sh > ch07_point_balance/results/bench_S.txt 2>&1
#
# 測るのは、同じ 1 行（会員 1 の残高）に 16 接続から書き込んだときの
#   1. 正しさ: 残高の列が、台帳の合計と一致するか（drift）
#   2. 処理量: tps（5 回の中央値と幅）
#
# 🔴 検査は「その測定の直後」に流す。まとめて最後に流すと、次の測定の前に状態が戻されて
#    空振りを PASS と読む（第5章で実際に起きた）。
#
# 🔴 pgbench のエラー 0 件は「正しかった」を意味しない。更新の喪失はエラーを出さない。
#    判定は必ず drift の値で行う。
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
D=ch07_point_balance
C="${PG_CONTAINER:-pgdbdesign}"
CLIENTS="${CLIENTS:-16}"
JOBS="${JOBS:-4}"
DURATION="${DURATION:-20}"
REPEATS="${REPEATS:-5}"

bash scripts/collect-env.sh

# 🔴 先に消す。既にあると docker cp が入れ子にコピーし、pgbench が
#    "could not open file" で落ちる（第5章で踏んだ）
docker exec "$C" rm -rf /tmp/ch07_bench
docker cp "$D/bench" "$C:/tmp/ch07_bench" >/dev/null

psql_app() {
  docker exec -e PGPASSWORD=book_app "$C" \
    psql -h 127.0.0.1 -U book_app -d book -X -At -P pager=off "$@" | tr -d '\r'
}

bench() {  # bench <schema> <script>
  docker exec -e PGPASSWORD=book_app -e PGOPTIONS="-c search_path=$1,public" "$C" \
    pgbench -h 127.0.0.1 -U book_app -n -c "$CLIENTS" -j "$JOBS" -T "$DURATION" \
    --failures-detailed -f "/tmp/ch07_bench/$2.sql" book 2>&1 \
    | grep -vE '^pgbench \(PostgreSQL'
}

reset_f() {
  docker exec -e PGPASSWORD=book_owner "$C" \
    psql -h 127.0.0.1 -U book_owner -d book -X -At -P pager=off -c \
    "TRUNCATE ch07_f.point_txns RESTART IDENTITY;
     UPDATE ch07_f.point_balances SET balance = 0 WHERE user_id = 1;" >/dev/null
}

# 残高の列と台帳の合計の差。0 が正しい
drift() {
  psql_app -c "SELECT
      (SELECT balance FROM ch07_f.point_balances WHERE user_id = 1) AS balance,
      (SELECT coalesce(sum(amount),0) FROM ch07_f.point_txns WHERE user_id = 1) AS ledger,
      (SELECT coalesce(sum(amount),0) FROM ch07_f.point_txns WHERE user_id = 1)
      - (SELECT balance FROM ch07_f.point_balances WHERE user_id = 1) AS drift"
}

for m in naive forupdate in_db; do
  for i in $(seq 1 "$REPEATS"); do
    echo "## run $i / ch07_f / $m"
    reset_f
    bench ch07_f "f_$m"
    # 🔴 この測定の直後に検査する
    echo "-- 検査（balance|ledger|drift。drift が 0 なら残高と台帳が一致）"
    drift
  done
done

echo "done."
