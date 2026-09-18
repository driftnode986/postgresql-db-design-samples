-- 案B の統合。置き換えたあと、同じタグが 2 つ並ぶ記事を整理する
\timing on
BEGIN;
UPDATE ch03_b.articles
   SET tags = (SELECT array_agg(DISTINCT x ORDER BY x)
               FROM unnest(array_replace(tags, 'tag002', 'tag001')) AS x)
 WHERE tags @> ARRAY['tag002'];
ROLLBACK;
