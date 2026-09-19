-- 申請・状態の遷移・内容の版を生成する。
--   SIZE=S … 申請 10 万（読者が手元で数分以内に再現できる量）
--   SIZE=M … 申請 100 万（案の差が読み取れる量）
--
-- 🔴 この章で偏らせるのは「状態の分布」である。
--    全申請が一様に散らばっていると、一覧の「申請中を新しい順に 20 件」が
--    1,000 行に 1 行ではなく 5 行に 1 行ヒットしてしまい、部分インデックスの有無で差が出ない。
--    実際の運用と同じく、ほとんどの申請は終わった状態（支払済み・差戻し）にある。
--
--    偏らせ方: 申請中 1%・差戻しのまま 4%・支払済み 95%。
--    「差戻しのまま止まっている申請」を残す（差戻しを経て承認された申請と、
--    差戻されたまま放置された申請は、一覧の見え方が違う）。
--
-- 🔴 `WITH ... AS MATERIALIZED` を必ず付ける。付けないと random() が外側で再評価され、
--    決めた状態と、その状態に至る遷移の並びが食い違う（第7章で踏んだ）。
-- 🔴 配列の添字には floor() を使う。::int は四捨五入なので 0 や範囲外になる（第7章で踏んだ）。
--
-- setseed で乱数の種を固定するので、何度実行しても同じ値になる。

SELECT CASE :'size' WHEN 'S' THEN 100000 WHEN 'M' THEN 1000000
       ELSE 1/0 END AS n_req \gset

\timing on
SELECT setseed(0.42);

TRUNCATE ch09_r.src_revision;
TRUNCATE ch09_r.src_transition;
TRUNCATE ch09_r.src_request CASCADE;
TRUNCATE ch09_r.src_employee CASCADE;
TRUNCATE ch09_r.src_category CASCADE;

\echo '生成する申請数:' :n_req

-- 社員 1,000 人
INSERT INTO ch09_r.src_employee (id, name, dept)
SELECT g,
       '社員' || g,
       (ARRAY['営業','開発','管理','人事'])[1 + floor(random() * 4)::int]
FROM generate_series(1, 1000) AS g;

-- 経費の科目
INSERT INTO ch09_r.src_category (id, code, name)
VALUES (1, 'travel',   '旅費交通費'),
       (2, 'supply',   '消耗品費'),
       (3, 'entertain','接待交際費'),
       (4, 'book',     '新聞図書費'),
       (5, 'comm',     '通信費');

-- 申請。2 年分に散らす
INSERT INTO ch09_r.src_request (id, applicant_id, created_at)
SELECT g,
       1 + floor(random() * 1000)::int,
       TIMESTAMPTZ '2024-01-01 00:00:00+09'
         + (floor(random() * 730))::int * INTERVAL '1 day'
         + (floor(random() * 86400))::int * INTERVAL '1 second'
FROM generate_series(1, :n_req) AS g;

-- 状態の遷移。
-- 到達する最終状態を先に決め、そこに至る経路を展開する。
--   申請中        1%: 下書き → 申請中（2 行）
--   差戻しのまま  4%: 下書き → 申請中 → 差戻し（3 行）
--   支払済み     95%: 下書き → 申請中 → 承認 → 支払済み（4 行）
--     うち 1/5 は差戻しを 1 回挟む（下書き → 申請中 → 差戻し → 申請中 → 承認 → 支払済み。6 行）
-- 平均すると 1 件あたり約 4.3 行になる。
--
-- 🔴 分岐は 1 つの乱数で決める。CASE の枝ごとに random() を呼ぶと、
--    2 つ目以降は「1 つ目を通過した残り」に対する確率になり、意図した割合にならない。
--
-- 経路は配列で持ち、unnest で行に開く。
WITH rolled AS MATERIALIZED (
  SELECT r.id AS request_id,
         r.created_at,
         r.applicant_id,
         random()                        AS dice,
         -- 承認者は申請者と別の人にする
         1 + floor(random() * 1000)::int AS approver_id,
         -- 1 回の遷移にかかる時間（時間単位）。0.5〜48 時間
         0.5 + random() * 47.5           AS step_hours
  FROM ch09_r.src_request r
),
picked AS (
  SELECT request_id, created_at, applicant_id, approver_id, step_hours,
         CASE
           WHEN dice < 0.01 THEN ARRAY['draft','submitted']
           WHEN dice < 0.05 THEN ARRAY['draft','submitted','rejected']
           WHEN dice < 0.24 THEN ARRAY['draft','submitted','rejected','submitted','approved','paid']
           ELSE                  ARRAY['draft','submitted','approved','paid']
         END AS path
  FROM rolled
)
INSERT INTO ch09_r.src_transition
  (request_id, seq, from_status, to_status, changed_by, changed_at, note)
SELECT p.request_id,
       s.ord,
       CASE WHEN s.ord = 1 THEN NULL ELSE p.path[s.ord - 1] END,
       s.st,
       -- 申請者が出し、それ以降は承認者が動かす
       CASE WHEN s.st IN ('draft','submitted') THEN p.applicant_id ELSE p.approver_id END,
       p.created_at + (s.ord - 1) * (p.step_hours * INTERVAL '1 hour'),
       CASE WHEN s.st = 'rejected' THEN '領収書の添付がありません' ELSE NULL END
FROM picked p
CROSS JOIN LATERAL unnest(p.path) WITH ORDINALITY AS s(st, ord);

-- 内容の版。1 件につき 1〜4 版（平均 3 版 ＝ 修正 2 回）。
-- 版 1 は申請の作成時刻。版 2 以降は、作成から 1〜72 時間後に順に並ぶ。
WITH picked AS MATERIALIZED (
  SELECT r.id AS request_id,
         r.created_at,
         r.applicant_id,
         -- 1〜4 の版数。2 と 3 が出やすいようにする
         (ARRAY[1,2,3,3,4])[1 + floor(random() * 5)::int] AS n_rev,
         1000 + floor(random() * 99000)::int AS base_amount,
         1 + floor(random() * 5)::int        AS category_id
  FROM ch09_r.src_request r
)
INSERT INTO ch09_r.src_revision
  (request_id, rev, amount_yen, category_id, reason, edited_by, valid_from)
SELECT p.request_id,
       g,
       -- 修正のたびに金額が動く（減額・増額の両方）
       p.base_amount + (g - 1) * 350,
       p.category_id,
       CASE g WHEN 1 THEN '取引先訪問の交通費' ELSE '訂正 ' || (g - 1) || ' 回目' END,
       p.applicant_id,
       p.created_at + (g - 1) * INTERVAL '18 hours'
FROM picked p
CROSS JOIN LATERAL generate_series(1, p.n_rev) AS g;

\timing off

-- 生成できた件数（本文の数値はここから取る。reltuples からは取らない）
SELECT 'src_request'    AS t, count(*) FROM ch09_r.src_request
UNION ALL SELECT 'src_transition', count(*) FROM ch09_r.src_transition
UNION ALL SELECT 'src_revision',   count(*) FROM ch09_r.src_revision
ORDER BY 1;

-- 最終状態の分布（偏りが意図どおりか）
SELECT last_status, count(*) AS n
FROM (
  SELECT DISTINCT ON (request_id) request_id, to_status AS last_status
  FROM ch09_r.src_transition
  ORDER BY request_id, seq DESC
) s
GROUP BY last_status
ORDER BY n DESC;
