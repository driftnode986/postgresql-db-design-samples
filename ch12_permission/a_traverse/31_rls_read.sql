-- run-as: book_app
-- ポリシーを付けた状態で、素の SELECT を測る。
--
-- 問い合わせに WHERE が 1 つも無いことに注目する。絞り込みはポリシーが行う。
--
-- 🔴 見るのは実行計画の `hashed SubPlan` と `loops=1` である。
--    ポリシーの中の副問い合わせ（vis の展開）が、行ごとに再実行されるのか、
--    1 回だけ評価されてハッシュに保持されるのかを、ここで確かめる。
--
-- 🔴 公式（ddl-rowsecurity）は「This expression will be evaluated **for each row**」と書いている。
--    両方とも正しい。行ごとに走るのは `IN` のハッシュ照合だけで、
--    副問い合わせそのものは 1 回である。この区別を実行計画で見る。
\timing on

\echo '=== 利用者7（SET app.user_id = 7）実行計画 3 回 ==='
SET app.user_id = '7';

EXPLAIN (ANALYZE, VERBOSE)
SELECT d.id, d.title FROM ch12_a.documents d ORDER BY d.created_at DESC LIMIT 20;

EXPLAIN (ANALYZE)
SELECT d.id, d.title FROM ch12_a.documents d ORDER BY d.created_at DESC LIMIT 20;

EXPLAIN (ANALYZE)
SELECT d.id, d.title FROM ch12_a.documents d ORDER BY d.created_at DESC LIMIT 20;

\echo '=== 利用者7 素の実行 5 回（実行時間は下の Time: を読む） ==='
SELECT d.id, d.title FROM ch12_a.documents d ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
SELECT d.id, d.title FROM ch12_a.documents d ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
SELECT d.id, d.title FROM ch12_a.documents d ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
SELECT d.id, d.title FROM ch12_a.documents d ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
SELECT d.id, d.title FROM ch12_a.documents d ORDER BY d.created_at DESC LIMIT 20 \g /dev/null

\echo '=== 🔴 ポリシーが効いていること（count が全件ではなく、見える件数になる） ==='
-- WHERE を書いていないのに件数が絞られる。これがポリシーの効果である。
SELECT count(*) AS visible_documents_for_user7 FROM ch12_a.documents;

\echo '=== 利用者42（SET app.user_id = 42）実行計画 3 回 ==='
SET app.user_id = '42';

EXPLAIN (ANALYZE)
SELECT d.id, d.title FROM ch12_a.documents d ORDER BY d.created_at DESC LIMIT 20;

EXPLAIN (ANALYZE)
SELECT d.id, d.title FROM ch12_a.documents d ORDER BY d.created_at DESC LIMIT 20;

EXPLAIN (ANALYZE)
SELECT d.id, d.title FROM ch12_a.documents d ORDER BY d.created_at DESC LIMIT 20;

\echo '=== 利用者42 素の実行 5 回（実行時間は下の Time: を読む） ==='
SELECT d.id, d.title FROM ch12_a.documents d ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
SELECT d.id, d.title FROM ch12_a.documents d ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
SELECT d.id, d.title FROM ch12_a.documents d ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
SELECT d.id, d.title FROM ch12_a.documents d ORDER BY d.created_at DESC LIMIT 20 \g /dev/null
SELECT d.id, d.title FROM ch12_a.documents d ORDER BY d.created_at DESC LIMIT 20 \g /dev/null

SELECT count(*) AS visible_documents_for_user42 FROM ch12_a.documents;

\echo '=== 🔴 ポリシーの結果が、明示的に書いた集合と同じであること（先頭列が 0） ==='
-- ポリシーが返す集合と、a_traverse/21_read_set.sql の集合が一致することを確かめる。
-- 一致しなければ、ポリシーは「別の絞り込み」をしていることになる。
SET app.user_id = '7';
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_a.memberships m WHERE m.user_id = 7
  UNION SELECT s.id FROM ch12_a.scopes s JOIN vis ON s.parent_id = vis.id),
by_query AS (
  -- 🔴 ポリシーが効いている表を読むので、ここも絞られた結果になる。
  --    絞られた集合の中で、明示的な条件をさらに掛けても同じ件数であるはず。
  SELECT d.id FROM ch12_a.documents d JOIN vis ON vis.id = d.project_id),
