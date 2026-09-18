#!/usr/bin/env bash
# 第6章の同時実行の測定。
#   bash ch06_reservation/run_bench.sh > ch06_reservation/results/bench_M.txt 2>&1
#
# 測るのは 3 つ。
#   1. 検算の対象（FOR UPDATE で確認してから INSERT）が重複予約を作ること。
#      pgbench はエラー 0 と報告するので、測定後の検査クエリでしか分からない
#   2. 正しい 4 案の処理量（5 回ずつ測り、中央値と幅を読む）
#   3. 例外を関数の中で捕まえる形と、アプリ側で捕まえる形の差
#
# 🔴 枠が測定中に埋まり切らないようにしてある（bench/*.sql の日付方向の広がり）。
#    埋まり切ると「違反を返す速さ」の測定になり、案の比較にならない。
#    測定のたびに 2 月以降の行を消して、同じ条件から始める。
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
D=ch06_reservation
C="${PG_CONTAINER:-pgdbdesign}"
CLIENTS="${CLIENTS:-16}"
JOBS="${JOBS:-4}"
DURATION="${DURATION:-20}"
REPEATS="${REPEATS:-5}"

bash scripts/collect-env.sh
# 🔴 先に消す。既に /tmp/ch06_bench があると docker cp は入れ子にコピーし、
#    pgbench が "could not open file" で落ちる（第5章で実際に踏んだ）
docker exec "$C" rm -rf /tmp/ch06_bench
docker cp "$D/bench" "$C:/tmp/ch06_bench" >/dev/null

sql() { bash scripts/run-sql.sh "$@"; }
tmp() { local f; f="$(mktemp)"; cat > "$f"; echo "$f"; }

bench() {  # bench <schema> <script>
  docker exec -e PGPASSWORD=book_app -e PGOPTIONS="-c search_path=$1,public" "$C" \
    pgbench -h 127.0.0.1 -U book_app -n -c "$CLIENTS" -j "$JOBS" -T "$DURATION" \
    --failures-detailed -f "/tmp/ch06_bench/$2.sql" book 2>&1 \
    | grep -vE '^pgbench \(PostgreSQL'
}

# 測定で入れた行を消し、元データだけの状態に戻す（2 月以降が測定で入った行）
reset_feb() {
  sql book_owner ch06_b "$(tmp <<'EOF'
DELETE FROM ch06_b.reservations WHERE start_at   >= timestamptz '2026-02-01 00:00+09';
DELETE FROM ch06_c.reservations WHERE lower(period) >= timestamptz '2026-02-01 00:00+09';
DELETE FROM ch06_d.reservations WHERE lower(period) >= timestamptz '2026-02-01 00:00+09';
DELETE FROM ch06_f.reservations WHERE start_at   >= timestamptz '2026-02-01 00:00+09';
DELETE FROM ch06_e.reservations WHERE id IN (
  SELECT reservation_id FROM ch06_e.reservation_slots
   WHERE slot_start >= timestamptz '2026-02-01 00:00+09');
DELETE FROM ch06_e.reservation_slots WHERE slot_start >= timestamptz '2026-02-01 00:00+09';
EOF
)" > /dev/null
}

deadlocks() {
  sql book_app ch06_b "$(tmp <<'EOF'
SELECT deadlocks FROM pg_stat_database WHERE datname = 'book';
EOF
)" | grep -E '^ +[0-9]+' | tr -d ' '
}

echo "###############################################################"
echo "# 1. 検算の対象: FOR UPDATE で確認してから INSERT する案"
echo "#    pgbench はエラー 0 と報告する。重複は測定後の検査でしか分からない"
echo "###############################################################"
reset_feb
bench ch06_f f_hot
echo "## 測定直後の検査（overlapping_pairs は 0 にならない。それがこの案の欠陥）"
sql book_owner ch06_f "$D/f_forupdate/count_overlaps.sql"

echo
echo "###############################################################"
echo "# 2. 正しい 4 案の処理量。$REPEATS 回ずつ測り、中央値と幅を読む"
echo "#    b=2列+EXCLUDE  c=範囲型+EXCLUDE  d=WITHOUT OVERLAPS  e=枠の行+UNIQUE"
echo "###############################################################"
for run in $(seq 1 "$REPEATS"); do
  for k in b c d e; do
    reset_feb
    before="$(deadlocks)"
    echo "## run $run / ch06_$k"
    bench "ch06_$k" "${k}_hot"
    after="$(deadlocks)"
    echo "deadlocks: before=$before after=$after delta=$((after - before))"
  done
done

echo
echo "###############################################################"
echo "# 3. 測定直後の検査。4 案とも全行の先頭列が 0 であること"
echo "###############################################################"
for p in b:b_exclude2col c:c_exclude_range d:d_without_overlaps e:e_slot; do
  k="${p%%:*}"; d="${p##*:}"
  echo "## ch06_$k"
  sql book_owner "ch06_$k" "$D/$d/verify.sql"
done
