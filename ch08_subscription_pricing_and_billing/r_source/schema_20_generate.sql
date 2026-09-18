-- 契約と料金の版を生成する。
--   SIZE=S … 契約 1 万・プラン 5・版 25（読者が手元で数分以内に再現できる量）
--   SIZE=M … 契約 100 万・プラン 5・版 50（案の差が読み取れる量）
--
-- 🔴 この章で偏らせるのは「1 人あたりの件数」ではなく「月の途中でプランを変えた契約の割合」である。
--    全契約が月初から月末まで同じプランなら、日割りの計算が 1 行も動かず、
--    丸めの差も日割りの差も測れない。実際のサービスと同じく、一部の契約だけが月の途中で動く。
--
--    偏らせ方: 契約の 10% が対象月の途中でプランを変える。
--    さらに契約の 20% を「据え置き」（旧料金のまま）にする。
--
-- 🔴 料金の改定日を、月初にそろえない。
--    月初にそろえると、契約の期間と料金の期間の境目が一致してしまい、
--    「月の途中で料金が変わる契約」が 1 件も出ない。制度上の端数処理の差も測れなくなる。
--
-- setseed で乱数の種を固定するので、何度実行しても同じ値になる。
SELECT CASE :'size' WHEN 'S' THEN 10000 WHEN 'M' THEN 1000000
       ELSE 1/0 END AS n_subs \gset
SELECT CASE :'size' WHEN 'S' THEN 5 WHEN 'M' THEN 10
       ELSE 1/0 END AS n_versions \gset

\timing on
SELECT setseed(0.42);

TRUNCATE ch08_r.src_sub_period;
TRUNCATE ch08_r.src_subscription CASCADE;
TRUNCATE ch08_r.src_price;
TRUNCATE ch08_r.src_plan CASCADE;

\echo '生成する契約数:' :n_subs '  1 プランあたりの料金の版:' :n_versions

-- プランは 5 つ。料金の桁を変えて、日割りの端数が出やすい額にしている
-- （980・1,480 のような額は、日割りにすると必ず小数が出る）。
INSERT INTO ch08_r.src_plan (id, code, name)
VALUES (1, 'lite',     'ライト'),
       (2, 'standard', 'スタンダード'),
       (3, 'pro',      'プロ'),
       (4, 'business', 'ビジネス'),
       (5, 'entpr',    'エンタープライズ');

-- 料金の版。2022-01-01 から、プランごとに n_versions 回に分けて改定する。
-- 期間は半開区間で切れ目なく続き、最後の行は上端なし（無限）にする。
--
-- 🔴 改定日を 1 日から 28 日の範囲でずらす。月初にそろえない理由は冒頭のとおり。
WITH v AS MATERIALIZED (
  SELECT p.id AS plan_id,
         g    AS seq,
         -- 改定日: 6 か月ごと + 0〜27 日のずれ
         (DATE '2022-01-01' + (g - 1) * INTERVAL '6 months'
            + (floor(random() * 28))::int * INTERVAL '1 day')::date AS from_on
  FROM ch08_r.src_plan p
  CROSS JOIN generate_series(1, :n_versions) AS g
),
w AS (
  SELECT plan_id, seq,
         -- 最初の版は 2022-01-01 から始める（ずらすと開始前の契約が覆えない）
         CASE WHEN seq = 1 THEN DATE '2022-01-01' ELSE from_on END AS from_on,
         lead(CASE WHEN seq = 1 THEN DATE '2022-01-01' ELSE from_on END)
           OVER (PARTITION BY plan_id ORDER BY seq) AS to_on
  FROM v
)
INSERT INTO ch08_r.src_price (id, plan_id, valid, price_yen)
SELECT row_number() OVER (ORDER BY plan_id, seq),
       plan_id,
       daterange(from_on, to_on),     -- to_on が NULL なら上端なし
       -- 基本額 × プラン + 改定のたびに 8% ずつ値上げ。端数が出る額にする
       (CASE plan_id WHEN 1 THEN 980 WHEN 2 THEN 1480 WHEN 3 THEN 2980
                     WHEN 4 THEN 5980 ELSE 9800 END
        * pow(1.08, seq - 1))::int
