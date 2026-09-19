-- run-as: book_app
-- ポリシーを付けた表を、一括処理（全件を読む処理）から使うとどうなるか。
--
-- 案C の初期構築のように、**全利用者ぶんの判定表を作る**処理は、
-- 「ログイン中の利用者」を持たない。ポリシーは current_setting('app.user_id') を要求するので、
-- ここで失敗する。確認記録 §6 で踏んだ問題である。
--
-- 🔴 対処を 2 つ比べる。
--    (a) FORCE を外す / ポリシーを無効にする … 迂回できるが、**黙って迂回する**
--    (b) SET row_security = off … 公式が勧める形で、**黙って欠けるのではなくエラーになる**
--
--    公式（ddl-rowsecurity）:
--      「it could be disastrous if row security silently caused some rows to be omitted from
--       the backup. In such a situation, you can set the row_security configuration parameter
--       to off. This does not in itself bypass row security; what it does is throw an error
--       if any query's results would get filtered by a policy.」
\timing on

\echo '=== (1) app.user_id が未設定のセッションで全件を読もうとする ==='
-- 🔴 期待するエラー: 42704 unrecognized configuration parameter "app.user_id"
DO $$
BEGIN
  PERFORM count(*) FROM ch12_a.documents;
  RAISE NOTICE '🔴 想定外: 読めた';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '想定どおりエラー: % (SQLSTATE %)', SQLERRM, SQLSTATE;
END $$;

\echo '=== (2) app.user_id を設定すると読めるが、その 1 人ぶんに絞られる ==='
-- 🔴 ここが危ない。一括処理が「エラーにならずに、少ない行で完走する」。
--    案C の判定表が 22,147 行しか入らず、しかも成功して見える。
SET app.user_id = '42';
SELECT count(*) AS rows_visible_to_user42 FROM ch12_a.documents;

\echo '=== (3) row_security = off にすると、絞られる問い合わせはエラーになる ==='
-- 🔴 期待するエラー: query would be affected by row-level security policy for table "documents"
--    黙って欠けるのではなく確実に止まるので、一括処理はこれを付ける。
SET row_security = off;
DO $$
BEGIN
  PERFORM count(*) FROM ch12_a.documents;
  RAISE NOTICE '🔴 想定外: row_security = off でも読めた';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '想定どおりエラー: % (SQLSTATE %)', SQLERRM, SQLSTATE;
END $$;
RESET row_security;

\echo '=== (4) まとめ: 3 つの経路の違い ==='
-- (1) 設定を忘れる          → エラー（気づける）
-- (2) 1 人ぶんを設定する    → 成功するが行が足りない（🔴 気づけない）
-- (3) row_security = off    → エラー（気づける・公式が勧める形）
SELECT 'app.user_id 未設定'          AS path, 'エラー'          AS result,
       '気づける'                     AS safety
UNION ALL
SELECT '1 人ぶんを設定',  '成功するが行が足りない', '🔴 気づけない'
UNION ALL
SELECT 'row_security = off', 'エラー',              '気づける（公式が勧める）';
