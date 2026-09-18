-- 案C の引当。合計を取ってから、足りれば負の行を追記する。
--
-- 案A・案B と違い、減らす対象の行が無い。追記するだけなので、ロックを取る相手がいない。
-- 何もしないと、2 つの接続が同じ合計を読んで両方が追記し、売り越しになる。
-- そこで商品の行を FOR UPDATE でロックし、商品 1 件につき同時に 1 つの引当だけが進むようにする。

CREATE FUNCTION ch05_c.allocate(p_product bigint, p_qty int)
RETURNS boolean LANGUAGE plpgsql AS $$
DECLARE
  v_stock int;
BEGIN
  -- 追記先の行が無いので、商品の行を待ち合わせの場所として使う。
  -- この行は更新しないが、FOR UPDATE は他の接続の FOR UPDATE を待たせる
  PERFORM 1 FROM ch05_c.products WHERE id = p_product FOR UPDATE;

  SELECT coalesce(sum(delta), 0) INTO v_stock
    FROM ch05_c.inventory_entries WHERE product_id = p_product;

  IF v_stock < p_qty THEN
    RETURN false;
  END IF;

  INSERT INTO ch05_c.inventory_entries (product_id, delta, reason)
  VALUES (p_product, -p_qty, 'allocation');
  RETURN true;
END $$;

GRANT EXECUTE ON FUNCTION ch05_c.allocate(bigint, int) TO book_app;

-- 比較のため、ロックを取らない版も置く。売り越しが出ることを実証するのに使う
CREATE FUNCTION ch05_c.allocate_nolock(p_product bigint, p_qty int)
RETURNS boolean LANGUAGE plpgsql AS $$
DECLARE
  v_stock int;
BEGIN
  SELECT coalesce(sum(delta), 0) INTO v_stock
    FROM ch05_c.inventory_entries WHERE product_id = p_product;

  IF v_stock < p_qty THEN
    RETURN false;
  END IF;

  INSERT INTO ch05_c.inventory_entries (product_id, delta, reason)
  VALUES (p_product, -p_qty, 'allocation');
  RETURN true;
END $$;

GRANT EXECUTE ON FUNCTION ch05_c.allocate_nolock(bigint, int) TO book_app;
