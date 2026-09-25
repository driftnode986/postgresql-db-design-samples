-- run-as: book_app
-- 案A: 退会していない利用者を登録の新しい順に 20 件。部分インデックスで引く。
EXPLAIN (ANALYZE) SELECT id, registered FROM ch14_a.users
 WHERE deleted_at IS NULL ORDER BY registered DESC LIMIT 20;
EXPLAIN (ANALYZE) SELECT id, registered FROM ch14_a.users
 WHERE deleted_at IS NULL ORDER BY registered DESC LIMIT 20;
EXPLAIN (ANALYZE) SELECT id, registered FROM ch14_a.users
 WHERE deleted_at IS NULL ORDER BY registered DESC LIMIT 20;
