-- run-as: book_app
-- 案B: 退会した利用者は users に居ないので、条件そのものが要らない。
EXPLAIN (ANALYZE) SELECT id, registered FROM ch14_b.users
 ORDER BY registered DESC LIMIT 20;
EXPLAIN (ANALYZE) SELECT id, registered FROM ch14_b.users
 ORDER BY registered DESC LIMIT 20;
EXPLAIN (ANALYZE) SELECT id, registered FROM ch14_b.users
 ORDER BY registered DESC LIMIT 20;
