-- ANALYZE のたびに見積もりが変わるかを 5 回見る（問い合わせは実行しない）
\timing off
ANALYZE ch03_b.articles;
EXPLAIN SELECT id FROM ch03_b.articles WHERE tags @> ARRAY['tag001'];
EXPLAIN SELECT id FROM ch03_b.articles WHERE tags @> ARRAY['tag050'];
EXPLAIN SELECT id FROM ch03_b.articles WHERE tags @> ARRAY['tag150'];
ANALYZE ch03_b.articles;
EXPLAIN SELECT id FROM ch03_b.articles WHERE tags @> ARRAY['tag001'];
EXPLAIN SELECT id FROM ch03_b.articles WHERE tags @> ARRAY['tag050'];
EXPLAIN SELECT id FROM ch03_b.articles WHERE tags @> ARRAY['tag150'];
ANALYZE ch03_b.articles;
EXPLAIN SELECT id FROM ch03_b.articles WHERE tags @> ARRAY['tag001'];
EXPLAIN SELECT id FROM ch03_b.articles WHERE tags @> ARRAY['tag050'];
EXPLAIN SELECT id FROM ch03_b.articles WHERE tags @> ARRAY['tag150'];
ANALYZE ch03_b.articles;
EXPLAIN SELECT id FROM ch03_b.articles WHERE tags @> ARRAY['tag001'];
EXPLAIN SELECT id FROM ch03_b.articles WHERE tags @> ARRAY['tag050'];
EXPLAIN SELECT id FROM ch03_b.articles WHERE tags @> ARRAY['tag150'];
ANALYZE ch03_b.articles;
EXPLAIN SELECT id FROM ch03_b.articles WHERE tags @> ARRAY['tag001'];
EXPLAIN SELECT id FROM ch03_b.articles WHERE tags @> ARRAY['tag050'];
EXPLAIN SELECT id FROM ch03_b.articles WHERE tags @> ARRAY['tag150'];

-- 要素ごとの統計があるか（案B は取る、案C は取らない）
SELECT attname,
       (most_common_elems IS NOT NULL) AS has_element_stats,
       cardinality(most_common_elems)  AS n_elems
FROM pg_stats WHERE schemaname = 'ch03_b' AND tablename = 'articles'
  AND attname = 'tags';
