-- 通知・利用者・既読を生成する。
--   SIZE=S … 通知 30 万（読者が手元で数分以内に再現できる量）
--   SIZE=M … 通知 1,000 万（案の差が読み取れる量）
--
-- 🔴 企画は M を 3 億行としていたが、Docker Desktop で約 8 分・43 GB になり
--    読者が再現できない。1,000 万行に下げた（docs/research/ch10_research.md §5）。
--    部分インデックスの倍率は S 19.3 / M 20.1 とデータ量にほとんど依らないので、
--    1,000 万行でも章の主張は変わらない。
--
-- 🔴 この章で偏らせるのは「未読の散らばり方」である。
--    未読 5% を全利用者に均等に散らすと、1 人あたりの未読が数件にしかならず、
--    未読の一覧を引く問い合わせで案の差が出ない（ch10_verification.md §2 で実際に踏んだ。
--    user_id = 42 の未読が 0 件だった）。
--    実際の運用でも未読は偏る。通知を放置する利用者に集中する。
--
--    偏らせ方: 利用者の 1% を「ためこむ人」とし、未読の 8 割をその 1% に集める。
--    残りの 2 割を全体に薄く散らす。
--
-- 🔴 「ためこむ人」の未読率を上げるだけでは足りない。
--    利用者の 1% には通知も 1% しか届かないので、その 6 割を未読にしても
--    全体の未読の 2 割にしかならなかった（最初にこの書き方をして実測 23% だった）。
--    **通知の宛先そのものを偏らせる**（ためこむ人に届く通知を増やす）必要がある。
--    ここでは個別の通知の 3 割をためこむ人（利用者の 1%）に集める。
--
-- 🔴 配列の添字には floor() を使う。::int は四捨五入なので
--    (random() * 2.999)::int は 3 を返し、添字が範囲外になる
--    （ch10_verification.md §0 で実際に踏んだ）。
--
-- 🔴 WITH ... AS MATERIALIZED を付ける。付けないと random() が外側で再評価され、
--    決めた未読・既読と、その時刻が食い違う。
--
-- setseed で乱数の種を固定するので、何度実行しても同じ値になる。

SELECT CASE :'size' WHEN 'S' THEN 300000 WHEN 'M' THEN 10000000
       ELSE 1/0 END AS n_notice \gset
SELECT CASE :'size' WHEN 'S' THEN 10000 WHEN 'M' THEN 1000000
       ELSE 1/0 END AS n_user \gset

\timing on
SELECT setseed(0.42);

-- 🔴 入れ直しても同じ結果になるようにする（2 回実行して行が倍にならない）
TRUNCATE ch10_r.src_delivery;
TRUNCATE ch10_r.src_notice CASCADE;
TRUNCATE ch10_r.src_user CASCADE;

\echo '生成する通知数:' :n_notice
\echo '生成する利用者数:' :n_user

-- 利用者。1% を「ためこむ人」にする
INSERT INTO ch10_r.src_user (id, login, is_hoarder)
SELECT g, 'user' || g, (g % 100 = 7)
FROM generate_series(1, :n_user) AS g;

-- 全員向けの告知は 20 件（年に数回という想定より多めにして、
-- 案B の未読判定に十分な件数を作る）
INSERT INTO ch10_r.src_notice (id, kind, is_broadcast, addressee_id, body, created_at)
SELECT g,
       'announcement',
       true,
       NULL,
       'メンテナンスのお知らせ ' || g,
       now() - (make_interval(days => 180) * (20 - g) / 20.0)
FROM generate_series(1, 20) AS g;

-- 個別の通知。告知の 20 件を避けて id を振る
INSERT INTO ch10_r.src_notice (id, kind, is_broadcast, addressee_id, body, created_at)
WITH base AS MATERIALIZED (
  SELECT g,
         -- 宛先を偏らせる。3 割はためこむ人（id % 100 = 7 の 1%）に届く。
         -- 残りの 7 割は全体に散らす。
         CASE WHEN random() < 0.30
              THEN floor(random() * (:n_user / 100))::bigint * 100 + 7
              ELSE floor(random() * :n_user)::bigint + 1
         END AS user_id,
         random() AS r_kind,
         random() AS r_age
  FROM generate_series(1, :n_notice) AS g
)
SELECT 20 + g,
       (ARRAY['order_shipped','comment_replied','request_approved'])
         [1 + floor(r_kind * 3)::int],
       false,
       user_id,
       '通知 ' || g,
       -- 直近 180 日に散らす。新しいものほど多い（運用と同じく増え続けている）
       now() - make_interval(days => floor(r_age * r_age * 180)::int)
