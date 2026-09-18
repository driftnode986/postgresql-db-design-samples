-- 在庫 100 個の商品 1 件だけを置く。16 接続がこの 1 件を取り合う形にする。
-- 🔴 1 万商品に分散させると、どの商品も売り切れに達せず、売り越しが 0 件で通ってしまう
SELECT count(*) AS src_rows FROM ch05_r.src_product \gset
SELECT CASE WHEN :src_rows = 0
            THEN 1/0 ELSE 1 END AS source_must_not_be_empty;

TRUNCATE ch05_f.inventory, ch05_f.allocations RESTART IDENTITY;
INSERT INTO ch05_f.inventory (product_id, qty) VALUES (1, 100);
