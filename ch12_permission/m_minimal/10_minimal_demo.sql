-- run-as: book_owner
-- standalone
-- 「1 件ずつ判定する関数」と「集合として結合する」の差を、最小の形で見る。
--
-- 🔴 このファイルだけで完結する（元データの生成を待たずに実行できる）。
--    本章の中心の主張を、読者が手元で 10 秒で再現するために置いてある。
--    規模は小さいので、時間の比ではなく **関数の実行回数** を見る。
--
-- 本番の測定は S サイズ（利用者 1,000・文書 10 万）で行う。
-- そちらは 20_read_func.sql と 21_read_set.sql を使う。
CREATE SCHEMA IF NOT EXISTS ch12_m;

DROP TABLE IF EXISTS ch12_m.memberships;
DROP TABLE IF EXISTS ch12_m.documents;
DROP TABLE IF EXISTS ch12_m.scopes;

CREATE TABLE ch12_m.scopes (
  id        bigint PRIMARY KEY,
  parent_id bigint REFERENCES ch12_m.scopes(id)
);

CREATE TABLE ch12_m.documents (
  id         bigint      PRIMARY KEY,
  project_id bigint      NOT NULL REFERENCES ch12_m.scopes(id),
  created_at timestamptz NOT NULL
);

CREATE TABLE ch12_m.memberships (
  user_id  bigint NOT NULL,
  scope_id bigint NOT NULL REFERENCES ch12_m.scopes(id)
);

-- 組織 1 → チーム 2 → プロジェクト 3・4
INSERT INTO ch12_m.scopes (id, parent_id)
VALUES (1, NULL), (2, 1), (3, 2), (4, 2);

-- 文書 2,000 件。プロジェクト 3 と 4 に交互に入れる
INSERT INTO ch12_m.documents (id, project_id, created_at)
SELECT g, 3 + (g % 2), now() - (g || ' minutes')::interval
  FROM generate_series(1, 2000) AS g
 ORDER BY g;

-- 利用者 1 はプロジェクト 4 だけに所属する（見える文書は半分）
INSERT INTO ch12_m.memberships (user_id, scope_id) VALUES (1, 4);

-- 🔴 データを入れてからインデックスを作る（充填率が実行のたびに変わらないように）
CREATE INDEX ON ch12_m.documents (created_at DESC);
CREATE INDEX ON ch12_m.memberships (user_id);

ANALYZE ch12_m.scopes;
ANALYZE ch12_m.documents;
ANALYZE ch12_m.memberships;

CREATE OR REPLACE FUNCTION ch12_m.can_view(p_user bigint, p_doc bigint)
RETURNS boolean AS $$
  SELECT EXISTS (
    WITH RECURSIVE anc AS (
      SELECT s.id, s.parent_id FROM ch12_m.scopes s
       WHERE s.id = (SELECT project_id FROM ch12_m.documents WHERE id = p_doc)
      UNION ALL
      SELECT s.id, s.parent_id
        FROM ch12_m.scopes s JOIN anc ON s.id = anc.parent_id)
    SELECT 1 FROM ch12_m.memberships m JOIN anc ON anc.id = m.scope_id
     WHERE m.user_id = p_user);
$$ LANGUAGE sql STABLE;

\echo '=== (1) 1 件ずつ判定する関数を WHERE に置く ==='
-- 🔴 見るのは Rows Removed by Filter。これが関数の実行回数である。
EXPLAIN (ANALYZE)
SELECT d.id FROM ch12_m.documents d
 WHERE ch12_m.can_view(1, d.id)
 ORDER BY d.created_at DESC LIMIT 20;

\echo '=== (2) 見える範囲を集合として作り、結合する ==='
EXPLAIN (ANALYZE)
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_m.memberships m WHERE m.user_id = 1
  UNION
  SELECT s.id FROM ch12_m.scopes s JOIN vis ON s.parent_id = vis.id)
SELECT d.id FROM ch12_m.documents d JOIN vis ON vis.id = d.project_id
 ORDER BY d.created_at DESC LIMIT 20;

\echo '=== 🔴 2 つの書き方が同じ結果を返すこと（先頭列が 0 であること） ==='
-- 🔴 対称差は括弧で囲む。囲まないと片方向にしか働かない。
WITH RECURSIVE vis AS (
  SELECT m.scope_id AS id FROM ch12_m.memberships m WHERE m.user_id = 1
  UNION
  SELECT s.id FROM ch12_m.scopes s JOIN vis ON s.parent_id = vis.id),
set_result  AS (SELECT d.id FROM ch12_m.documents d JOIN vis ON vis.id = d.project_id),
func_result AS (SELECT d.id FROM ch12_m.documents d WHERE ch12_m.can_view(1, d.id))
SELECT count(*) AS diff_rows,
       (SELECT count(*) FROM set_result)  AS set_rows,
       (SELECT count(*) FROM func_result) AS func_rows
  FROM ((SELECT id FROM set_result  EXCEPT SELECT id FROM func_result)
        UNION ALL
        (SELECT id FROM func_result EXCEPT SELECT id FROM set_result)) t;
