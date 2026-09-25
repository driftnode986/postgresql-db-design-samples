-- 案B に元データを写す。
-- 🔴 元データが空なら、何も消す前にここで止める。
DO $$
BEGIN
  IF (SELECT count(*) FROM ch14_r.src_user) = 0 THEN
    RAISE EXCEPTION '元データ ch14_r.src_user が空。先に r_source/ を実行する';
  END IF;
END $$;

TRUNCATE ch14_b.comments, ch14_b.orders, ch14_b.withdrawn_users, ch14_b.users;

-- 案B では退会済みの利用者は users に居ない。控えのテーブルに居る。
INSERT INTO ch14_b.users (id, email, full_name, postal, address, phone, registered)
SELECT id, email, full_name, postal, address, phone, registered
FROM ch14_r.src_user WHERE NOT withdrawn ORDER BY id;

INSERT INTO ch14_b.withdrawn_users
       (id, email, full_name, postal, address, phone, registered, withdrawn_at, purge_after)
SELECT id, email, full_name, postal, address, phone, registered,
       registered + interval '10 day',
       registered + interval '10 day' + interval '30 day'
FROM ch14_r.src_user WHERE withdrawn ORDER BY id;

-- 注文とコメントは全件残す。退会した利用者のぶんは user_id を NULL にする
-- （物理削除で ON DELETE SET NULL が働いた後の状態と同じ）。
INSERT INTO ch14_b.orders (id, user_id, ordered_at, amount, recipient, ship_addr, ship_phone)
SELECT o.id,
       CASE WHEN u.withdrawn THEN NULL ELSE o.user_id END,
       o.ordered_at, o.amount, o.recipient, o.ship_addr, o.ship_phone
FROM ch14_r.src_order o JOIN ch14_r.src_user u ON u.id = o.user_id
ORDER BY o.id;

INSERT INTO ch14_b.comments (id, user_id, body, posted_at)
SELECT c.id,
       CASE WHEN u.withdrawn THEN NULL ELSE c.user_id END,
       c.body, c.posted_at
FROM ch14_r.src_comment c JOIN ch14_r.src_user u ON u.id = c.user_id
ORDER BY c.id;

ANALYZE ch14_b.users, ch14_b.withdrawn_users, ch14_b.orders, ch14_b.comments;
