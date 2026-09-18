-- 🔴 このファイルは pgbench の測定の直後にだけ意味がある（run_bench.sh が流す）。
--    素の DB に流すと「商品 1 の在庫が 0 でない」で当然落ちるので、
--    verify*.sql という名前にしない（verify* は読み込み直後に全行 0 を求められる）。
-- 測定直後の検査（案C）。全行の先頭列が 0 であること。
-- 案C は在庫の列を持たず、増減の合計で有効在庫を求める。
SELECT count(*) AS oversold FROM ch05_c.available WHERE qty < 0;
SELECT count(*) AS no_allocation
  FROM (SELECT count(*) AS s FROM ch05_c.inventory_entries
         WHERE reason = 'allocation') AS x WHERE s = 0;
SELECT abs(coalesce((SELECT qty FROM ch05_c.available WHERE product_id = 1), -1))
       AS qty_of_product_1_must_be_zero;
