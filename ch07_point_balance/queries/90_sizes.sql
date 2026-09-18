-- 4 案の保存サイズ。本体と索引を分けて出す。
-- 🔴 案ごとに表の数が違うので、案の合計で比べる（一覧の行だけを見て順位を付けない）
SELECT n.nspname AS schema, c.relname AS table_name,
       pg_size_pretty(pg_relation_size(c.oid))      AS heap,
       pg_size_pretty(pg_indexes_size(c.oid))       AS indexes,
       pg_size_pretty(pg_total_relation_size(c.oid)) AS total
FROM pg_class AS c JOIN pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname IN ('ch07_a', 'ch07_b', 'ch07_c', 'ch07_d') AND c.relkind = 'r'
ORDER BY n.nspname, c.relname;

-- 案ごとの合計（これで順位を付ける）
SELECT n.nspname AS schema,
       sum(pg_total_relation_size(c.oid))                  AS total_bytes,
       pg_size_pretty(sum(pg_total_relation_size(c.oid)))  AS total
FROM pg_class AS c JOIN pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname IN ('ch07_a', 'ch07_b', 'ch07_c', 'ch07_d') AND c.relkind = 'r'
GROUP BY n.nspname ORDER BY sum(pg_total_relation_size(c.oid));

-- 🔴 案D の締めの行は、取引が締めの間隔を超えた会員にだけできる。
--    「案D は案C より軽い」は、締めの行を持つ会員に限った話である（独立レビューで検出）
SELECT count(*) FILTER (WHERE s.user_id IS NOT NULL) AS users_with_snapshot,
       count(*) FILTER (WHERE s.user_id IS NULL)     AS users_without_snapshot
FROM ch07_r.src_user AS u
LEFT JOIN (SELECT DISTINCT user_id FROM ch07_d.point_snapshots) AS s
  ON s.user_id = u.id;

-- 🔴 生きたロットの件数の分布。案A の読む量はこれに比例する。
--    「数十件までなら問題ない」と書くなら、その帯に測定値があるかを見る
SELECT min(c) AS min_live_lots, max(c) AS max_live_lots,
       count(*) FILTER (WHERE c <= 100)  AS users_upto_100,
       count(*) FILTER (WHERE c > 100)   AS users_over_100
FROM (SELECT user_id, count(*) AS c FROM ch07_a.point_lots
      WHERE remaining > 0 AND expires_at > now() GROUP BY user_id) AS t;
