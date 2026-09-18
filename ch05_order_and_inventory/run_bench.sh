#!/usr/bin/env bash
# 第5章の同時実行の測定。
#   bash ch05_order_and_inventory/run_bench.sh > ch05_order_and_inventory/results/bench.txt
#
# 4 つを測る。
#   1. ロックを取らない案C が売り越しを出すこと（pgbench はエラー 0 と報告する）
#   2. 在庫が尽きる条件と尽きない条件で、案の順位の見え方が変わること
#   3. 1 商品への集中と、1 万商品への分散
#   4. ロックの順序をそろえた場合とそろえない場合
#
# 🔴 在庫が尽きると「売り切れ後の速い経路」を測ることになる。
#    案の比較は在庫を尽きさせない条件で行う（本文の「測る」の節で説明している）。
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
D=ch05_order_and_inventory
C="${PG_CONTAINER:-pgdbdesign}"
CLIENTS="${CLIENTS:-16}"
JOBS="${JOBS:-4}"
DURATION="${DURATION:-20}"
REPEATS="${REPEATS:-5}"

bash scripts/collect-env.sh
# 🔴 先に消す。既に /tmp/ch05_bench があると docker cp は入れ子
# （/tmp/ch05_bench/bench/…）にコピーし、pgbench が
# "could not open file" で落ちる（実際に踏んだ）
docker exec "$C" rm -rf /tmp/ch05_bench
docker cp "$D/bench" "$C:/tmp/ch05_bench" >/dev/null

sql() { bash scripts/run-sql.sh "$@"; }
tmp() { local f; f="$(mktemp)"; cat > "$f"; echo "$f"; }

bench() {  # bench <schema> <script>
  docker exec -e PGPASSWORD=book_app -e PGOPTIONS="-c search_path=$1,public" "$C" \
    pgbench -h 127.0.0.1 -U book_app -n -c "$CLIENTS" -j "$JOBS" -T "$DURATION" \
    --failures-detailed -f "/tmp/ch05_bench/$2.sql" book 2>&1 \
    | grep -vE '^pgbench \(PostgreSQL'
}

# 在庫を戻す。qty を指定した値にし、案C は引当の行を消す
reset_stock() {  # reset_stock <qty>
  sql book_owner ch05_a "$(tmp <<EOF
UPDATE ch05_a.inventory SET qty = $1;
UPDATE ch05_b.inventory SET qty = $1;
DELETE FROM ch05_c.inventory_entries WHERE reason = 'allocation';
UPDATE ch05_c.inventory_entries SET delta = $1 WHERE reason = 'receipt';
EOF
)" > /dev/null
}

deadlocks() {
  sql book_app ch05_a "$(tmp <<'EOF'
SELECT deadlocks FROM pg_stat_database WHERE datname = 'book';
EOF
)" | grep -E '^ +[0-9]+' | tr -d ' '
}

echo "###############################################################"
echo "# 0. 読んだ値を書き戻す案は、CHECK (qty >= 0) があっても売り越す"
echo "#    在庫 100 個の 1 商品に集中させる"
echo "###############################################################"
sql book_owner ch05_f "$D/f_naive/load.sql" > /dev/null
bench ch05_f f_naive_hot
echo "## 検査（oversold_rows は 0 にならない。それがこの案の欠陥）"
sql book_owner ch05_f "$D/f_naive/count_oversold.sql"

echo
echo "###############################################################"
echo "# 1. ロックを取らない案C は売り越しを出す（在庫 100 個・1 商品）"
echo "###############################################################"
reset_stock 100
bench ch05_c c_nolock_hot
echo "## 測定後の有効在庫（0 未満なら売り越し）"
sql book_app ch05_c "$(tmp <<'EOF'
SELECT qty AS available_after FROM ch05_c.available WHERE product_id = 1;
EOF
)"

echo
echo "###############################################################"
echo "# 2. 在庫 100 個（測定中に尽きる）。案B が速く見えるが、"
echo "#    これは売り切れ後の経路を測っているため"
echo "###############################################################"
# 🔴 検査は「その案の測定の直後」に流す。3 案ぶんまとめて最後に流すと、
#    次の案の前の reset_stock で前の案の結果が消える（実際にそれで
#    「引当が 1 件も起きていない」状態を売り越し 0 と読み違えた）
for k in a b c; do
  reset_stock 100
  echo "## ch05_$k"
  bench "ch05_$k" "${k}_hot"
  echo "## ch05_$k / 測定直後の検査（全行の先頭列が 0 であること）"
  sql book_owner "ch05_$k" "$D/queries/after_hot_$k.sql"
done

echo
echo "###############################################################"
echo "# 3. 在庫を尽きさせない条件（1 商品への集中）。これが案の比較"
echo "#    $REPEATS 回ずつ測り、中央値と幅を読む"
echo "###############################################################"
for run in $(seq 1 "$REPEATS"); do
  for k in a b c; do
    reset_stock 100000000
    echo "## run $run / ch05_$k / hot"
    bench "ch05_$k" "${k}_hot"
  done
done

echo
echo "###############################################################"
echo "# 4. 1 万商品への分散（random_zipfian で人気商品に偏らせる）"
echo "###############################################################"
for run in $(seq 1 "$REPEATS"); do
  for k in a b c; do
    reset_stock 100000000
    echo "## run $run / ch05_$k / spread"
    bench "ch05_$k" "${k}_spread"
  done
done

echo
echo "###############################################################"
echo "# 5. ロックの順序。そろえる / そろえない / 案B"
echo "#    デッドロックは関数の中で受けるので pgbench の出力に出ない。"
echo "#    pg_stat_database.deadlocks の増分で数える"
echo "###############################################################"
for s in a_many_sorted a_many_unsorted b_many; do
  reset_stock 100000000
  before="$(deadlocks)"
  echo "## $s"
  # そろえない側では、流している最中に待ち行列を観測する
  # （デッドロックの件数だけでは tps の落ち方を説明できないため）
  if [ "$s" = "a_many_unsorted" ]; then
    ( sleep 8; echo "## $s / 待ち行列の観測"; \
      sql book_app ch05_a "$D/queries/40_lock_waits.sql" ) &
    obs=$!
  fi
  bench ch05_a "$s"
  [ "$s" = "a_many_unsorted" ] && wait "$obs"
  after="$(deadlocks)"
  echo "deadlocks: before=$before after=$after delta=$((after - before))"
done

echo
echo "###############################################################"
echo "# 5b. deadlock_timeout を変えて、遅さの実体を確かめる"
echo "#     設計は変えず、設定だけを変える。ロック待ちそのものではなく"
echo "#     デッドロックの検出待ちが効いていることを示す"
echo "###############################################################"
# deadlock_timeout はスーパーユーザーでないと変えられないので book_admin で設定する
set_dt() {
  docker exec -e PGPASSWORD=book_admin "$C" psql -h 127.0.0.1 -U book_admin -d book -X -q \
    -c "ALTER SYSTEM SET deadlock_timeout = '$1'" -c "SELECT pg_reload_conf()" >/dev/null
}
for dt in 1s 20ms; do
  set_dt "$dt"
  reset_stock 100000000
  echo "## deadlock_timeout = $dt"
  bench ch05_a a_many_unsorted
done
set_dt 1s   # 既定に戻す（以降の測定に影響させない）
echo "## deadlock_timeout を 1s に戻した"

echo
echo "###############################################################"
echo "# 6. REPEATABLE READ のシリアライゼーション失敗"
echo "###############################################################"
reset_stock 100000000
bench ch05_b rr
