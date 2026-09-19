-- run-as: book_owner
-- 判定表は、元の所属とズレうる。ズレを検出する検査と、その検査が動いていることの確認。
--
-- 🔴 「検査が 0 を返した」だけでは、検査器が動いている証拠にならない（第8章 C1）。
--    ここでは **わざとズラして、検出できることを確かめてから** 直して 0 に戻す、
--    という両方向を 1 つのファイルで示す。
--
-- 🔴 検査は両方向で見る。
--    missing = 見られるべきなのに判定表に無い（読者が「見えない」と言ってくる）
--    extra   = 見られないはずなのに判定表にある（**情報漏洩**）
--    片方向だけの検査は、より危ない extra を見落とす。
--
-- 🔴 対称差は必ず括弧で囲む（第9章で 5 ファイルが同じ誤りだった）。
\timing on

\echo '=== (1) まずズレていないことを確かめる（drift / missing / extra が 0） ==='
WITH RECURSIVE vis AS (
  SELECT m.user_id, m.scope_id AS id FROM ch12_c.memberships m
  UNION
  SELECT v.user_id, s.id FROM ch12_c.scopes s JOIN vis v ON s.parent_id = v.id
), truth AS (
  SELECT DISTINCT v.user_id, d.id AS document_id
    FROM vis v JOIN ch12_c.documents d ON d.project_id = v.id
)
SELECT count(*) AS drift,
       count(*) FILTER (WHERE kind = 'missing') AS missing,
       count(*) FILTER (WHERE kind = 'extra')   AS extra,
       (SELECT count(*) FROM truth)             AS truth_rows
  FROM ((SELECT user_id, document_id, 'missing' AS kind FROM truth
         EXCEPT
         SELECT user_id, document_id, 'missing' FROM ch12_c.effective_access)
        UNION ALL
        (SELECT user_id, document_id, 'extra' FROM ch12_c.effective_access
         EXCEPT
         SELECT user_id, document_id, 'extra' FROM truth)) diff;

\echo '=== (2) わざとズラす（判定表だけを触り、所属は変えない） ==='
-- 運用では「所属を消す経路が 1 つあって、判定表の更新を呼んでいなかった」で起きる。
-- 消す 1 行（missing になる）と、実在しない権限 1 行（extra になる）を作る。
CREATE TEMP TABLE drift_removed AS
SELECT * FROM ch12_c.effective_access WHERE user_id = 7 ORDER BY document_id LIMIT 1;

DELETE FROM ch12_c.effective_access ea
 USING drift_removed r
 WHERE ea.user_id = r.user_id AND ea.document_id = r.document_id;

-- 利用者7 が所属していないプロジェクトの文書を 1 件、勝手に見えるようにする
CREATE TEMP TABLE drift_added AS
SELECT 7::bigint AS user_id, d.id AS document_id, 'viewer'::text AS role, d.created_at
  FROM ch12_c.documents d
 WHERE d.project_id NOT IN (SELECT scope_id FROM ch12_c.memberships WHERE user_id = 7)
   AND d.project_id NOT IN (
     SELECT p.id FROM ch12_c.scopes p
      WHERE p.parent_id IN (SELECT scope_id FROM ch12_c.memberships WHERE user_id = 7))
 ORDER BY d.id LIMIT 1;

INSERT INTO ch12_c.effective_access (user_id, document_id, role, created_at)
SELECT user_id, document_id, role, created_at FROM drift_added;

\echo '--- ズラした内容（missing 1 件 / extra 1 件になるはず） ---'
SELECT 'removed' AS kind, user_id, document_id FROM drift_removed
UNION ALL
SELECT 'added', user_id, document_id FROM drift_added;

\echo '=== (3) 🔴 検査がそれを捕まえること（drift=2 / missing=1 / extra=1 が正しい） ==='
-- ここで 0 が出たら、検査器が壊れている。
WITH RECURSIVE vis AS (
  SELECT m.user_id, m.scope_id AS id FROM ch12_c.memberships m
  UNION
  SELECT v.user_id, s.id FROM ch12_c.scopes s JOIN vis v ON s.parent_id = v.id
), truth AS (
  SELECT DISTINCT v.user_id, d.id AS document_id
    FROM vis v JOIN ch12_c.documents d ON d.project_id = v.id
)
SELECT count(*) AS drift_after_injection,
       count(*) FILTER (WHERE kind = 'missing') AS missing,
       count(*) FILTER (WHERE kind = 'extra')   AS extra
  FROM ((SELECT user_id, document_id, 'missing' AS kind FROM truth
         EXCEPT
         SELECT user_id, document_id, 'missing' FROM ch12_c.effective_access)
        UNION ALL
        (SELECT user_id, document_id, 'extra' FROM ch12_c.effective_access
         EXCEPT
         SELECT user_id, document_id, 'extra' FROM truth)) diff;

\echo '=== (4) 直す（消した 1 行を戻し、足した 1 行を消す） ==='
INSERT INTO ch12_c.effective_access (user_id, document_id, role, created_at)
SELECT user_id, document_id, role, created_at FROM drift_removed;

DELETE FROM ch12_c.effective_access ea
 USING drift_added a
 WHERE ea.user_id = a.user_id AND ea.document_id = a.document_id;

DROP TABLE drift_removed;
DROP TABLE drift_added;

\echo '=== (5) 直ったこと（先頭列が 0 に戻ること） ==='
WITH RECURSIVE vis AS (
  SELECT m.user_id, m.scope_id AS id FROM ch12_c.memberships m
  UNION
  SELECT v.user_id, s.id FROM ch12_c.scopes s JOIN vis v ON s.parent_id = v.id
), truth AS (
  SELECT DISTINCT v.user_id, d.id AS document_id
    FROM vis v JOIN ch12_c.documents d ON d.project_id = v.id
)
SELECT count(*) AS drift_after_repair,
       count(*) FILTER (WHERE kind = 'missing') AS missing,
       count(*) FILTER (WHERE kind = 'extra')   AS extra
  FROM ((SELECT user_id, document_id, 'missing' AS kind FROM truth
         EXCEPT
         SELECT user_id, document_id, 'missing' FROM ch12_c.effective_access)
        UNION ALL
        (SELECT user_id, document_id, 'extra' FROM ch12_c.effective_access
         EXCEPT
         SELECT user_id, document_id, 'extra' FROM truth)) diff;

\echo '=== 🔴 検査の費用（この検査は判定表の全行を作り直すのと同じ量を読む） ==='
-- 上の (1)(3)(5) の Time: がその費用である。案C の「ズレていないことを毎晩確かめる」は、
-- 初期構築と同じ桁の時間がかかる。これも案C の運用費用に数える。
SELECT (SELECT count(*) FROM ch12_c.effective_access) AS effective_rows,
       pg_size_pretty(pg_total_relation_size('ch12_c.effective_access')) AS total_size;
