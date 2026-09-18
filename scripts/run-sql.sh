#!/usr/bin/env bash
# SQL ファイルをコンテナに入れて実行し、出力をそのまま表示する。
#
#   bash scripts/run-sql.sh <ロール> <スキーマ> <SQL ファイル> [psql に渡す追加の引数...]
#   例: bash scripts/run-sql.sh book_owner ch06_c ch06_reservation/c_exclude/schema.sql
#       bash scripts/run-sql.sh book_app   ch06_c ch06_reservation/queries/find_free.sql -v size=M
#
# 実行のしかたを固定している理由（どちらも実機で確かめた事故）:
#   - 標準入力で流したり -t を付けずに流したりすると、docker exec 越しでは標準出力と標準エラーの
#     順序が保証されず、ERROR の行が次の文の表示より後ろにずれる。docker cp でファイルを入れ、-t を付けて流す
#   - -t を付けると psql のページャが起動して止まる。-P pager=off を必ず付ける
#   - -t を付けると行末に CR が付くので取り除く（結果を results/ に保存して比べるため）
#
# ロールは book_owner（テーブルを作る）、book_app（測る）、book_guest（権限を何も持たない）。
# スーパーユーザーの book_admin では測らない。行レベルセキュリティを迂回するので、結果を読み誤る。
#
# search_path は「指定したスキーマ, public」。lib は入れない（関数は lib.関数名() と修飾して呼ぶ）。
# 指定したスキーマがまだ無く、SQL ファイルもそのスキーマを作らないときは、実行せずに止まる。
# 止めないと、テーブルが意図しないスキーマに出来たり、分かりにくいエラーになったりする。
set -uo pipefail
CONTAINER="${PG_CONTAINER:-pgdbdesign}"
ROLE="${1:?ロール（book_owner / book_app）}"
SCHEMA="${2:?スキーマ（例 ch06_c）}"
FILE="${3:?SQL ファイル}"
shift 3

case "$ROLE" in
  book_owner|book_app|book_guest) ;;
  *) echo "NG: ロールは book_owner / book_app / book_guest（$ROLE は使わない）" >&2; exit 2 ;;
esac
case "$SCHEMA" in
  *[!a-z0-9_]*|'') echo "NG: スキーマ名は英小文字・数字・_ だけ: $SCHEMA" >&2; exit 2 ;;
esac
[ -f "$FILE" ] || { echo "NG: ファイルが無い: $FILE" >&2; exit 2; }

EXISTS=$(docker exec -e PGPASSWORD=book_owner "$CONTAINER" \
  psql -h 127.0.0.1 -U book_owner -d book -X -At -P pager=off \
  -c "select count(*) from pg_namespace where nspname = '$SCHEMA'") || exit 1
if [ "$EXISTS" != "1" ] && ! grep -Eiq "CREATE[[:space:]]+SCHEMA[[:space:]]+(IF[[:space:]]+NOT[[:space:]]+EXISTS[[:space:]]+)?$SCHEMA([^a-z0-9_]|\$)" "$FILE"; then
  echo "NG: スキーマ $SCHEMA がまだ無く、$FILE にも CREATE SCHEMA $SCHEMA が無い。" >&2
  echo "    先にその案の schema.sql を実行する。" >&2
  exit 2
fi

# 🔴 名前にプロセス番号を入れない。psql は NOTICE や ERROR の行頭にこのファイル名を出すので、
#    毎回変わると results/ の差分が無意味に出て、本文に引用した出力とも一致しなくなる
#    （書籍に /tmp/run-sql-82472.sql のような実行ごとの名前が載ってしまう）。
#    同じファイルを使い回すが、実行のたびに docker cp で上書きするので中身は毎回正しい。
DEST="/tmp/run-sql.sql"
docker cp "$FILE" "$CONTAINER:$DEST" >/dev/null || exit 1
docker exec -t \
  -e PGPASSWORD="$ROLE" \
  -e PGOPTIONS="-c search_path=$SCHEMA,public" \
  "$CONTAINER" \
  psql -h 127.0.0.1 -U "$ROLE" -d book -X -a -v ON_ERROR_STOP=1 -v size="${SIZE:-S}" \
       -P pager=off "$@" -f "$DEST" | tr -d '\r'
RC="${PIPESTATUS[0]}"
docker exec "$CONTAINER" rm -f "$DEST" >/dev/null 2>&1
exit "$RC"
