-- run-as: book_app
-- 案A の書き方(1)「1 件ずつ可否を返す関数を WHERE に置く」。
--
-- 既存のアプリに can_view(user, doc) の判定があるサービスで、
-- それをそのまま一覧に使うとどうなるかを見る。
--
-- 🔴 見る順番は「実行時間」ではなく「Rows Removed by Filter」である。
--    これが関数の実行回数で、20 件返すために何回判定したかを示す。
--
-- 🔴 5 回繰り返して中央値と幅を取る（docs/measurement-rules.yml）。
\timing on

\echo '=== 利用者7（大きなチームに入っていない = 見える文書が少ない）実行計画 3 回 ==='
EXPLAIN (ANALYZE)
SELECT d.id, d.title FROM ch12_a.documents d
 WHERE ch12_a.can_view(7, d.id)
 ORDER BY d.created_at DESC LIMIT 20;

EXPLAIN (ANALYZE)
SELECT d.id, d.title FROM ch12_a.documents d
 WHERE ch12_a.can_view(7, d.id)
 ORDER BY d.created_at DESC LIMIT 20;

EXPLAIN (ANALYZE)
SELECT d.id, d.title FROM ch12_a.documents d
 WHERE ch12_a.can_view(7, d.id)
 ORDER BY d.created_at DESC LIMIT 20;

\echo '=== 利用者7 素の実行 5 回（実行時間は下の Time: を読む） ==='
SELECT d.id, d.title FROM ch12_a.documents d
 WHERE ch12_a.can_view(7, d.id) ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
SELECT d.id, d.title FROM ch12_a.documents d
 WHERE ch12_a.can_view(7, d.id) ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
SELECT d.id, d.title FROM ch12_a.documents d
 WHERE ch12_a.can_view(7, d.id) ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
SELECT d.id, d.title FROM ch12_a.documents d
 WHERE ch12_a.can_view(7, d.id) ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
SELECT d.id, d.title FROM ch12_a.documents d
 WHERE ch12_a.can_view(7, d.id) ORDER BY d.created_at DESC LIMIT 20 \g /dev/null

\echo '=== 利用者42（大きなチーム込み = ほぼ全部見える）実行計画 3 回 ==='
EXPLAIN (ANALYZE)
SELECT d.id, d.title FROM ch12_a.documents d
 WHERE ch12_a.can_view(42, d.id)
 ORDER BY d.created_at DESC LIMIT 20;

EXPLAIN (ANALYZE)
SELECT d.id, d.title FROM ch12_a.documents d
 WHERE ch12_a.can_view(42, d.id)
 ORDER BY d.created_at DESC LIMIT 20;

EXPLAIN (ANALYZE)
SELECT d.id, d.title FROM ch12_a.documents d
 WHERE ch12_a.can_view(42, d.id)
 ORDER BY d.created_at DESC LIMIT 20;

\echo '=== 利用者42 素の実行 5 回（実行時間は下の Time: を読む） ==='
SELECT d.id, d.title FROM ch12_a.documents d
 WHERE ch12_a.can_view(42, d.id) ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
SELECT d.id, d.title FROM ch12_a.documents d
 WHERE ch12_a.can_view(42, d.id) ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
SELECT d.id, d.title FROM ch12_a.documents d
 WHERE ch12_a.can_view(42, d.id) ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
SELECT d.id, d.title FROM ch12_a.documents d
 WHERE ch12_a.can_view(42, d.id) ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
SELECT d.id, d.title FROM ch12_a.documents d
 WHERE ch12_a.can_view(42, d.id) ORDER BY d.created_at DESC LIMIT 20 \g /dev/null

\echo '=== 🔴 行レベルセキュリティが有効になっていないこと（交絡の検査） ==='
-- 確認記録 §6 で踏んだ事故の再発防止。ポリシーが残っていると
-- 関数は「絞られたあとの行」にしか適用されず、235 ms が 4 ms に見える。
-- 案ごとにスキーマを分けているので起きないが、機械で確かめておく。
-- 先頭列が 0 であること。
SELECT count(*) AS rls_enabled_tables
  FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
 WHERE n.nspname = 'ch12_a' AND (c.relrowsecurity OR c.relforcerowsecurity);

\echo '=== 🔴 book_app から見える文書の数が絞られていないこと ==='
-- 先頭列が 0 であること（絞られていたら 0 にならない）
SELECT count(*) AS documents_hidden_from_book_app
  FROM (SELECT 1 FROM ch12_r.src_document
        EXCEPT ALL SELECT 1 FROM ch12_a.documents) t;
