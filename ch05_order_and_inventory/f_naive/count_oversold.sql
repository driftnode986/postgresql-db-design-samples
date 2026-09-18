-- 🔴 この検査は 0 にならないのが正しい結果。だから verify*.sql という名前にしない
--    （verify*.sql は「全行の先頭列が 0」を機械検査される規約のため）。
-- 読んで書き戻す案が、在庫 100 個に対して何個売ったかを数える。
SELECT count(*) AS negative_qty_rows FROM ch05_f.inventory WHERE qty < 0;
SELECT count(*) AS allocated_rows FROM ch05_f.allocations;
SELECT greatest(count(*) - 100, 0) AS oversold_rows FROM ch05_f.allocations;
