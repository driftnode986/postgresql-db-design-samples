-- 案A に元データを写す。
-- 🔴 元データが空なら、何も消す前にここで止める（第2章の教訓。
--    load の実行順が先だと、全案が空のまま「全件 OK」になる）。
DO $$
BEGIN
  IF (SELECT count(*) FROM ch14_r.src_user) = 0 THEN
    RAISE EXCEPTION '元データ ch14_r.src_user が空。先に r_source/ を実行する';
  END IF;
END $$;

TRUNCATE ch14_a.comments, ch14_a.orders, ch14_a.users;

-- 元データの withdrawn を deleted_at に写す。退会日時は登録日より後になるようにそろえる。
INSERT INTO ch14_a.users (id, email, full_name, postal, address, phone, registered, deleted_at)
SELECT id, email, full_name, postal, address, phone, registered,
       CASE WHEN withdrawn THEN registered + interval '10 day' END
FROM ch14_r.src_user ORDER BY id;

INSERT INTO ch14_a.orders (id, user_id, ordered_at, amount, recipient, ship_addr, ship_phone)
SELECT id, user_id, ordered_at, amount, recipient, ship_addr, ship_phone
FROM ch14_r.src_order ORDER BY id;

INSERT INTO ch14_a.comments (id, user_id, body, posted_at)
SELECT id, user_id, body, posted_at FROM ch14_r.src_comment ORDER BY id;

ANALYZE ch14_a.users, ch14_a.orders, ch14_a.comments;
