-- 案C に元データを写す。
-- 🔴 元データが空なら、何も消す前にここで止める。
DO $$
BEGIN
  IF (SELECT count(*) FROM ch14_r.src_user) = 0 THEN
    RAISE EXCEPTION '元データ ch14_r.src_user が空。先に r_source/ を実行する';
  END IF;
END $$;

TRUNCATE ch14_c.comments, ch14_c.order_shipments, ch14_c.orders,
         ch14_c.profiles, ch14_c.accounts;

INSERT INTO ch14_c.accounts (id, status, registered, withdrawn_at)
SELECT id,
       CASE WHEN withdrawn THEN 'withdrawn' ELSE 'active' END,
       registered,
       CASE WHEN withdrawn THEN registered + interval '10 day' END
FROM ch14_r.src_user ORDER BY id;

-- 退会した利用者の個人情報は、この案では既に消えている（行が無い）。
INSERT INTO ch14_c.profiles (account_id, email, full_name, postal, address, phone)
SELECT id, email, full_name, postal, address, phone
FROM ch14_r.src_user WHERE NOT withdrawn ORDER BY id;

INSERT INTO ch14_c.orders (id, account_id, ordered_at, amount)
SELECT id, user_id, ordered_at, amount FROM ch14_r.src_order ORDER BY id;

-- 配送先も、退会した利用者のぶんは消えている。
INSERT INTO ch14_c.order_shipments (order_id, recipient, ship_addr, ship_phone)
SELECT o.id, o.recipient, o.ship_addr, o.ship_phone
FROM ch14_r.src_order o JOIN ch14_r.src_user u ON u.id = o.user_id
WHERE NOT u.withdrawn ORDER BY o.id;

INSERT INTO ch14_c.comments (id, account_id, body, posted_at)
SELECT id, user_id, body, posted_at FROM ch14_r.src_comment ORDER BY id;

ANALYZE ch14_c.accounts, ch14_c.profiles, ch14_c.orders,
        ch14_c.order_shipments, ch14_c.comments;
