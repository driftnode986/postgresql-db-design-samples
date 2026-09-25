-- run-as: book_owner
-- 案B の退会: 控えに写してから行を消す。ON DELETE SET NULL で子の参照が切れる。
\timing on
BEGIN;
INSERT INTO ch14_b.withdrawn_users
       (id, email, full_name, postal, address, phone, registered, withdrawn_at, purge_after)
SELECT id, email, full_name, postal, address, phone, registered,
       now(), now() + interval '30 day'
FROM ch14_b.users WHERE id = 1;
DELETE FROM ch14_b.users WHERE id = 1;
COMMIT;
\timing off

-- 注文が残っていて、参照だけが切れていることの検査（先頭列 0）
SELECT count(*) AS orders_lost_for_user1 FROM (
  SELECT 1 WHERE (SELECT count(*) FROM ch14_b.orders) <>
                 (SELECT count(*) FROM ch14_r.src_order)
) t;
