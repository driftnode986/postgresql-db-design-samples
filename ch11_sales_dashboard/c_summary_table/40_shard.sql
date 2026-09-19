-- run-as: book_owner
-- 集計行への集中を緩める。集計行を 1 つではなく 16 個に分ける。
--
-- 🔴 同じ日・同じ商品でも、接続ごとに違う行に足す。
--    読むときに 16 行を合計するだけで済むので、読み取りの代償は小さい。
--    これで「集中するなら案C は使えない」ではなく
--    「集中する見込みがあるなら行を分ける」という条件つきの選び方が書ける。
CREATE TABLE IF NOT EXISTS ch11_c.daily_sales_shard (
  sales_date date   NOT NULL,
  product_id bigint NOT NULL,
  shard      int    NOT NULL,
  qty        bigint NOT NULL DEFAULT 0,
  gross_yen  bigint NOT NULL DEFAULT 0,
  PRIMARY KEY (sales_date, product_id, shard)
);

CREATE OR REPLACE FUNCTION ch11_c.place_order_sharded(
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

  -- 🔴 接続ごとに違う行へ足す。同じ行を取り合わない。
  INSERT INTO ch11_c.daily_sales_shard
         (sales_date, product_id, shard, qty, gross_yen)
  VALUES (v_date, p_product_id, pg_backend_pid() % 16, p_qty, p_amount_yen)
  ON CONFLICT (sales_date, product_id, shard) DO UPDATE
    SET qty       = ch11_c.daily_sales_shard.qty       + EXCLUDED.qty,
        gross_yen = ch11_c.daily_sales_shard.gross_yen + EXCLUDED.gross_yen;
END $$ LANGUAGE plpgsql;
