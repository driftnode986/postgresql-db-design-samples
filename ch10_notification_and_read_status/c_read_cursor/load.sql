-- 案C に元データを写す。
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ch10_r.src_notice) THEN
    RAISE EXCEPTION '元データが空。先に r_source/schema_20_generate.sql を実行する';
  END IF;
END $$;

\timing on

TRUNCATE ch10_c.read_cursors;
TRUNCATE ch10_c.broadcasts;
TRUNCATE ch10_c.notifications RESTART IDENTITY;

-- 個別の通知（案A・案B とまったく同じ中身）
INSERT INTO ch10_c.notifications (user_id, kind, body, read_at, created_at)
SELECT d.user_id, n.kind, n.body, d.read_at, n.created_at
  FROM ch10_r.src_notice n
  JOIN ch10_r.src_delivery d ON d.notice_id = n.id
 WHERE NOT n.is_broadcast
 ORDER BY n.id;

-- 全員向けの告知（案B と同じ）
INSERT INTO ch10_c.broadcasts (id, kind, body, created_at)
SELECT n.id, n.kind, n.body, n.created_at
  FROM ch10_r.src_notice n
 WHERE n.is_broadcast
 ORDER BY n.id;

-- カーソル。利用者 1 人につき 1 行。
--
-- 🔴 ここが案C の性質そのものである。
--    元データは「どの告知を読んだか」を 1 件ずつ持っているが、
--    案C はそれを「ここまで読んだ」という 1 つの位置に畳む。
--    畳むときに、飛ばし読み（10 番を読んで 9 番を読んでいない）の情報は失われる。
--
--    位置の決め方は「読んでいない最も古い告知の 1 つ手前」にする。
--    最大の既読 id を採ると、飛ばした 9 番を既読と見なしてしまい、
--    読んでいない告知を未読件数から落とす（＝通知を握りつぶす）。
--    未読を多めに見せる側に倒すのが安全側である。
INSERT INTO ch10_c.read_cursors (user_id, broadcast_read_upto, updated_at)
SELECT u.id,
       COALESCE(
         (SELECT min(b.id) - 1
            FROM ch10_c.broadcasts b
           WHERE NOT EXISTS (SELECT 1 FROM ch10_r.src_delivery d
                              WHERE d.notice_id = b.id
                                AND d.user_id = u.id
                                AND d.read_at IS NOT NULL)),
         (SELECT max(b.id) FROM ch10_c.broadcasts b),   -- 全部読んでいる
         0),
       now()
  FROM ch10_r.src_user u
 ORDER BY u.id;

-- 🔴 索引はデータを入れてから作る。案A・案B と同じ形にそろえる
CREATE INDEX notif_c_unread ON ch10_c.notifications (user_id, created_at DESC)
  WHERE read_at IS NULL;

ANALYZE ch10_c.notifications;
ANALYZE ch10_c.broadcasts;
ANALYZE ch10_c.read_cursors;

\echo '=== 案C の件数 ==='
SELECT (SELECT count(*) FROM ch10_c.notifications) AS personal_rows,
       (SELECT count(*) FROM ch10_c.broadcasts)    AS broadcast_rows,
       (SELECT count(*) FROM ch10_c.read_cursors)  AS cursor_rows;

\echo '=== カーソルに畳んだことで失われた情報（飛ばし読み） ==='
-- 元データでは読んだのに、カーソルでは未読になる告知の件数。
-- 🔴 これは不具合ではなく、案C が引き受けた代償である。本文で数値を示す。
SELECT count(*) AS lost_reads
  FROM ch10_r.src_delivery d
  JOIN ch10_c.broadcasts b ON b.id = d.notice_id
  JOIN ch10_c.read_cursors c ON c.user_id = d.user_id
 WHERE d.read_at IS NOT NULL
   AND b.id > c.broadcast_read_upto;
