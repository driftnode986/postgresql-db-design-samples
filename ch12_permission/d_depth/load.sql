-- run-as: book_owner
-- 深さ 12 の鎖を 200 本作る。文書は最深部（lvl = 12）に 10,000 件。
--
-- 🔴 この章のほかの案と違い、元データ（ch12_r）からは写さない。
--    深さを変えるための専用の形であり、元データの形とは別物である。
\timing on

SELECT setseed(0.42);

TRUNCATE ch12_d.memberships;
TRUNCATE ch12_d.documents;
TRUNCATE ch12_d.scopes CASCADE;

\set n_chain 200
\set max_depth 12

-- 節点。id は (chain - 1) * max_depth + lvl で決める（親の計算が簡単になる）
-- 🔴 親は「同じ鎖の 1 つ上」。lvl = 1 は親なし
INSERT INTO ch12_d.scopes (id, parent_id, lvl, chain)
SELECT (c - 1) * :max_depth + l,
       CASE WHEN l = 1 THEN NULL ELSE (c - 1) * :max_depth + (l - 1) END,
       l, c
  FROM generate_series(1, :n_chain) AS c,
       generate_series(1, :max_depth) AS l
 ORDER BY c, l;

-- 文書は**すべての深さ**に散らす。
--
-- 🔴 ここを間違えると測定が成立しない。最初は「文書を最深部だけに置く」形で作ったが、
--    深さの上限を切ると**一覧が 0 件になり**、
--    「10,000 件を走査して 1 件も見つからない時間」（depth<=2 で 133 ms）を
--    測ることになった。深さの差ではなく、空振りの走査の差を測っていた。
--    深さごとに 0 件でない一覧が返るように、各深さに文書を置く。
INSERT INTO ch12_d.documents (id, project_id, title, created_at)
WITH base AS MATERIALIZED (
  SELECT g,
         1 + floor(:n_chain * random())::bigint AS chain,
         1 + floor(:max_depth * random())::int  AS lvl,
         floor(random() * 86400)::int           AS sec_ago
    FROM generate_series(1, 10000) AS g
)
SELECT b.g, (b.chain - 1) * :max_depth + b.lvl,
       '文書' || b.g,
       now() - make_interval(secs => b.sec_ago)
  FROM base b
 ORDER BY b.g;

-- 利用者1 は各鎖の最上位（lvl = 1）に所属する。
-- 文書に届くには 12 段たどる必要がある。
INSERT INTO ch12_d.memberships (id, user_id, scope_id, role)
SELECT row_number() OVER (ORDER BY s.id), 1, s.id, 'viewer'
  FROM ch12_d.scopes s WHERE s.lvl = 1 ORDER BY s.id;

-- 🔴 索引はデータを入れてから作る。
--    TRUNCATE では索引は消えないので、入れ直しでも同じ結果になるように先に落とす
--    （落とさないと 2 回目の実行が「既にある」で止まる）。
DROP INDEX IF EXISTS ch12_d.scopes_parent;
DROP INDEX IF EXISTS ch12_d.documents_created_at;
DROP INDEX IF EXISTS ch12_d.memberships_user;

CREATE INDEX scopes_parent ON ch12_d.scopes (parent_id);
CREATE INDEX documents_created_at ON ch12_d.documents (created_at DESC);
CREATE INDEX memberships_user ON ch12_d.memberships (user_id);

ANALYZE ch12_d.scopes;
ANALYZE ch12_d.documents;
ANALYZE ch12_d.memberships;

\echo '=== 深さの実験のデータ ==='
SELECT (SELECT count(*) FROM ch12_d.scopes)      AS scopes,
       (SELECT max(lvl) FROM ch12_d.scopes)      AS max_depth,
       (SELECT count(DISTINCT chain) FROM ch12_d.scopes) AS chains,
       (SELECT count(*) FROM ch12_d.documents)   AS documents,
       (SELECT count(*) FROM ch12_d.memberships) AS memberships;

\echo '=== 🔴 すべての深さに文書があること（先頭列が 0 であること） ==='
-- 1 つでも文書が無い深さがあると、その深さの測定が「0 件の走査」になる。
SELECT count(*) AS depths_without_documents
  FROM generate_series(1, (SELECT max(lvl) FROM ch12_d.scopes)) AS l
 WHERE NOT EXISTS (SELECT 1 FROM ch12_d.documents d
                     JOIN ch12_d.scopes s ON s.id = d.project_id
                    WHERE s.lvl = l);

\echo '--- 深さごとの文書数 ---'
SELECT s.lvl, count(*) AS docs
  FROM ch12_d.documents d JOIN ch12_d.scopes s ON s.id = d.project_id
 GROUP BY s.lvl ORDER BY s.lvl;

\echo '=== 🔴 所属がすべて最上位にあること（先頭列が 0 であること） ==='
SELECT count(*) AS memberships_not_at_top
  FROM ch12_d.memberships m JOIN ch12_d.scopes s ON s.id = m.scope_id
 WHERE s.lvl <> 1;
