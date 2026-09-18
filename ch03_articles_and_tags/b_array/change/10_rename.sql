-- 案B では、そのタグを持つ記事すべての配列を書き換える
\timing on
BEGIN;
UPDATE ch03_b.articles
   SET tags = array_replace(tags, 'tag001', 'postgres')
 WHERE tags @> ARRAY['tag001'];
SELECT c.relname, l.mode FROM pg_locks l
JOIN pg_class c ON c.oid = l.relation
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'ch03_b' AND l.pid = pg_backend_pid()
ORDER BY c.relname, l.mode;
ROLLBACK;
