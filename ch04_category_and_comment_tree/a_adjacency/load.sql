-- 元データを写す。インデックスはデータを入れてから作る（充填率を一定にするため）
SELECT count(*) AS src_rows FROM ch04_r.src_thread \gset
SELECT CASE WHEN :src_rows = 0
            THEN 1/0 ELSE 1 END AS source_must_not_be_empty;  -- 空なら何も消さずに止まる

\timing on
TRUNCATE ch04_a.nodes RESTART IDENTITY CASCADE;
DROP INDEX IF EXISTS ch04_a.nodes_parent_idx;

-- 親は必ず子より小さい id を持つので、id の順に入れれば外部キーを満たす
INSERT INTO ch04_a.nodes (id, parent_id, body, pos)
OVERRIDING SYSTEM VALUE
SELECT id, parent_id, body, pos FROM ch04_r.src_thread ORDER BY id;

SELECT setval(pg_get_serial_sequence('ch04_a.nodes', 'id'),
              (SELECT max(id) FROM ch04_a.nodes));

-- 直下の子を引くインデックス。並び順も一緒に持つので、表示順のまま取り出せる
CREATE INDEX nodes_parent_idx ON ch04_a.nodes (parent_id, pos, id);

ANALYZE ch04_a.nodes;
