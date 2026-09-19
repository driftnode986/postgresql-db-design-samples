-- 階層・利用者・文書・所属を生成する。
--   SIZE=S … 利用者 1,000・文書 10 万（読者が手元で数分以内に再現できる量）
--   SIZE=M … 利用者 10,000・文書 100 万（案の差が読み取れる量）
--
-- 🔴 この章で偏らせるのは「所属の広さ」である。階層の深さではない。
--    深さ 2 → 12 で時間は 1.5 倍にしかならないが（d_depth/）、
--    「全員が入る大きなチーム」があると案C の行数が桁で変わる
--    （docs/research/ch12_verification.md §1・§7・§8）。
--
--    そこで次の 2 つを両方作る:
--      - team1 に利用者 **全員** を viewer で入れる（= 大きなチーム）
--      - それとは別に、各利用者はプロジェクトに 0〜4 個 editor で所属する
--    さらに比較のため、**利用者7 だけ team1 の所属を外す**。
--    利用者7 は「見える文書が少ない利用者」、利用者42 は「大きなチーム込みの利用者」になる。
--
-- 🔴 文書もプロジェクトに偏らせる（floor(400 * power(random(), 2)) で人気プロジェクトに集中）。
--    均等に散らすと、どのプロジェクトも同じ文書数になり、
--    「移すプロジェクト次第で作り直す行数が変わる」現象が再現しない。
--
-- 🔴 WITH ... AS MATERIALIZED を付ける。付けないと random() が外側で再評価され、
--    決めた値と入った値が食い違う（第7章・第10章・第11章で踏んだ）。
--
-- 🔴 添字には floor() を使う。::int は四捨五入なので範囲外になる（第10章の教訓）。
--
-- setseed で乱数の種を固定するので、何度実行しても同じ値になる。
-- XS は検査を速く回すためだけの量（案C の判定表が 2,253 万行あると
-- verify-examples-build.sh が 30 分かかる）。偏りの作り方は S・M と同じなので、
-- 「大きなチームが判定表の大半を占める」という構造はそのまま再現する。
-- 🔴 本文に載せる測定値は S。XS の値を本文に書かない。
SELECT CASE :'size' WHEN 'XS' THEN 200    WHEN 'S' THEN 1000   WHEN 'M' THEN 10000
       ELSE 1/0 END AS n_user \gset
SELECT CASE :'size' WHEN 'XS' THEN 5000   WHEN 'S' THEN 100000 WHEN 'M' THEN 1000000
       ELSE 1/0 END AS n_doc \gset

-- 階層の形は S と M で変えない（深さは効かないことが分かっているので、
-- 変えるのは利用者と文書の数だけにして、比較の軸を 1 つに絞る）。
-- 組織1 → チーム20 → プロジェクト400（チームごとに 20）の深さ3。文書はその下。
\set n_team 20
\set n_project 400

\timing on

SELECT setseed(0.42);

-- 🔴 入れ直しても同じ結果になるようにする（2 回実行して行が倍にならない）
TRUNCATE ch12_r.src_membership;
TRUNCATE ch12_r.src_document;
TRUNCATE ch12_r.src_user CASCADE;
TRUNCATE ch12_r.src_scope CASCADE;

\echo '生成する利用者数:' :n_user
\echo '生成する文書数:' :n_doc

-- 組織（id = 1）
INSERT INTO ch12_r.src_scope (id, parent_id, kind, name, path)
VALUES (1, NULL, 'org', '組織1', 'n1'::public.ltree);

-- チーム（id = 2..21）。team1 が「全員が入る大きなチーム」になる
INSERT INTO ch12_r.src_scope (id, parent_id, kind, name, path)
SELECT 1 + g, 1, 'team', 'team' || g,
       ('n1.n' || (1 + g))::public.ltree
  FROM generate_series(1, :n_team) AS g;

-- プロジェクト（id = 22..421）。チームごとに 20 個
INSERT INTO ch12_r.src_scope (id, parent_id, kind, name, path)
SELECT 1 + :n_team + g,
       1 + 1 + ((g - 1) / (:n_project / :n_team)),          -- 親のチーム
       'project', 'project' || g,
       ('n1.n' || (1 + 1 + ((g - 1) / (:n_project / :n_team)))
             || '.n' || (1 + :n_team + g))::public.ltree
  FROM generate_series(1, :n_project) AS g;

INSERT INTO ch12_r.src_user (id, login)
SELECT g, 'user' || g FROM generate_series(1, :n_user) AS g;

-- 文書。プロジェクトに偏らせる（power(random(), 2) で小さい id に集中）
INSERT INTO ch12_r.src_document (id, project_id, title, created_at)
WITH base AS MATERIALIZED (
  SELECT g,
         -- プロジェクトの id は 1 + n_team + 1 .. 1 + n_team + n_project
         1 + :n_team + 1 + floor(:n_project * power(random(), 2))::bigint AS project_id,
         floor(random() * 365)::int  AS day_ago,
         floor(random() * 86400)::int AS sec_ago
    FROM generate_series(1, :n_doc) AS g
)
SELECT g, project_id, '文書' || g,
       -- 🔴 今から過去へ向かって引く。足すと未来の日付ができる（第11章で踏んだ）
       now() - make_interval(days => day_ago) - make_interval(secs => sec_ago)
  FROM base
 ORDER BY g;

