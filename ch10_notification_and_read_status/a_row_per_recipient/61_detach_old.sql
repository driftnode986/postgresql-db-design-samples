-- run-as: book_owner
--
-- パーティションを切り離して落とす。60_delete_old.sql の続き。
--
-- 🔴 この節の主役はロックである。
--    CONCURRENTLY を付けない DETACH は親テーブルに AccessExclusiveLock を取り、
--    そのあいだ全読み取りが止まる。「パーティションなら一瞬」は
--    CONCURRENTLY を付けた場合の話である。

\timing on
SET search_path TO ch10_a, public;

-- 🔴 このファイルは 2 回流しても同じ結果になるようにする。
--    前回の実行で切り離した（DETACH した）パーティションが残っていると、
--    次の実行は「すでに切り離されている」ところで止まる。
--    切り離されたまま残っている表を、先に付け直すか落とす。
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'ch10_a' AND c.relname LIKE 'del\_part\_%' AND c.relkind = 'r'
       AND NOT EXISTS (SELECT 1 FROM pg_inherits i WHERE i.inhrelid = c.oid)
  LOOP
    EXECUTE format('DROP TABLE ch10_a.%I', r.relname);
    RAISE NOTICE '前回の実行で切り離された % を落とした', r.relname;
  END LOOP;
END $$;

\echo '=== 消す前（全パーティションの合計） ==='
SELECT pg_size_pretty((SELECT sum(pg_total_relation_size(c.oid))
                         FROM pg_inherits i JOIN pg_class c ON c.oid = i.inhrelid
                        WHERE i.inhparent = 'ch10_a.del_part'::regclass)) AS total;

\echo '=== パーティションごとの行数 ==='
SELECT c.relname,
       (SELECT reltuples::bigint FROM pg_class c2 WHERE c2.oid = c.oid) AS est_rows,
       pg_size_pretty(pg_total_relation_size(c.oid)) AS size
  FROM pg_inherits i JOIN pg_class c ON c.oid = i.inhrelid
 WHERE i.inhparent = 'ch10_a.del_part'::regclass
 ORDER BY c.relname;

\echo '=== (1) CONCURRENTLY を付けない DETACH が取るロック ==='
-- 🔴 トランザクションの中で実行して pg_locks を見る。
--    ここで AccessExclusiveLock が見えることが、この節の要点である。
BEGIN;
ALTER TABLE ch10_a.del_part DETACH PARTITION ch10_a.del_part_2026_04;
SELECT c.relname, l.mode
  FROM pg_locks l JOIN pg_class c ON c.oid = l.relation
  JOIN pg_namespace n ON n.oid = c.relnamespace
 WHERE n.nspname = 'ch10_a' AND c.relname LIKE 'del_part%'
 ORDER BY c.relname, l.mode;
ROLLBACK;

\echo '=== (2) DETACH CONCURRENTLY はトランザクションの中で実行できない ==='
-- 🔴 「消す処理をトランザクションでまとめて安全に」という素直な書き方ができない。
--    ここは **エラーになるのが正しい**（expect-error: 25001）。
--    エラーで止めずに先へ進めるため、この 1 文だけ ON_ERROR_STOP を外す。
\set ON_ERROR_STOP off
BEGIN;
ALTER TABLE ch10_a.del_part DETACH PARTITION ch10_a.del_part_2026_04 CONCURRENTLY;
ROLLBACK;
\set ON_ERROR_STOP on

\echo '=== (3) DETACH CONCURRENTLY + DROP（トランザクションの外） ==='
ALTER TABLE ch10_a.del_part DETACH PARTITION ch10_a.del_part_2026_04 CONCURRENTLY;
DROP TABLE ch10_a.del_part_2026_04;

\echo '=== 落とした後（全パーティションの合計。即座に戻る） ==='
SELECT pg_size_pretty((SELECT sum(pg_total_relation_size(c.oid))
                         FROM pg_inherits i JOIN pg_class c ON c.oid = i.inhrelid
                        WHERE i.inhparent = 'ch10_a.del_part'::regclass)) AS total_after;
