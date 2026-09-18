-- 元データの中身。案を作り直しても同じ木であることを、この出力で確かめる。
SELECT 'cat' AS tree, count(*) AS nodes, max(depth) AS max_depth,
       round(avg(depth), 2) AS avg_depth
FROM ch04_r.src_cat
UNION ALL
SELECT 'thread', count(*), max(depth), round(avg(depth), 2)
FROM ch04_r.src_thread;

-- 深さごとの件数（スレッド型は深いほど少なくなる）
SELECT depth, count(*) AS nodes FROM ch04_r.src_thread GROUP BY depth ORDER BY depth;
SELECT depth, count(*) AS nodes FROM ch04_r.src_cat    GROUP BY depth ORDER BY depth;

-- 木の形が同じであることの指紋
SELECT md5(string_agg(id || '>' || coalesce(parent_id, 0), ',' ORDER BY id)) AS thread_md5
FROM ch04_r.src_thread;
SELECT md5(string_agg(id || '>' || coalesce(parent_id, 0), ',' ORDER BY id)) AS cat_md5
FROM ch04_r.src_cat;

-- 本文で使う起点ノード。子孫の取得と直下の子は 11、パンくずは深さ 20 のノードを使う
SELECT 11 AS anchor_id,
       (SELECT depth FROM ch04_r.src_thread WHERE id = 11) AS anchor_depth,
       (SELECT count(*) FROM ch04_r.src_thread c WHERE c.parent_id = 11) AS anchor_children;
SELECT id AS deepest_id, depth AS deepest_depth
FROM ch04_r.src_thread WHERE depth = 20 ORDER BY id LIMIT 1;

-- 木として壊れていないこと（どちらも 0 になること）
SELECT count(*) AS orphan
FROM ch04_r.src_thread c
     LEFT JOIN ch04_r.src_thread p ON p.id = c.parent_id
WHERE c.parent_id IS NOT NULL AND p.id IS NULL;
SELECT count(*) AS parent_not_before_child
FROM ch04_r.src_thread WHERE parent_id >= id;
