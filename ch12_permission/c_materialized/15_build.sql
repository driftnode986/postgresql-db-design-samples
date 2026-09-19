-- run-as: book_owner
-- 案C の判定表を初期構築する。この章で最も大きな数が出る。
--
-- 🔴 作る前に行数を数える。作ってから「大きすぎた」と気づくと、
--    やり直しに時間がかかる（この量では数分。M では作れない見込み）。
\timing on

\echo '=== (1) 作る前に行数を見積もる（実際に数える。COUNT だけで実体化はしない） ==='
WITH RECURSIVE vis AS (
  SELECT m.user_id, m.scope_id AS id FROM ch12_c.memberships m
  UNION
  SELECT v.user_id, s.id FROM ch12_c.scopes s JOIN vis v ON s.parent_id = v.id
)
SELECT (SELECT count(*) FROM ch12_c.documents)   AS documents,
       (SELECT count(*) FROM ch12_c.users)       AS users,
       (SELECT count(*) FROM ch12_c.memberships) AS memberships,
       count(*)                                  AS effective_rows_to_build,
       round(count(*)::numeric
             / (SELECT count(*) FROM ch12_c.documents), 1) AS times_source
  FROM vis v JOIN ch12_c.documents d ON d.project_id = v.id;

\echo '=== (2) 大きなチームが何行を生むか（内訳） ==='
-- 「全員が入る大きなチーム」1 つが、判定表の何割を占めるかを示す。
SELECT s.id AS scope_id, s.kind, s.name,
       (SELECT count(*) FROM ch12_c.memberships m WHERE m.scope_id = s.id) AS members,
       (SELECT count(*) FROM ch12_c.documents d
          JOIN ch12_c.scopes p ON p.id = d.project_id
         WHERE p.parent_id = s.id OR p.id = s.id)                          AS docs_below,
       (SELECT count(*) FROM ch12_c.memberships m WHERE m.scope_id = s.id)
       * (SELECT count(*) FROM ch12_c.documents d
            JOIN ch12_c.scopes p ON p.id = d.project_id
           WHERE p.parent_id = s.id OR p.id = s.id)                        AS rows_generated
  FROM ch12_c.scopes s
 WHERE s.kind IN ('org', 'team')
 ORDER BY rows_generated DESC LIMIT 5;

\echo '=== (3) 初期構築（ここが本章の「あとで変えるのが大変な点」の数値） ==='
-- 🔴 入れ直しても同じ結果になるようにする（2 回実行すると主キー違反で止まる）
TRUNCATE ch12_c.effective_access;
-- 🔴 DISTINCT ON で、同じ人が同じ文書に複数の経路で到達したときに 1 行に畳む。
--    ORDER BY の role で「強い役割」を優先する（admin < editor < viewer の文字列順で
--    admin が先に来るので、ここでは文字列順がそのまま優先順になる）。
INSERT INTO ch12_c.effective_access (user_id, document_id, role, created_at)
WITH RECURSIVE vis AS (
  SELECT m.user_id, m.scope_id AS id, m.role FROM ch12_c.memberships m
  UNION
  SELECT v.user_id, s.id, v.role FROM ch12_c.scopes s JOIN vis v ON s.parent_id = v.id
)
SELECT DISTINCT ON (v.user_id, d.id) v.user_id, d.id, v.role, d.created_at
  FROM vis v JOIN ch12_c.documents d ON d.project_id = v.id
 ORDER BY v.user_id, d.id, v.role;

\echo '=== (4) 索引を作る（データを入れてから。一覧は user_id + created_at 降順で引く） ==='
-- 主キー (user_id, document_id) では「新しい順に 20 件」に効かない。
-- 一覧のための索引を別に張る。これも案C の費用である。
-- 🔴 入れ直しでも同じ結果になるように先に落とす（TRUNCATE では索引は消えない）。
DROP INDEX IF EXISTS ch12_c.effective_access_user_created;
CREATE INDEX effective_access_user_created
  ON ch12_c.effective_access (user_id, created_at DESC);

ANALYZE ch12_c.effective_access;

\echo '=== (5) 行数とサイズ（元データとの比） ==='
SELECT (SELECT count(*) FROM ch12_c.effective_access) AS effective_rows,
       (SELECT count(*) FROM ch12_c.documents)        AS documents,
       round((SELECT count(*) FROM ch12_c.effective_access)::numeric
             / (SELECT count(*) FROM ch12_c.documents), 1) AS times_source_rows;

SELECT 'effective_access' AS tbl,
       pg_size_pretty(pg_relation_size('ch12_c.effective_access'))       AS heap,
       pg_size_pretty(pg_indexes_size('ch12_c.effective_access'))        AS indexes,
       pg_size_pretty(pg_total_relation_size('ch12_c.effective_access')) AS total
UNION ALL
SELECT 'documents',
       pg_size_pretty(pg_relation_size('ch12_c.documents')),
       pg_size_pretty(pg_indexes_size('ch12_c.documents')),
       pg_size_pretty(pg_total_relation_size('ch12_c.documents'))
UNION ALL
SELECT 'memberships',
       pg_size_pretty(pg_relation_size('ch12_c.memberships')),
       pg_size_pretty(pg_indexes_size('ch12_c.memberships')),
       pg_size_pretty(pg_total_relation_size('ch12_c.memberships'));

\echo '=== (6) 判定表が元データと一致すること（先頭列が 0 であること） ==='
-- 🔴 作った直後は一致するのが当たり前だが、ここを測っておかないと
--    あとで「ズレを検出できる検査がある」ことを示せない（50_drift.sql が使う）。
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
