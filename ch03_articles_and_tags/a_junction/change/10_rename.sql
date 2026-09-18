-- 変更シナリオ 1: タグの名前を変える（tag001 を postgres に）。
-- 案A はマスタの 1 行だけを書き換える
\timing on
BEGIN;
UPDATE ch03_a.tags SET name = 'postgres' WHERE name = 'tag001';
SELECT count(*) AS rows_touched FROM ch03_a.tags WHERE name = 'postgres';
-- トランザクションの中で、どのロックを取っているかを見る
SELECT c.relname, l.mode FROM pg_locks l
JOIN pg_class c ON c.oid = l.relation
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'ch03_a' AND l.pid = pg_backend_pid()
ORDER BY c.relname, l.mode;
ROLLBACK;