FROM base;

-- 既読の記録。
--
-- 個別の通知は宛先の 1 人にだけ届く。
-- 「ためこむ人」は 13% を未読のまま残し、そうでない人は 1.5% だけ未読で残す。
-- ためこむ人には通知の 3 割が届くので、未読の 7 割以上がそこに集まり、
-- 全体の未読率は約 5% になる。
INSERT INTO ch10_r.src_delivery (notice_id, user_id, read_at)
WITH base AS MATERIALIZED (
  SELECT n.id AS notice_id,
         n.addressee_id AS user_id,
         n.created_at,
         u.is_hoarder,
         random() AS r_unread,
         random() AS r_lag
    FROM ch10_r.src_notice n
    JOIN ch10_r.src_user u ON u.id = n.addressee_id
   WHERE NOT n.is_broadcast
)
SELECT notice_id,
       user_id,
       CASE WHEN r_unread < CASE WHEN is_hoarder THEN 0.13 ELSE 0.015 END
            THEN NULL                                    -- 未読
            ELSE created_at + make_interval(secs => floor(r_lag * 86400)::int)
       END
  FROM base;

-- 告知の既読。告知は全員に届くが、行を作るのは「読んだ人」だけにする。
-- 案A（受信者ごとに行を作る）はここから 100 万行に展開し、
-- 案B・案C はこのまま使う。
--
-- 🔴 20 件 × 利用者数の直積を作ると M では 2,000 万行になるので、
--    読んだ人だけを抽出する形で作る（読んだ人は 8 割）。
INSERT INTO ch10_r.src_delivery (notice_id, user_id, read_at)
WITH pairs AS MATERIALIZED (
  SELECT n.id AS notice_id, u.id AS user_id, n.created_at,
         random() AS r_read, random() AS r_lag
    FROM ch10_r.src_notice n
   CROSS JOIN ch10_r.src_user u
   WHERE n.is_broadcast
)
SELECT notice_id, user_id,
       created_at + make_interval(secs => floor(r_lag * 86400)::int)
  FROM pairs
 WHERE r_read < 0.80;

ANALYZE ch10_r.src_user;
ANALYZE ch10_r.src_notice;
ANALYZE ch10_r.src_delivery;

-- 生成できたものを確認する。本文はここに出る数値を引用する。
\echo '=== 元データの件数 ==='
SELECT (SELECT count(*) FROM ch10_r.src_user)                          AS users,
       (SELECT count(*) FROM ch10_r.src_notice WHERE NOT is_broadcast) AS personal,
       (SELECT count(*) FROM ch10_r.src_notice WHERE is_broadcast)     AS broadcasts,
       (SELECT count(*) FROM ch10_r.src_delivery)                      AS deliveries;

\echo '=== 個別の通知の未読率と、その偏り ==='
SELECT count(*) FILTER (WHERE d.read_at IS NULL)                        AS unread,
       round(100.0 * count(*) FILTER (WHERE d.read_at IS NULL)
             / count(*), 2)                                             AS unread_pct,
       round(100.0 * count(*) FILTER (WHERE d.read_at IS NULL AND u.is_hoarder)
             / nullif(count(*) FILTER (WHERE d.read_at IS NULL), 0), 1) AS pct_in_hoarders
  FROM ch10_r.src_delivery d
  JOIN ch10_r.src_notice n ON n.id = d.notice_id AND NOT n.is_broadcast
  JOIN ch10_r.src_user u ON u.id = d.user_id;

\echo '=== 1 人あたりの未読（ためこむ人とそれ以外） ==='
SELECT u.is_hoarder,
       count(DISTINCT u.id)                                    AS users,
       count(*) FILTER (WHERE d.read_at IS NULL)               AS unread,
       round(count(*) FILTER (WHERE d.read_at IS NULL)::numeric
             / count(DISTINCT u.id), 1)                        AS unread_per_user
  FROM ch10_r.src_user u
  LEFT JOIN ch10_r.src_delivery d ON d.user_id = u.id
  LEFT JOIN ch10_r.src_notice n ON n.id = d.notice_id AND NOT n.is_broadcast
 GROUP BY u.is_hoarder ORDER BY u.is_hoarder;
