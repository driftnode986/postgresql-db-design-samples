#!/usr/bin/env bash
# SQL の流し方で、ERROR の行の位置が変わるかを数える。
#   bash ch01_environment/extras/error_order.sh > ch01_environment/results/error_order.txt
# エラーになる文を 40 個含む SQL を 3 通りで 5 回ずつ流し、ERROR の行が、
# 原因の文（SELECT 1/0）の表示の直後に無かった件数を数える。
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
C="${PG_CONTAINER:-pgdbdesign}"
F="$(mktemp)"; trap 'rm -f "$F"' EXIT
for i in $(seq 1 40); do
  echo "SELECT 'row' AS ok_$i FROM generate_series(1, 5);"
  echo "SELECT 1/0 AS err_$i;"
done > "$F"
docker cp "$F" "$C:/tmp/error_order.sql" >/dev/null
misplaced() { awk 'NF { if ($0 ~ /ERROR:/ && prev !~ /SELECT 1\/0/) n++; prev = $0 } END { print n + 0 }'; }
P=(psql -h 127.0.0.1 -U book_app -d book -X -a)
bash scripts/collect-env.sh
for way in stdin file file_tty; do
  printf '%s:' "$way"
  for run in 1 2 3 4 5; do
    case "$way" in
      stdin)    docker exec -i -e PGPASSWORD=book_app "$C" "${P[@]}" < "$F" 2>&1 ;;
      file)     docker exec    -e PGPASSWORD=book_app "$C" "${P[@]}" -f /tmp/error_order.sql 2>&1 ;;
      file_tty) docker exec -t -e PGPASSWORD=book_app "$C" "${P[@]}" -P pager=off -f /tmp/error_order.sql 2>&1 | tr -d '\r' ;;
    esac | misplaced | tr '\n' ' '
  done
  echo "（40 件中、位置がずれた ERROR の件数。5 回分）"
done
