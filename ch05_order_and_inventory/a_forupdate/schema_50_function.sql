-- 案A の引当。1 回の関数呼び出しにまとめる（案の間で往復の回数をそろえる規約）。
--
-- p_items は (商品 id, 数量) の配列。複数商品の一括引当を 1 文で渡せるようにする。
-- 戻り値は成功したかどうか。pgbench はこの真偽値を数えない（測定後の検査クエリで判定する）。

-- 単一商品版。1 商品への集中を測るときに使う
CREATE FUNCTION ch05_a.allocate(p_product bigint, p_qty int)
RETURNS boolean LANGUAGE plpgsql AS $$
DECLARE
  v_stock int;
BEGIN
  -- 在庫の行をロックしてから読む。ロックが取れるまで他の接続はここで待つ
  SELECT qty INTO v_stock FROM ch05_a.inventory
   WHERE product_id = p_product FOR UPDATE;

  IF v_stock IS NULL OR v_stock < p_qty THEN
    RETURN false;
  END IF;

  UPDATE ch05_a.inventory
     SET qty = qty - p_qty, updated_at = now()
   WHERE product_id = p_product;
  RETURN true;
EXCEPTION
  -- 制約違反は pgbench のクライアントを止めるので、関数の中で受けて false を返す。
  -- この受けがあるぶん、測定値には例外処理の費用が含まれる
  WHEN check_violation THEN RETURN false;
END $$;

-- 複数商品版。ロックを取る順序を引数で切り替え、デッドロックの件数を比べる。
-- p_sorted が真なら商品 id の昇順にロックを取る
CREATE FUNCTION ch05_a.allocate_many(p_products bigint[], p_qty int, p_sorted boolean)
RETURNS boolean LANGUAGE plpgsql AS $$
DECLARE
  v_id    bigint;
  v_stock int;
  v_ids   bigint[];
BEGIN
  IF p_sorted THEN
    SELECT array_agg(x ORDER BY x) INTO v_ids
      FROM unnest(p_products) AS x;
  ELSE
    v_ids := p_products;
  END IF;

  FOREACH v_id IN ARRAY v_ids LOOP
    SELECT qty INTO v_stock FROM ch05_a.inventory
     WHERE product_id = v_id FOR UPDATE;
    IF v_stock IS NULL OR v_stock < p_qty THEN
      RETURN false;
    END IF;
    UPDATE ch05_a.inventory
       SET qty = qty - p_qty, updated_at = now()
     WHERE product_id = v_id;
  END LOOP;
  RETURN true;
EXCEPTION
  WHEN check_violation THEN RETURN false;
  -- デッドロックも受ける。件数は pgbench の failures-detailed ではなく、
  -- この関数が false を返した回数としては数えられないので、測定後の検査で在庫の整合だけを見る
  WHEN deadlock_detected THEN RETURN false;
END $$;

GRANT EXECUTE ON FUNCTION ch05_a.allocate(bigint, int) TO book_app;
GRANT EXECUTE ON FUNCTION ch05_a.allocate_many(bigint[], int, boolean) TO book_app;
