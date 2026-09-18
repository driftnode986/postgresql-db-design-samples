-- 元データを写す。path は NOT NULL なので、経路を組み立てながら 1 文で入れる
-- （先に行だけ入れてあとで経路を埋める 2 段構えにすると、最初の INSERT が
--   null value in column "path" violates not-null constraint で落ちる）
SELECT count(*) AS src_rows FROM ch04_r.src_thread \gset
SELECT CASE WHEN :src_rows = 0
            THEN 1/0 ELSE 1 END AS source_must_not_be_empty;

\timing on
TRUNCATE ch04_c.nodes RESTART IDENTITY CASCADE;
DROP INDEX IF EXISTS ch04_c.nodes_parent_idx;
DROP INDEX IF EXISTS ch04_c.nodes_path_gist;

INSERT INTO ch04_c.nodes (id, parent_id, path, body, pos)
OVERRIDING SYSTEM VALUE
WITH RECURSIVE p AS (
  SELECT id, parent_id, body, pos, text2ltree(id::text) AS path
  FROM ch04_r.src_thread WHERE parent_id IS NULL
  UNION ALL
  SELECT c.id, c.parent_id, c.body, c.pos, p.path || text2ltree(c.id::text)
  FROM ch04_r.src_thread c JOIN p ON c.parent_id = p.id
)
SELECT id, parent_id, path, body, pos FROM p ORDER BY id;

SELECT setval(pg_get_serial_sequence('ch04_c.nodes', 'id'),
              (SELECT max(id) FROM ch04_c.nodes));

-- 子孫の判定（<@）に使えるインデックスは GiST だけ。B-tree は < <= = >= > しか扱えない
CREATE INDEX nodes_path_gist ON ch04_c.nodes USING gist (path);
-- 直下の子は経路ではなく親の列で引く（経路のインデックスより速い）
CREATE INDEX nodes_parent_idx ON ch04_c.nodes (parent_id, pos, id);

ANALYZE ch04_c.nodes;