-- 所属。id は連番で付けるので、2 段に分けて入れたあと row_number で振り直す。
--
-- (1) 大きなチーム team1（scope id = 2）に、利用者7 以外の全員を viewer で入れる
-- (2) 各利用者は、プロジェクトに 0〜4 個 editor で所属する
--     🔴 利用者7 には必ず 3 件付ける（見える文書が少ない利用者の比較対象を作るため、
--        0 件になって「1 件も見えない」利用者にしない）
CREATE TEMP TABLE tmp_m (user_id bigint, scope_id bigint, role text);

INSERT INTO tmp_m (user_id, scope_id, role)
SELECT u.id, 2, 'viewer'
  FROM ch12_r.src_user u
 WHERE u.id <> 7
 ORDER BY u.id;

INSERT INTO tmp_m (user_id, scope_id, role)
WITH per_user AS MATERIALIZED (
  SELECT u.id AS user_id,
         CASE WHEN u.id = 7 THEN 3 ELSE floor(random() * 5)::int END AS n_proj
    FROM ch12_r.src_user u
)
SELECT p.user_id,
       1 + :n_team + 1 + floor(:n_project * random())::bigint,
       'editor'
  FROM per_user p, generate_series(1, 4) AS g
 WHERE g <= p.n_proj
 ORDER BY p.user_id, g;

-- 同じ利用者・同じ対象に 2 件できることがある（乱数が重なった場合）。
-- 役割が違えば実在しうる形だが、ここでは判定の集合が変わらないので畳んでおく。
INSERT INTO ch12_r.src_membership (id, user_id, scope_id, role)
SELECT row_number() OVER (ORDER BY user_id, scope_id, role),
       user_id, scope_id, role
  FROM (SELECT DISTINCT user_id, scope_id, role FROM tmp_m) t
 ORDER BY user_id, scope_id, role;

DROP TABLE tmp_m;

-- 索引は元データにも付ける（各案は自分で張り直す）
-- 🔴 TRUNCATE では索引は消えないので、入れ直しでも同じ結果になるように先に落とす
--    （落とさないと 2 回目の実行が「既にある」で止まる）。
DROP INDEX IF EXISTS ch12_r.src_scope_parent;
DROP INDEX IF EXISTS ch12_r.src_document_proj;
DROP INDEX IF EXISTS ch12_r.src_membership_u;

CREATE INDEX src_scope_parent  ON ch12_r.src_scope (parent_id);
CREATE INDEX src_document_proj ON ch12_r.src_document (project_id);
CREATE INDEX src_membership_u  ON ch12_r.src_membership (user_id);

ANALYZE ch12_r.src_scope;
ANALYZE ch12_r.src_user;
ANALYZE ch12_r.src_document;
ANALYZE ch12_r.src_membership;

\echo '=== 元データの件数 ==='
SELECT (SELECT count(*) FROM ch12_r.src_scope)      AS scopes,
       (SELECT count(*) FROM ch12_r.src_user)       AS users,
       (SELECT count(*) FROM ch12_r.src_document)   AS documents,
       (SELECT count(*) FROM ch12_r.src_membership) AS memberships;

\echo '=== 階層の形（種類ごとの件数と深さ） ==='
SELECT kind, count(*) AS n, min(public.nlevel(path)) AS min_level,
       max(public.nlevel(path)) AS max_level
  FROM ch12_r.src_scope GROUP BY kind ORDER BY min_level;

\echo '=== 🔴 未来の日付が無いこと（先頭列が 0 であること） ==='
SELECT count(*) AS documents_in_the_future
  FROM ch12_r.src_document WHERE created_at > now();

\echo '=== 文書の偏り（上位 5 プロジェクトの占める割合） ==='
SELECT project_id, count(*) AS docs,
       round(100.0 * count(*) / (SELECT count(*) FROM ch12_r.src_document), 1) AS pct
  FROM ch12_r.src_document GROUP BY project_id ORDER BY docs DESC LIMIT 5;

\echo '=== 所属の偏り（大きなチームに入っている利用者の数） ==='
SELECT (SELECT count(*) FROM ch12_r.src_membership WHERE scope_id = 2) AS in_big_team,
       (SELECT count(*) FROM ch12_r.src_user)                          AS users,
       (SELECT count(*) FROM ch12_r.src_membership WHERE user_id = 7)  AS user7_memberships,
       (SELECT count(*) FROM ch12_r.src_membership WHERE user_id = 42) AS user42_memberships;

\echo '=== 🔴 比較する 2 人の「見える文書の数」（本文が引用する値） ==='
-- ここで出る数は所属の乱数で決まる。確認記録（§0）の 378 件をそのまま書かず、
-- ここに出た値を本文に引用する。
WITH RECURSIVE vis AS (
  SELECT m.user_id, m.scope_id AS id FROM ch12_r.src_membership m WHERE m.user_id IN (7, 42)
  UNION
  SELECT v.user_id, s.id FROM ch12_r.src_scope s JOIN vis v ON s.parent_id = v.id
)
SELECT v.user_id,
       count(DISTINCT v.id) FILTER (WHERE s.kind = 'project') AS visible_projects,
       count(d.id)                                           AS visible_documents
  FROM vis v
  JOIN ch12_r.src_scope s ON s.id = v.id
  LEFT JOIN ch12_r.src_document d ON d.project_id = v.id
 GROUP BY v.user_id ORDER BY v.user_id;

\echo '=== 🔴 利用者7 が大きなチームに入っていないこと（先頭列が 0 であること） ==='
SELECT count(*) AS user7_in_big_team
  FROM ch12_r.src_membership WHERE user_id = 7 AND scope_id = 2;
