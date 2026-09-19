-- run-as: book_owner
-- REFRESH ... CONCURRENTLY が何を要求するかを、索引の状態を変えて確かめる。
--
-- 🔴 公式は「素の一意インデックスが要る。式インデックスでも WHERE 付きでも駄目」と書いている。
--    ここでは 4 通りの駄目な状態を実際に作り、**エラー文が 4 つとも同じ**であることを示す。
--    原因が分からないまま詰まる落とし穴なので、本文で扱う価値がある。
\timing on

\echo '=== (1) 索引がまったく無い ==='
DROP INDEX IF EXISTS ch11_b.daily_sales_pk;
\set ON_ERROR_STOP off
REFRESH MATERIALIZED VIEW CONCURRENTLY ch11_b.daily_sales;
\set ON_ERROR_STOP on

\echo '=== (2) 非一意の索引だけ ==='
CREATE INDEX ds_not_unique ON ch11_b.daily_sales (sales_date);
\set ON_ERROR_STOP off
REFRESH MATERIALIZED VIEW CONCURRENTLY ch11_b.daily_sales;
\set ON_ERROR_STOP on
DROP INDEX ch11_b.ds_not_unique;

\echo '=== (3) 一意だが WHERE 付き（部分一意） ==='
CREATE UNIQUE INDEX ds_partial ON ch11_b.daily_sales (sales_date, product_id)
  WHERE sales_date >= DATE '2020-01-01';
\set ON_ERROR_STOP off
REFRESH MATERIALIZED VIEW CONCURRENTLY ch11_b.daily_sales;
\set ON_ERROR_STOP on
DROP INDEX ch11_b.ds_partial;

\echo '=== (4) 一意だが式（列名そのものではない） ==='
-- 🔴 式は IMMUTABLE でなければ索引そのものが作れない。
--    (sales_date + 0) は IMMUTABLE なので索引は作れる。
--    つまりここで失敗するのは「索引が作れないから」ではなく
--    「CONCURRENTLY が式の索引を受け付けないから」である。
CREATE UNIQUE INDEX ds_expr ON ch11_b.daily_sales ((sales_date + 0), product_id);
\set ON_ERROR_STOP off
REFRESH MATERIALIZED VIEW CONCURRENTLY ch11_b.daily_sales;
\set ON_ERROR_STOP on
DROP INDEX ch11_b.ds_expr;

\echo '=== (5) 素の一意インデックス（これだけが通る） ==='
CREATE UNIQUE INDEX daily_sales_pk ON ch11_b.daily_sales (sales_date, product_id);
REFRESH MATERIALIZED VIEW CONCURRENTLY ch11_b.daily_sales;
