-- 元データの利用を、案B の消し込みで実際に適用する。
--
-- 🔴 これをやらないと、ロットの残りは付与したままになり、案C（取引の合計）と残高が食い違う。
--    食い違いの原因が「設計の違い」なのか「投入の手抜き」なのか分からなくなるので、
--    測定の前に必ず適用する。
--
-- 利用は元データの順（id 順）に適用する。案B も同じ順で適用するので、
-- どちらの案も「同じ履歴をたどった結果」になる。
\timing on

DO $$
DECLARE
  r record;
  v_ok boolean;
  v_fail bigint := 0;
BEGIN
  FOR r IN SELECT id, user_id, amount FROM ch07_r.src_txn
           WHERE kind = 'use' ORDER BY id
  LOOP
    -- 台帳は load.sql で写し済み。案B はロットに加えて残高の列も減らす
    WITH cand AS (
      SELECT l.id, l.remaining,
             coalesce(sum(l.remaining) OVER (ORDER BY l.expires_at, l.id
               ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS before_sum
      FROM ch07_b.point_lots AS l
      WHERE l.user_id = r.user_id AND l.remaining > 0 AND l.expires_at > now()
    ), pick AS (
      SELECT c.id, least(c.remaining, r.amount - c.before_sum) AS take
      FROM cand AS c WHERE c.before_sum < r.amount
    ), upd AS (
      UPDATE ch07_b.point_lots AS l
      SET remaining = l.remaining - p.take
      FROM pick AS p WHERE l.id = p.id
      RETURNING l.id, p.take
    )
    INSERT INTO ch07_b.lot_consumptions (txn_id, lot_id, taken)
    SELECT r.id, id, take FROM upd;

    -- 🔴 案B はここで残高の列も減らす。ロットと残高の 2 か所を同じ量だけ動かす
    UPDATE ch07_b.point_balances
    SET balance = balance - r.amount, updated_at = now()
    WHERE user_id = r.user_id;

    SELECT coalesce(sum(taken), 0) = r.amount INTO v_ok
    FROM ch07_b.lot_consumptions WHERE txn_id = r.id;
    IF NOT v_ok THEN v_fail := v_fail + 1; END IF;
  END LOOP;

  RAISE NOTICE '引ききれなかった利用: % 件', v_fail;
  -- 🔴 1 件でもあれば元データが破綻している。測定に進ませない
  IF v_fail > 0 THEN
    RAISE EXCEPTION '元データの利用を引ききれない: % 件', v_fail;
  END IF;
END $$;

ANALYZE ch07_b.point_lots, ch07_b.lot_consumptions, ch07_b.point_balances;

SELECT count(*) AS consumptions, sum(taken) AS total_taken
FROM ch07_b.lot_consumptions;