FROM w;

INSERT INTO ch08_r.src_subscription (id, customer_id, started_on)
SELECT g, g,
       -- 契約の開始日は 2022-01-01 から 2024-06-30 の間に散らす
       (DATE '2022-01-01' + (floor(random() * 911))::int * INTERVAL '1 day')::date
FROM generate_series(1, :n_subs) AS g;

-- 契約 × プランの期間。
-- 10% の契約は、対象月（2024-04）の途中でプランを変える。残りは 1 行のまま。
--
-- 🔴 WITH ... AS MATERIALIZED を必ず付ける。付けないと random() が外側で再評価され、
--    「プランを変える契約」の判定と、実際に入れる行数が食い違う。
WITH s AS MATERIALIZED (
  SELECT sub.id, sub.started_on,
         (random() < 0.10) AS changes_plan,
         (random() < 0.20) AS grandfathered,
         (1 + floor(random() * 5))::int AS plan_id,
         -- 変更日は 2024-04 の 2 日〜28 日
         (DATE '2024-04-01' + (1 + floor(random() * 27))::int * INTERVAL '1 day')::date AS change_on
  FROM ch08_r.src_subscription sub
),
rows AS (
  -- 変えない契約: 開始から無期限の 1 行
  SELECT id AS subscription_id, plan_id, daterange(started_on, NULL) AS period,
         grandfathered, 0 AS ord
  FROM s WHERE NOT changes_plan
  UNION ALL
  -- 変える契約: 開始 〜 変更日 の行と、変更日 〜 無期限 の行
  SELECT id, plan_id, daterange(started_on, change_on), grandfathered, 0
  FROM s WHERE changes_plan AND started_on < change_on
  UNION ALL
  SELECT id,
         -- 変更後は別のプランにする（同じだと変更にならない）
         1 + (plan_id % 5),
         daterange(change_on, NULL), grandfathered, 1
  FROM s WHERE changes_plan AND started_on < change_on
  UNION ALL
  -- 変更日より後に始まった契約は、変えずに 1 行
  SELECT id, plan_id, daterange(started_on, NULL), grandfathered, 0
  FROM s WHERE changes_plan AND started_on >= change_on
)
INSERT INTO ch08_r.src_sub_period (id, subscription_id, plan_id, period, grandfathered_yen)
SELECT row_number() OVER (ORDER BY subscription_id, ord),
       subscription_id, plan_id, period,
       -- 据え置きの契約だけ、その期間の開始時点の料金を焼き付ける。
       -- 以後の改定に追従しない、という意味になる
       CASE WHEN grandfathered THEN (
         SELECT pr.price_yen FROM ch08_r.src_price pr
         WHERE pr.plan_id = rows.plan_id AND pr.valid @> lower(rows.period)
       ) END
FROM rows;

ANALYZE ch08_r.src_plan;
ANALYZE ch08_r.src_price;
ANALYZE ch08_r.src_subscription;
ANALYZE ch08_r.src_sub_period;

\echo '--- 生成した行数 ---'
SELECT (SELECT count(*) FROM ch08_r.src_plan)         AS plans,
       (SELECT count(*) FROM ch08_r.src_price)        AS prices,
       (SELECT count(*) FROM ch08_r.src_subscription) AS subscriptions,
       (SELECT count(*) FROM ch08_r.src_sub_period)   AS sub_periods,
       (SELECT count(*) FROM ch08_r.src_sub_period
          WHERE grandfathered_yen IS NOT NULL)        AS grandfathered,
       (SELECT count(*) FROM ch08_r.src_sub_period
          WHERE period && daterange('2024-04-01','2024-05-01')
            AND NOT (period @> daterange('2024-04-01','2024-05-01'))) AS partial_in_april;