by_policy AS (
  SELECT d.id FROM ch12_a.documents d)
SELECT count(*) AS policy_vs_query_diff,
       (SELECT count(*) FROM by_policy) AS policy_rows,
       (SELECT count(*) FROM by_query)  AS query_rows
  FROM ((SELECT id FROM by_policy EXCEPT SELECT id FROM by_query)
        UNION ALL
        (SELECT id FROM by_query  EXCEPT SELECT id FROM by_policy)) t;

\echo '=== 🔴 一意制約の検査は RLS を迂回する（公式が covert channel と呼ぶ経路） ==='
-- 公式（ddl-rowsecurity）:
--   「Referential integrity checks, such as unique or primary key constraints and foreign key
--    references, always bypass row security」
-- 利用者7 が**書ける**プロジェクト（自分が所属しているプロジェクト）に、
-- 利用者7 に**見えない**文書の id で INSERT する。
-- 書き込みのポリシーは通るが、主キーの検査に当たる。
-- 「見えないのに主キー違反」= その id の文書が存在することが分かってしまう。
--
-- 🔴 期待するエラー: 23505 duplicate key value violates unique constraint "documents_pkey"
DO $$
DECLARE v_hidden bigint; v_writable bigint; v_free bigint;
BEGIN
  -- 利用者7 が書けるプロジェクト（ポリシーの WITH CHECK を通る先）
  SELECT m.scope_id INTO v_writable
    FROM ch12_a.memberships m
    JOIN ch12_a.scopes s ON s.id = m.scope_id
   WHERE m.user_id = 7 AND s.kind = 'project' ORDER BY m.scope_id LIMIT 1;

  -- 利用者7 に見えない文書の id。攻撃者は id を総当たりするだけでよい。
  -- ここでは「自分に見えない id」を 1 件選ぶ（自分の SELECT からは空に見える id）。
  SELECT g INTO v_hidden FROM generate_series(1, 100000) AS g
   WHERE NOT EXISTS (SELECT 1 FROM ch12_a.documents d WHERE d.id = g)
   ORDER BY g LIMIT 1;

  -- 比較のため、本当に存在しない id も 1 つ用意する
  SELECT max(id) + 1000000 INTO v_free FROM ch12_r.src_document;

  RAISE NOTICE '書けるプロジェクト: % / 自分には見えない id: % / 存在しない id: %',
               v_writable, v_hidden, v_free;

  -- (a) 存在しない id → 挿入できる（= 「空き」だと分かる）
  --
  -- 🔴 挿入した行は必ず消す。ここで消し漏らすと、この表の件数が 1 件増えたまま残り、
  --    あとの検査（案A と案C の一覧の突き合わせ）が 674 対 673 の差を出す（実際に踏んだ）。
  --    しかも **DELETE のポリシーが無いと、DELETE はエラーにならず 0 行消して終わる**
  --    （公式 sql-createpolicy: 「Typically, such rows are silently suppressed;
  --    no error is reported」）。消えたつもりで残るので、消えたことを検査する。
  BEGIN
    INSERT INTO ch12_a.documents (id, project_id, title, created_at)
    VALUES (v_free, v_writable, 'probe-free', now());
    RAISE NOTICE '(a) 存在しない id % → 挿入できた（空きだと分かる）', v_free;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '(a) 想定外: % (SQLSTATE %)', SQLERRM, SQLSTATE;
  END;

  -- (b) 自分には見えないが存在する id → 主キー違反（= 「使用済み」だと分かる）
  BEGIN
    INSERT INTO ch12_a.documents (id, project_id, title, created_at)
    VALUES (v_hidden, v_writable, 'probe-hidden', now());
    RAISE NOTICE '(b) 🔴 想定外: 挿入できた（主キーの検査が働いていない）';
    DELETE FROM ch12_a.documents WHERE id = v_hidden;
  EXCEPTION WHEN unique_violation THEN
    RAISE NOTICE '(b) 想定どおり: % (SQLSTATE %)', SQLERRM, SQLSTATE;
    RAISE NOTICE '(b) 🔴 (a) と (b) でエラーが違う = 見えない行の存在が分かってしまう';
  WHEN OTHERS THEN
    RAISE NOTICE '(b) 別のエラー: % (SQLSTATE %)', SQLERRM, SQLSTATE;
  END;
END $$;
