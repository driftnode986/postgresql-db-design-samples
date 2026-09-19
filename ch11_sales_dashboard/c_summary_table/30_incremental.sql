-- run-as: book_owner
-- 案C の差分更新。注文を入れると同時に、その日その商品の集計行を書き換える。
--
-- 🔴 ON CONFLICT ... DO UPDATE を使う。集計行が無ければ作り、あれば足す。
--    MERGE でも同じことが書けるが、ON CONFLICT のほうが短い。
-- 🔴 id はシーケンスで採る。max(id) + 1 で採ると、そこが直列化の原因になり、
--    この測定で見たい「集計行への集中」ではなく、id の取り合いを測ることになる。
CREATE SEQUENCE IF NOT EXISTS ch11_c.order_lines_seq
  START WITH 2000000;   -- 既存の 100 万件とぶつからない位置から

CREATE OR REPLACE FUNCTION ch11_c.place_order(
  p_product_id bigint, p_qty int, p_amount_yen bigint) RETURNS void AS $$
DECLARE
  v_line_id bigint;
  v_cat     int;
  v_now     timestamptz := now();
  v_date    date := (v_now AT TIME ZONE 'Asia/Tokyo')::date;
BEGIN
  SELECT category_id INTO v_cat FROM ch11_r.src_product WHERE id = p_product_id;

  v_line_id := nextval('ch11_c.order_lines_seq');

  INSERT INTO ch11_c.order_lines
         (id, order_id, product_id, category_id, qty, amount_yen, ordered_at)
  VALUES (v_line_id, v_line_id, p_product_id, v_cat, p_qty, p_amount_yen, v_now);

  -- 🔴 ここが同じ行への更新になる。人気商品では全接続が同じ 1 行を取り合う。
  INSERT INTO ch11_c.daily_sales
         (sales_date, product_id, category_id, qty, gross_yen, refund_yen)
  VALUES (v_date, p_product_id, v_cat, p_qty, p_amount_yen, 0)
  ON CONFLICT (sales_date, product_id) DO UPDATE
    SET qty       = ch11_c.daily_sales.qty       + EXCLUDED.qty,
        gross_yen = ch11_c.daily_sales.gross_yen + EXCLUDED.gross_yen;
END $$ LANGUAGE plpgsql;

-- 比較のため、集計を更新せずに注文だけを入れる関数も作る。
CREATE OR REPLACE FUNCTION ch11_c.place_order_only(
  p_product_id bigint, p_qty int, p_amount_yen bigint) RETURNS void AS $$
DECLARE
  v_line_id bigint;
  v_cat     int;
BEGIN
  SELECT category_id INTO v_cat FROM ch11_r.src_product WHERE id = p_product_id;
  v_line_id := nextval('ch11_c.order_lines_seq');
  INSERT INTO ch11_c.order_lines
         (id, order_id, product_id, category_id, qty, amount_yen, ordered_at)
  VALUES (v_line_id, v_line_id, p_product_id, v_cat, p_qty, p_amount_yen, now());
END $$ LANGUAGE plpgsql;
