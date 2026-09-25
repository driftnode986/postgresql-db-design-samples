-- run-as: book_app
-- 案C: 本体は残るので、案A と同じく条件で絞る。部分インデックスで引く。
EXPLAIN (ANALYZE) SELECT id, registered FROM ch14_c.accounts
 WHERE status = 'active' ORDER BY registered DESC LIMIT 20;
EXPLAIN (ANALYZE) SELECT id, registered FROM ch14_c.accounts
 WHERE status = 'active' ORDER BY registered DESC LIMIT 20;
EXPLAIN (ANALYZE) SELECT id, registered FROM ch14_c.accounts
 WHERE status = 'active' ORDER BY registered DESC LIMIT 20;
