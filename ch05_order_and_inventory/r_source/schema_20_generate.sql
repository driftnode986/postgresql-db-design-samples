-- 商品を生成する。SIZE=S なら 1,000 商品、M なら 10,000 商品。
-- 在庫は 1 商品あたり 100 個。測定の 20 秒で在庫が尽きないように、測定のたびに入れ直す。
--
-- setseed で乱数の種を固定するので、何度実行しても同じ値になる。
\set size `echo "${SIZE:-M}"`
\set n_products `case "${SIZE:-M}" in S) echo 1000 ;; *) echo 10000 ;; esac`

\timing on
SELECT setseed(0.42);

TRUNCATE ch05_r.src_product;

INSERT INTO ch05_r.src_product (id, sku, name, price_yen, qty)
SELECT g,
       'SKU-' || lpad(g::text, 7, '0'),
       '商品' || g,
       -- 価格は 500 円から 30,000 円。分布は結論に関係しないので一様でよい
       500 + (random() * 29500)::int,
       100
FROM generate_series(1, :n_products) AS g;

SELECT count(*) AS products, sum(qty) AS total_qty FROM ch05_r.src_product;
