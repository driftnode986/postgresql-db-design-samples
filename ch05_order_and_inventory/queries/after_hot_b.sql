-- 🔴 このファイルは pgbench の測定の直後にだけ意味がある（run_bench.sh が流す）。
--    素の DB に流すと「商品 1 の在庫が 0 でない」で当然落ちるので、
--    verify*.sql という名前にしない（verify* は読み込み直後に全行 0 を求められる）。
-- 測定直後の検査（案B）。全行の先頭列が 0 であること。
--
-- 🔴 その案の測定の直後に流す。3 案ぶんまとめて最後に 1 回流すと、
--    次の案の前に在庫を戻した時点で前の案の結果が消え、
--    「引当が 1 件も起きていない」状態を売り越し 0 と読んでしまう（実際に踏んだ）。
SELECT count(*) AS oversold FROM ch05_b.inventory WHERE qty < 0;
-- 引当が実際に起きたか（起きていなければ「売り越し 0」は無意味）
SELECT count(*) AS no_allocation
  FROM (SELECT sum(qty) AS s FROM ch05_b.inventory) AS x
 WHERE s = (SELECT sum(qty) FROM ch05_r.src_product);
-- 在庫 100 個の商品 1 が、ちょうど 0 で止まったか（0 以外なら 0 でない値が出る）
SELECT abs(coalesce((SELECT qty FROM ch05_b.inventory WHERE product_id = 1), -1))
       AS qty_of_product_1_must_be_zero;
