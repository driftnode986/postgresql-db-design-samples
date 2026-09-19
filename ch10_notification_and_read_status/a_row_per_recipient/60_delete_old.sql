-- run-as: book_owner
--
-- 90 日より古い通知を消す。2 つのやり方を比べる。
--
--   (A) 通常の表を DELETE する
--   (B) 月ごとのパーティションを DETACH して DROP する
--
-- 🔴 本当の論点は時間ではなくロックである。
--    「パーティションなら一瞬」で終わらせると、CONCURRENTLY を付け忘れて
--    本番の読み取りを止める読者が出る（docs/research/ch10_verification.md §11）。
--
-- 元データからコピーした作業用の表で測る。案A の本体は触らない。

\timing on
SET search_path TO ch10_a, public;

DROP TABLE IF EXISTS ch10_a.del_plain;
DROP TABLE IF EXISTS ch10_a.del_part;

\echo '=== (A) 通常の表を用意する ==='
CREATE TABLE ch10_a.del_plain (LIKE ch10_a.notifications INCLUDING ALL);
INSERT INTO ch10_a.del_plain (user_id, kind, body, read_at, created_at)
SELECT user_id, kind, body, read_at, created_at FROM ch10_a.notifications
 ORDER BY id;
ANALYZE ch10_a.del_plain;

\echo '=== (B) パーティション表を用意する（月ごと） ==='
-- 🔴 パーティション表の主キーには、パーティションキーの列が入る必要がある。
--    (id) だけにすると「unique constraint on partitioned table must include
--    all partitioning columns」で作れない。
CREATE TABLE ch10_a.del_part (
  id         bigint GENERATED ALWAYS AS IDENTITY,
  user_id    bigint      NOT NULL,
  kind       text        NOT NULL,
  body       text        NOT NULL,
  read_at    timestamptz,
  created_at timestamptz NOT NULL,
  PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- 直近 7 か月ぶんを用意する（元データは 180 日に散っている）
DO $$
DECLARE m date := date_trunc('month', now())::date - interval '6 months';
BEGIN
  WHILE m <= date_trunc('month', now())::date LOOP
    EXECUTE format(
      'CREATE TABLE ch10_a.del_part_%s PARTITION OF ch10_a.del_part '
      'FOR VALUES FROM (%L) TO (%L)',
      to_char(m, 'YYYY_MM'), m, m + interval '1 month');
    m := m + interval '1 month';
  END LOOP;
END $$;

INSERT INTO ch10_a.del_part (user_id, kind, body, read_at, created_at)
SELECT user_id, kind, body, read_at, created_at FROM ch10_a.notifications
 ORDER BY id;
ANALYZE ch10_a.del_part;

\echo '=== 消す前のサイズ ==='
-- 🔴 パーティション表に pg_total_relation_size(親) を使わない。0 を返す。
--    全パーティションの合計を取る（docs/measurement-rules.yml の sizes.partitioned）。
SELECT pg_size_pretty(pg_total_relation_size('ch10_a.del_plain')) AS plain,
       pg_size_pretty(pg_total_relation_size('ch10_a.del_part'))  AS part_parent_wrong,
       pg_size_pretty((SELECT sum(pg_total_relation_size(c.oid))
                         FROM pg_inherits i JOIN pg_class c ON c.oid = i.inhrelid
                        WHERE i.inhparent = 'ch10_a.del_part'::regclass)) AS part_correct;

\echo '=== (A) DELETE で 90 日より古い行を消す ==='
DELETE FROM ch10_a.del_plain WHERE created_at < now() - interval '90 days';

\echo '=== DELETE の直後のサイズ（戻らない） ==='
SELECT pg_size_pretty(pg_total_relation_size('ch10_a.del_plain')) AS after_delete;

VACUUM (ANALYZE) ch10_a.del_plain;
\echo '=== VACUUM の後のサイズ（まだ戻らない） ==='
SELECT pg_size_pretty(pg_total_relation_size('ch10_a.del_plain')) AS after_vacuum;

VACUUM FULL ch10_a.del_plain;
\echo '=== VACUUM FULL の後のサイズ（ここで戻る） ==='
SELECT pg_size_pretty(pg_total_relation_size('ch10_a.del_plain')) AS after_vacuum_full;
