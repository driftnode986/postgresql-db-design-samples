-- run-as: book_guest
-- IDENTITY の列を持つ表に INSERT する。GRANT したのは表への INSERT だけで、
-- serial の場合と権限はまったく同じである。
--
-- 🔴 こちらは成功する。IDENTITY の裏にもシーケンスはあるが、
--    それはテーブルに従属するオブジェクトなので、表の権限で読める。
--
-- 本書が主キーに IDENTITY を使う理由の 1 つがこれである
--    （権限の設計が 1 つ減る = 事故が 1 つ減る）。
INSERT INTO ch12_g.t_identity (memo) VALUES ('guest からの挿入');

\echo '=== 入った行（book_guest は SELECT を持たないので count は見られない） ==='
-- 🔴 SELECT は GRANT していないので、ここで読もうとすると別のエラーになる。
--    「挿入はできるが読めない」という状態が作れることを示す。
DO $$
BEGIN
  PERFORM count(*) FROM ch12_g.t_identity;
  RAISE NOTICE '🔴 想定外: SELECT できた';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '想定どおり: % (SQLSTATE %)', SQLERRM, SQLSTATE;
END $$;
