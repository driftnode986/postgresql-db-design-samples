#!/usr/bin/env bash
# 会社 1 社ぶんだけを取り出せるかを、案C と案B で比べる。
#
# 案C はスキーマが 1 社に対応しているので、pg_dump -n で抜ける。
# 案B は 1 つの表に全社が混ざっているので、pg_dump には会社を指定する手段が無い。
# 代わりに COPY で抜き出す形になる（これは自前の仕組みになる）。
set -uo pipefail
CONTAINER="${PG_CONTAINER:-pgdbdesign}"
run() { docker exec -e PGPASSWORD=book_owner "$CONTAINER" "$@"; }

echo "== 案C: 会社 1 社のスキーマだけを抜く =="
start=$(date +%s.%N)
run pg_dump -h 127.0.0.1 -U book_owner -d book -n ch13_c_t0050 > /tmp/ch13_c_one.sql
end=$(date +%s.%N)
printf 'pg_dump -n ch13_c_t0050: %.3f 秒 / %s バイト\n' \
  "$(echo "$end - $start" | bc)" "$(wc -c < /tmp/ch13_c_one.sql | tr -d ' ')"

echo
echo "== 案B: 同じ 1 社を抜く（pg_dump には会社を指定できないので COPY で書き出す）=="
# 🔴 2 か所つまずく。どちらも案B の運用で必ず踏む。
#   (1) \copy はクライアント側で解釈されるので、docker exec 越しだと
#       コンテナの中に書き出そうとする。サーバ側の COPY TO STDOUT を使う
#   (2) FORCE ROW LEVEL SECURITY を付けてあるので、所有者で実行しても
#       app.tenant_id を設定しないとポリシー式の評価が失敗する
start=$(date +%s.%N)
run psql -h 127.0.0.1 -U book_owner -d book -X -q -t -A -P pager=off \
  -c "SET app.tenant_id = '50'; COPY (SELECT * FROM ch13_b.deals WHERE tenant_id = 50) TO STDOUT" \
  > /tmp/ch13_b_one.tsv
end=$(date +%s.%N)
printf 'COPY (tenant_id = 50): %.3f 秒 / %s バイト\n' \
  "$(echo "$end - $start" | bc)" "$(wc -c < /tmp/ch13_b_one.tsv | tr -d ' ')"

echo
echo "== データベース全体のスキーマ定義（案C は会社の数だけ定義が並ぶ）=="
start=$(date +%s.%N)
run pg_dump -h 127.0.0.1 -U book_owner -d book --schema-only > /tmp/ch13_all_schema.sql
end=$(date +%s.%N)
printf 'pg_dump --schema-only: %.3f 秒 / %s 行 / %s バイト\n' \
  "$(echo "$end - $start" | bc)" \
  "$(wc -l < /tmp/ch13_all_schema.sql | tr -d ' ')" \
  "$(wc -c < /tmp/ch13_all_schema.sql | tr -d ' ')"

# 🔴 書き出しが 0 バイトでも、コマンド自体は成功で終わる。
#    実際に \copy を docker exec 越しに使って 0 バイトになり、
#    そのまま「測れた」ことにしてしまった。中身があることを検査する。
for f in /tmp/ch13_c_one.sql /tmp/ch13_b_one.tsv /tmp/ch13_all_schema.sql; do
  n=$(wc -c < "$f" | tr -d ' ')
  if [ "$n" -lt 100 ]; then
    echo "NG: $f が $n バイトしかない（書き出せていない）"
    rm -f /tmp/ch13_c_one.sql /tmp/ch13_b_one.tsv /tmp/ch13_all_schema.sql
    exit 1
  fi
done

rm -f /tmp/ch13_c_one.sql /tmp/ch13_b_one.tsv /tmp/ch13_all_schema.sql
