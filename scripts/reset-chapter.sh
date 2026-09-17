#!/usr/bin/env bash
# 1 つの章のスキーマだけを消す。他の章には触れない。
#
#   bash scripts/reset-chapter.sh 06
#
# 消すのは、その章が所有するスキーマ: ch06、ch06_a、ch06_b …と、
# ch13_c_t001 のようなテナント別のスキーマ（案のスキーマ名に _ と英数字を足したもの）。
# 形は ^chNN(_[a-z](_[a-z0-9]+)?)?$ で、scripts/check-schema-isolation.sh と同じ。
#
# スキーマの数が多い章（テナント別スキーマ）でも 1 回の接続で済むように、
# DROP 文を問い合わせで組み立てて \gexec で 1 つずつ実行する（1 文ごとに確定する）。
set -uo pipefail
CONTAINER="${PG_CONTAINER:-pgdbdesign}"
N="${1:?章番号（例 06）}"
case "$N" in *[!0-9]*) echo "NG: 章番号は数字" >&2; exit 2 ;; esac
CH="$(printf 'ch%02d' "$((10#$N))")"
PATTERN="^${CH}(_[a-z](_[a-z0-9]+)?)?\$"

COUNT=$(docker exec -e PGPASSWORD=book_owner "$CONTAINER" \
  psql -h 127.0.0.1 -U book_owner -d book -X -At -P pager=off \
  -c "select count(*) from pg_namespace where nspname ~ '${PATTERN}'") || exit 1
if [ "$COUNT" = "0" ]; then
  echo "${CH} のスキーマは無い"
  exit 0
fi

docker exec -i -e PGPASSWORD=book_owner "$CONTAINER" \
  psql -h 127.0.0.1 -U book_owner -d book -X -q -v ON_ERROR_STOP=1 -P pager=off -f - <<SQL || exit 1
SET client_min_messages = warning;
SELECT format('DROP SCHEMA %I CASCADE', nspname)
FROM pg_namespace WHERE nspname ~ '${PATTERN}' ORDER BY nspname \gexec
SQL
echo "消した: ${CH} のスキーマ ${COUNT} 個"
