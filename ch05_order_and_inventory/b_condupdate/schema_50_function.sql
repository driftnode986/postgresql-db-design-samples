-- 案B の引当。UPDATE 1 文で済ませる。
--
-- UPDATE は対象の行に自動で排他ロックを取るので、FOR UPDATE を別に書かない。
-- 読んでから書くまでの隙間が無いので、在庫が足りるかどうかの判定と減算が同じ文で起きる。

CREATE FUNCTION ch05_b.allocate(p_product bigint, p_qty int)
RETURNS boolean LANGUAGE plpgsql AS $$
DECLARE
  v_after int;
BEGIN
  -- 18 では RETURNING に old. と new. を書ける。引当前と引当後の在庫を 1 文で取れる
  UPDATE ch05_b.inventory
     SET qty = qty - p_qty, updated_at = now()
   WHERE product_id = p_product
     AND qty >= p_qty          -- 足りるときだけ更新する。足りなければ 0 行
  RETURNING new.qty INTO v_after;

  -- 更新できなかった（在庫不足、または商品が無い）
  RETURN v_after IS NOT NULL;
EXCEPTION
  WHEN check_violation THEN RETURN false;
END $$;

-- 複数商品版。1 文で全商品をまとめて更新し、更新できた件数が要求した件数と一致するかで判定する。
-- 更新の順序は PostgreSQL が決めるので、ロック順をそろえられない
CREATE FUNCTION ch05_b.allocate_many(p_products bigint[], p_qty int)
RETURNS boolean LANGUAGE plpgsql AS $$
DECLARE
  v_updated int;
BEGIN
  WITH t AS (SELECT DISTINCT x AS product_id FROM unnest(p_products) AS x),
  upd AS (
    UPDATE ch05_b.inventory i
       SET qty = i.qty - p_qty, updated_at = now()
      FROM t
     WHERE i.product_id = t.product_id
       AND i.qty >= p_qty
    RETURNING i.product_id
  )
  SELECT count(*) INTO v_updated FROM upd;

  -- 1 つでも足りなければ、呼び出し側が ROLLBACK する。
  -- ここでは例外を出して、この関数の呼び出しを含むトランザクションを巻き戻す
  IF v_updated <> (SELECT count(DISTINCT x) FROM unnest(p_products) AS x) THEN
    RAISE EXCEPTION 'insufficient stock' USING ERRCODE = 'check_violation';
  END IF;
  RETURN true;
EXCEPTION
  WHEN check_violation THEN RETURN false;
  WHEN deadlock_detected THEN RETURN false;
END $$;

GRANT EXECUTE ON FUNCTION ch05_b.allocate(bigint, int) TO book_app;
GRANT EXECUTE ON FUNCTION ch05_b.allocate_many(bigint[], int) TO book_app;
