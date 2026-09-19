#!/usr/bin/env bash
# REFRESH の最中に読み取りがどれだけ待たされるかを測る。
#
#   bash ch11_sales_dashboard/make_refresh_wait.sh
#
# 🔴 1 つの psql セッションでは測れない。REFRESH を背景で流しながら、
#    別の接続で SELECT を投げて、その SELECT にかかった時間を見る。
#
# 🔴 CONCURRENTLY の有無で「速さ」を比べるのではない。
#    比べるのは「読み手が待たされるかどうか」である
#    （REFRESH 自体は CONCURRENTLY のほうが遅い。それは代償であって欠点ではない）。
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
N="${N:-4}"

psql_owner() { docker exec -i pgdbdesign psql -U book_owner -d book -X -At -P pager=off -c "$1"; }
psql_app()   { docker exec -i pgdbdesign psql -U book_app   -d book -X -At -P pager=off -c "$1"; }

echo "# REFRESH 中の読み取りの待ち時間"
echo "# 各パターン ${N} 回。背景で REFRESH を流し、0.25 秒後に SELECT count(*) を投げる。"
echo

for mode in plain concurrently; do
  if [ "$mode" = plain ]; then
    REF="REFRESH MATERIALIZED VIEW ch11_b.daily_sales;"
  else
    REF="REFRESH MATERIALIZED VIEW CONCURRENTLY ch11_b.daily_sales;"
  fi
  for i in $(seq 1 "$N"); do
    # 背景で REFRESH を流し、所要時間を拾う
    ( t0=$(date +%s%N)
      psql_owner "$REF" >/dev/null 2>&1
      t1=$(date +%s%N)
      echo $(( (t1 - t0) / 1000000 )) > "/tmp/ch11_ref_${mode}_${i}.ms" ) &
    bgpid=$!

    sleep 0.25   # REFRESH が始まってから読みにいく

    t0=$(date +%s%N)
    psql_app "SELECT count(*) FROM ch11_b.daily_sales;" >/dev/null 2>&1
    t1=$(date +%s%N)
    sel=$(( (t1 - t0) / 1000000 ))

    wait "$bgpid"
    ref=$(cat "/tmp/ch11_ref_${mode}_${i}.ms" 2>/dev/null || echo -1)
    rm -f "/tmp/ch11_ref_${mode}_${i}.ms"

    printf '%-14s %d  SELECT %5d ms  REFRESH %6d ms\n' "$mode" "$i" "$sel" "$ref"
  done
done
