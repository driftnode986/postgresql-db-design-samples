-- 検算用: 読んだ値を書き戻す書き方
--
-- 採取した AI の案は 3 本とも FOR UPDATE を書いていた（docs/research/ch05_first_idea.md）。
-- この案は「AI がこう間違える」例ではなく、なぜ FOR UPDATE が要るのかを説明するための対照として置く。
--
-- CHECK (qty >= 0) を付けてあるのが要点。この制約があっても売り越しは止まらない。
CREATE SCHEMA ch05_f;

CREATE TABLE ch05_f.inventory (
  product_id bigint  PRIMARY KEY,
  qty        integer NOT NULL
             CONSTRAINT inventory_qty_non_negative CHECK (qty >= 0)
);

-- 引き当てた事実を 1 行ずつ残す。qty の減り方ではなく、この行数で売れた数を数える
CREATE TABLE ch05_f.allocations (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  product_id bigint NOT NULL,
  qty        integer NOT NULL
);

-- search_path を関数に付ける。付けないと book_app から呼んだときに
-- relation "inventory" does not exist で pgbench のクライアントが全滅する
CREATE FUNCTION ch05_f.allocate(p_product bigint, p_qty int)
RETURNS boolean LANGUAGE plpgsql SET search_path = ch05_f, public AS $$
DECLARE
  v_stock int;
BEGIN
  -- 読む。この時点の値をアプリ側（関数の変数）に持ち出す
  SELECT qty INTO v_stock FROM inventory WHERE product_id = p_product;
  IF v_stock IS NULL OR v_stock < p_qty THEN
    RETURN false;
  END IF;

  -- 読んだ値から引いて書き戻す。読んでから書くまでの間に他の接続が更新していても気づかない
  UPDATE inventory SET qty = v_stock - p_qty WHERE product_id = p_product;
  INSERT INTO allocations (product_id, qty) VALUES (p_product, p_qty);
  RETURN true;
END $$;

GRANT EXECUTE ON FUNCTION ch05_f.allocate(bigint, int) TO book_app;
GRANT SELECT, INSERT, UPDATE
  ON ch05_f.inventory, ch05_f.allocations TO book_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA ch05_f TO book_app;
