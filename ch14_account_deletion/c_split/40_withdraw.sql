-- run-as: book_owner
-- 案C の退会: 個人情報のテーブルから行を消し、本体に印を立てる。
-- 消す対象は profiles と order_shipments の 2 つだけ。
\timing on
BEGIN;
UPDATE ch14_c.accounts SET status = 'withdrawn', withdrawn_at = now()
 WHERE id = 1 AND status = 'active';
DELETE FROM ch14_c.profiles WHERE account_id = 1;
DELETE FROM ch14_c.order_shipments
 WHERE order_id IN (SELECT id FROM ch14_c.orders WHERE account_id = 1);
COMMIT;
\timing off

-- 個人情報が残っていないことの検査（先頭列 0）
SELECT count(*) AS pii_left_for_account1 FROM (
  SELECT 1 FROM ch14_c.profiles WHERE account_id = 1
  UNION ALL
  SELECT 1 FROM ch14_c.order_shipments s
    JOIN ch14_c.orders o ON o.id = s.order_id WHERE o.account_id = 1
) t;

-- 注文は残っていることの検査（先頭列 0 = 消えた件数が 0）
SELECT count(*) AS orders_lost FROM (
  SELECT 1 WHERE (SELECT count(*) FROM ch14_c.orders) <>
                 (SELECT count(*) FROM ch14_r.src_order)
) t;
