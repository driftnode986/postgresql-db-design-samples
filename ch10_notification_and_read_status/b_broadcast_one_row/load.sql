-- 案B に元データを写す。
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ch10_r.src_notice) THEN
    RAISE EXCEPTION '元データが空。先に r_source/schema_20_generate.sql を実行する';
  END IF;
END $$;

\timing on

TRUNCATE ch10_b.broadcast_reads;
TRUNCATE ch10_b.broadcasts CASCADE;
TRUNCATE ch10_b.notifications RESTART IDENTITY;

-- 個別の通知（案A とまったく同じ中身）
INSERT INTO ch10_b.notifications (user_id, kind, body, read_at, created_at)
SELECT d.user_id, n.kind, n.body, d.read_at, n.created_at
  FROM ch10_r.src_notice n
  JOIN ch10_r.src_delivery d ON d.notice_id = n.id
 WHERE NOT n.is_broadcast
 ORDER BY n.id;

-- 全員向けの告知は 1 件 1 行。id は元データのものをそのまま使う
INSERT INTO ch10_b.broadcasts (id, kind, body, created_at)
SELECT n.id, n.kind, n.body, n.created_at
  FROM ch10_r.src_notice n
 WHERE n.is_broadcast
 ORDER BY n.id;

-- 告知を読んだ人だけ行を作る
INSERT INTO ch10_b.broadcast_reads (broadcast_id, user_id, read_at)
SELECT d.notice_id, d.user_id, d.read_at
  FROM ch10_r.src_notice n
  JOIN ch10_r.src_delivery d ON d.notice_id = n.id
 WHERE n.is_broadcast AND d.read_at IS NOT NULL
 ORDER BY d.notice_id, d.user_id;

-- 🔴 索引はデータを入れてから作る。案A と同じ形にそろえる
CREATE INDEX notif_b_unread ON ch10_b.notifications (user_id, created_at DESC)
  WHERE read_at IS NULL;
-- 告知の未読判定（「この人が読んだ告知」を引く）を支える
CREATE INDEX bcast_reads_user ON ch10_b.broadcast_reads (user_id);

ANALYZE ch10_b.notifications;
ANALYZE ch10_b.broadcasts;
ANALYZE ch10_b.broadcast_reads;

\echo '=== 案B の件数 ==='
SELECT (SELECT count(*) FROM ch10_b.notifications)   AS personal_rows,
       (SELECT count(*) FROM ch10_b.broadcasts)      AS broadcast_rows,
       (SELECT count(*) FROM ch10_b.broadcast_reads) AS read_rows;
