-- 元データを作る。各案の load.sql より先に実行する。
-- SIZE=S は 10 万記事、M は 100 万記事、L は 1,000 万記事
SELECT CASE :'size' WHEN 'S' THEN 100000 WHEN 'M' THEN 1000000
                    WHEN 'L' THEN 10000000 END AS n \gset
SELECT :n AS rows_to_load;   -- S・M・L 以外なら、ここで構文エラーになって止まる

\timing on
TRUNCATE ch03_r.article_tags_src;
TRUNCATE ch03_r.articles_src;
TRUNCATE ch03_r.tags_src;
SELECT setseed(0.42);

-- タグ 165 種類。出現率は順位ごとに 0.95 倍（tag001 が最も多く、tag165 が最も少ない）
INSERT INTO ch03_r.tags_src (id, name)
SELECT g, 'tag' || lpad(g::text, 3, '0') FROM generate_series(1, 165) AS g;

-- 各タグの累積確率。乱数 1 つからタグ 1 つを決めるために使う
DROP TABLE IF EXISTS ch03_r.cum;
CREATE TABLE ch03_r.cum AS
SELECT id,
       sum(w) OVER (ORDER BY id) / sum(w) OVER () AS upper_bound,
       coalesce(sum(w) OVER (ORDER BY id ROWS BETWEEN UNBOUNDED PRECEDING
                             AND 1 PRECEDING), 0) / sum(w) OVER ()
         AS lower_bound
FROM (SELECT id, power(0.95, id - 1) AS w FROM ch03_r.tags_src) AS t;
CREATE INDEX cum_bounds_idx ON ch03_r.cum (lower_bound, upper_bound);

INSERT INTO ch03_r.articles_src (id, title, body, published_at)
SELECT g,
       'article-' || g,
       repeat('x', 200),
       -- 公開日時は id の順とわざとずらす（id 順 = 新しい順、を前提にできないようにする）
       '2024-01-01 00:00+09'::timestamptz
         + (g + (hashint8(g) % 1000)) * (interval '900 days' / :n)
FROM generate_series(1, :n) AS g;

-- 🔴 乱数は先に列として引いておく。LATERAL の中で random() を書くと、
-- 1 度だけ評価されて全記事が同じ値になる（実測で全記事が同じタグ 1 個になった）
DROP TABLE IF EXISTS ch03_r.draw;
CREATE TABLE ch03_r.draw AS
SELECT g AS id,
       -- タグの個数。1 個が 65%、5 個が 1%
       CASE WHEN k < 0.65 THEN 1 WHEN k < 0.80 THEN 2 WHEN k < 0.92 THEN 3
            WHEN k < 0.99 THEN 4 ELSE 5 END AS n_tags,
       r1, r2, r3, r4, r5
FROM (
  SELECT g, random() AS k, random() AS r1, random() AS r2, random() AS r3,
         random() AS r4, random() AS r5
  FROM generate_series(1, :n) AS g
  ORDER BY g
) AS s;

-- 記事ごとに n_tags 個の乱数を縦に並べ、それぞれを累積確率でタグに直す。
-- 同じ記事に同じタグが 2 回出ることがあるので、記事ごとに重複を落とす。
-- 🔴 全体に DISTINCT を掛けると 1,000 万記事では巨大なソートになる（L で 5 分を超えた）。
-- 記事ごとの配列にまとめてから重複を落とすと、記事の単位で処理が閉じる
INSERT INTO ch03_r.article_tags_src (article_id, tag_id)
SELECT d.id, t.tag_id
FROM ch03_r.draw d
CROSS JOIN LATERAL unnest((
  SELECT array_agg(DISTINCT c.id)
  FROM (VALUES (1, d.r1), (2, d.r2), (3, d.r3), (4, d.r4), (5, d.r5)) AS v(k, r)
  JOIN ch03_r.cum c ON v.r >= c.lower_bound AND v.r < c.upper_bound
  WHERE v.k <= d.n_tags
)) AS t(tag_id);

DROP TABLE ch03_r.draw;

-- 🔴 ANALYZE を忘れると、次に読む側（案B の load）が古い統計で計画を立て、
-- 10 倍のデータより遅くなることがある（第3章の確認記録 §0）
ANALYZE ch03_r.tags_src;
ANALYZE ch03_r.articles_src;
ANALYZE ch03_r.article_tags_src;
