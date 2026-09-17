#!/usr/bin/env bash
# 拡張を専用のスキーマに置くと何が起きるかを、別のデータベースで確かめる。
#   bash ch01_environment/extras/ext_placement.sh > ch01_environment/results/ext_placement.txt
# データベースの作成と拡張の導入にはスーパーユーザーが要るので、ここだけ book_admin を使う。
# 本書のデータベース book には何も作らず、終わったら確認用のデータベースを消す。
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
C="${PG_CONTAINER:-pgdbdesign}"
admin() { docker exec -t -e PGPASSWORD=book_admin "$C" psql -h 127.0.0.1 -U book_admin -X -a -P pager=off "$@" | tr -d '\r'; }
bash scripts/collect-env.sh
admin -d book -q -c "DROP DATABASE IF EXISTS book_ext" -c "CREATE DATABASE book_ext"
docker exec -i -e PGPASSWORD=book_admin "$C" sh -c 'cat > /tmp/ext_placement.sql' <<'SQL'
CREATE SCHEMA ext;
CREATE EXTENSION btree_gist SCHEMA ext;
CREATE EXTENSION ltree SCHEMA ext;
CREATE SCHEMA trial;
SET search_path = trial, public;
-- ext は search_path に無い。btree_gist の演算子クラスは見つかるか
CREATE TABLE resv (
  room_id int, period tstzrange,
  PRIMARY KEY (room_id, period WITHOUT OVERLAPS));
-- ltree の型は見つかるか
SELECT 'a.b'::ltree;
SELECT 'a.b.c'::ext.ltree <@ 'a.b'::ext.ltree;
SELECT 'a.b.c'::ext.ltree OPERATOR(ext.<@) 'a.b'::ext.ltree AS is_descendant;
SQL
admin -d book_ext -f /tmp/ext_placement.sql
admin -d book -q -c "DROP DATABASE book_ext"
