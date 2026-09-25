-- run-as: book_owner
-- 案A の退会: 印を立てるだけ。1 文で済む。
-- 🔴 ただし個人情報は残る（20_pii_leftover.sql が示す）。
--    要件を満たすには上書きが要る。両方を測る。
\timing on
-- (1) 印を立てるだけ
UPDATE ch14_a.users SET deleted_at = now() WHERE id = 1 AND deleted_at IS NULL;
-- (2) 要件を満たすには、個人情報の列を全部つぶす必要がある
UPDATE ch14_a.users
   SET email     = 'deleted-' || id || '@invalid',
       full_name = '', postal = '', address = '', phone = ''
 WHERE id = 3;
-- (3) 注文の配送先にも同じ個人情報が写っている
UPDATE ch14_a.orders SET recipient = '', ship_addr = '', ship_phone = ''
 WHERE user_id = 3;
\timing off

-- (2)(3) のあと、その利用者の個人情報が残っていないことの検査（先頭列 0）
SELECT count(*) AS pii_left_for_user3 FROM (
  SELECT 1 FROM ch14_a.users
   WHERE id = 3 AND (full_name <> '' OR address <> '' OR phone <> '')
  UNION ALL
  SELECT 1 FROM ch14_a.orders
   WHERE user_id = 3 AND (recipient <> '' OR ship_addr <> '' OR ship_phone <> '')
) t;
