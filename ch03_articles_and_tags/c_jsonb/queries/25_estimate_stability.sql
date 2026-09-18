-- ANALYZE のたびに見積もりが変わるかを 5 回見る（問い合わせは実行しない）
\timing off
ANALYZE ch03_c.articles;
EXPLAIN SELECT id FROM ch03_c.articles WHERE tags @> '["tag001"]'::jsonb;
EXPLAIN SELECT id FROM ch03_c.articles WHERE tags @> '["tag050"]'::jsonb;
EXPLAIN SELECT id FROM ch03_c.articles WHERE tags @> '["tag150"]'::jsonb;
ANALYZE ch03_c.articles;
EXPLAIN SELECT id FROM ch03_c.articles WHERE tags @> '["tag001"]'::jsonb;
EXPLAIN SELECT id FROM ch03_c.articles WHERE tags @> '["tag050"]'::jsonb;
EXPLAIN SELECT id FROM ch03_c.articles WHERE tags @> '["tag150"]'::jsonb;
ANALYZE ch03_c.articles;
EXPLAIN SELECT id FROM ch03_c.articles WHERE tags @> '["tag001"]'::jsonb;
EXPLAIN SELECT id FROM ch03_c.articles WHERE tags @> '["tag050"]'::jsonb;
EXPLAIN SELECT id FROM ch03_c.articles WHERE tags @> '["tag150"]'::jsonb;
ANALYZE ch03_c.articles;
EXPLAIN SELECT id FROM ch03_c.articles WHERE tags @> '["tag001"]'::jsonb;
EXPLAIN SELECT id FROM ch03_c.articles WHERE tags @> '["tag050"]'::jsonb;
EXPLAIN SELECT id FROM ch03_c.articles WHERE tags @> '["tag150"]'::jsonb;
ANALYZE ch03_c.articles;
EXPLAIN SELECT id FROM ch03_c.articles WHERE tags @> '["tag001"]'::jsonb;
EXPLAIN SELECT id FROM ch03_c.articles WHERE tags @> '["tag050"]'::jsonb;
EXPLAIN SELECT id FROM ch03_c.articles WHERE tags @> '["tag150"]'::jsonb;

-- 要素ごとの統計があるか（案B は取る、案C は取らない）
SELECT attname,
       (most_common_elems IS NOT NULL) AS has_element_stats,
       cardinality(most_common_elems)  AS n_elems
FROM pg_stats WHERE schemaname = 'ch03_c' AND tablename = 'articles'
  AND attname = 'tags';
