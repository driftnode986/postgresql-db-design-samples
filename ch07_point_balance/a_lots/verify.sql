-- 案A の検査。🔴 返す全行の先頭列が 0 であること（0 でなければ検証スクリプトが FAIL にする）
-- 残りが負のロットは無いか（CHECK があるので 0 のはず。制約が効いていることの確認）
SELECT count(*) AS negative_remaining FROM ch07_a.point_lots WHERE remaining < 0;

-- 残りが付与額を超えるロットは無いか
SELECT count(*) AS remaining_over_granted
FROM ch07_a.point_lots WHERE remaining > granted;

-- 引いた合計と、ロットの減った量が一致するか
SELECT count(*) AS lot_consumption_mismatch
FROM (
  SELECT l.id
  FROM ch07_a.point_lots AS l
  LEFT JOIN (
    SELECT lot_id, sum(taken) AS taken FROM ch07_a.lot_consumptions GROUP BY lot_id
  ) AS c ON c.lot_id = l.id
  WHERE l.granted - l.remaining <> coalesce(c.taken, 0)
) AS t;

-- 利用の台帳と、引いた合計が一致するか（引ききれていない利用が無いか）
SELECT count(*) AS use_not_fully_taken
FROM (
  SELECT t.id
  FROM ch07_a.point_txns AS t
  LEFT JOIN (
    SELECT txn_id, sum(taken) AS taken FROM ch07_a.lot_consumptions GROUP BY txn_id
  ) AS c ON c.txn_id = t.id
  WHERE t.kind = 'use' AND coalesce(c.taken, 0) <> t.amount
) AS t;
