-- 案C の名前の変更。案B と同じく、持っている記事すべてを書き換える
\timing on
BEGIN;
UPDATE ch03_c.articles
   SET tags = (SELECT jsonb_agg(CASE WHEN x = 'tag001' THEN 'postgres' ELSE x END
                                ORDER BY x)
               FROM jsonb_array_elements_text(tags) AS x)
 WHERE tags @> '["tag001"]'::jsonb;
ROLLBACK;
