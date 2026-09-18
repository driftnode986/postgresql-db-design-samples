-- 会員と、その付与・利用の履歴を生成する。
--   SIZE=S … 会員 1,000 人・取引 約 10 万件
--   SIZE=M … 会員 10,000 人・取引 約 100 万件
--
-- 🔴 取引の件数を会員ごとに大きく偏らせる。
--    ここが第7章の測定の肝である。「会員が何人いるか」ではなく
--    「1 人あたりの取引が何件あるか」で、残高照会の実行計画の形が変わる。
--    均等に配ると、どの会員も同じ件数になってしまい、章の主張が測れない。
--
--    偏らせ方: 会員の 1% を「多い会員」にして、全取引の大半をそこへ集める。
--    通販のポイントは、ヘビーユーザーに履歴が集中する（現実の形に合わせている）。
--
-- 🔴 期限は付与日から決まらない。付与のたびに 30 日・180 日・400 日のいずれかを選ぶので、
--    あとから付与されたポイントのほうが先に切れることがある（§6 の FEFO の教材）。
--
-- setseed で乱数の種を固定するので、何度実行しても同じ値になる。
--
-- 🔴 サイズは psql の変数 :size で受け取る（run-sql.sh が -v size=$SIZE で渡す）。
--    バッククォートで書くとコンテナの中で実行され、ホストの SIZE は渡らない。
SELECT CASE :'size' WHEN 'S' THEN 1000 WHEN 'M' THEN 10000
       ELSE 1/0 END AS n_users \gset
SELECT CASE :'size' WHEN 'S' THEN 100000 WHEN 'M' THEN 1000000
       ELSE 1/0 END AS n_txns \gset

\timing on
SELECT setseed(0.42);

TRUNCATE ch07_r.src_txn;
TRUNCATE ch07_r.src_user CASCADE;

\echo '生成する会員数:' :n_users '  取引件数:' :n_txns

INSERT INTO ch07_r.src_user (id, name)
SELECT g, '会員' || g
FROM generate_series(1, :n_users) AS g;

-- 取引を会員に割り当てる。
-- 会員の 1%（id が n_users/100 以下）に全取引の 80% を集める。
-- 残り 20% を、残りの会員へ均等に配る。
-- 🔴 MATERIALIZED を必ず付ける。付けないと PostgreSQL は副問い合わせを外側へ畳み込み、
--    random() が外側でもう一度評価される。すると内側で kind='grant' と決めた行が、
--    外側の CASE では 'use' と判定され、期限が NULL のまま入って CHECK に弾かれる
--    （実際にこれで 2 回失敗した）。
WITH src AS MATERIALIZED (
  SELECT g AS id,
         CASE WHEN random() < 0.8
              THEN 1 + floor(random() * greatest(:n_users / 100, 1))::bigint
              ELSE greatest(:n_users / 100, 1) + 1
                   + floor(random()
                           * (:n_users - greatest(:n_users / 100, 1)))::bigint
         END AS user_id,
         CASE WHEN random() < 0.6 THEN 'grant' ELSE 'use' END AS kind,
         -- 刻みの大きさは下の外側の SELECT で kind から決める。
         -- ここで CASE WHEN random() ... と書くと、kind を決めた random() とは
         -- 別の値が引かれるので、付与なのに利用の刻みになる行ができる
         1 + floor(random() * 10)::int AS step,
         -- 🔴 floor() を使う。::int は四捨五入なので (random()*2.999)::int は 3 になることがあり、
         --    添字 4 が範囲外で NULL になる（実際に踏んだ）。切り捨てなら 0..2 に収まる
         (ARRAY[30, 180, 400])[1 + floor(random() * 3)::int] AS span,
         timestamptz '2026-01-01 00:00+09'
           + (random() * 300)::int * interval '1 day'
           + (random() * 86400)::int * interval '1 second' AS created_at
  FROM generate_series(1, :n_txns) AS g
)
INSERT INTO ch07_r.src_txn (id, user_id, kind, amount, expires_at, created_at)
SELECT s.id, s.user_id, s.kind,
       -- 🔴 付与は 100〜1,000、利用は 10〜100 にする。
       --    同じ刻みにすると「利用の合計 > 期限内の付与の合計」になる会員が半数出て、
       --    どの案でも残高が負になり、案の比較そのものができなくなる（実際にそうなった）。
       --    期限切れで消える付与があるぶん、利用は小さくしておく必要がある
       s.step * CASE WHEN s.kind = 'grant' THEN 100 ELSE 10 END AS amount,
       -- 付与の行にだけ期限を入れる。
       -- 🔴 期限の長さは付与日と独立に選ぶ（30 / 180 / 400 日）。
       --    これにより「あとから付与されたのに先に切れる」ポイントができる
       CASE WHEN s.kind = 'grant'
            THEN s.created_at + s.span * interval '1 day'
            ELSE NULL END AS expires_at,
       s.created_at
FROM src AS s;

-- 🔴 会員ごとに「期限の遠い付与」を 1 件ずつ足す（入会時のボーナスにあたる）。
--    これが無いと、取引の少ない会員で付与が全部期限切れになり、利用ぶんを引けなくなる。
--    乱数の引き方を調整して避けようとすると、種を変えるたびに壊れる。
--    構造として保証するほうが確実である。
--    id は元データの最大 id より後ろに置く（写すときの ORDER BY id を壊さないため）
INSERT INTO ch07_r.src_txn (id, user_id, kind, amount, expires_at, created_at)
SELECT :n_txns + u.id, u.id, 'grant', 20000,
       timestamptz '2027-12-31 00:00+09',
       timestamptz '2025-12-01 00:00+09'
FROM ch07_r.src_user AS u;

SELECT count(*) AS users FROM ch07_r.src_user;

SELECT count(*)                                  AS txns,
       count(*) FILTER (WHERE kind = 'grant')    AS grants,
       count(*) FILTER (WHERE kind = 'use')      AS uses
FROM ch07_r.src_txn;

-- 1 人あたりの取引件数の偏り。章の主張はこの偏りの上に立つ
SELECT max(c) AS max_per_user, round(avg(c)) AS avg_per_user, min(c) AS min_per_user
FROM (SELECT count(*) AS c FROM ch07_r.src_txn GROUP BY user_id) AS t;

-- 🔴 検査: 利用の合計が「期限内の付与の合計」を超える会員が 1 人でもいたら、
--    その会員は消し込みが最後まで通らず、案の比較にならない。0 でなければ止める。
--    この検査が無いと、案ごとに残高が食い違う原因が「設計の違い」なのか
--    「元データが破綻している」のか分からないまま測ってしまう（実際に一度そうなった）
SELECT count(*) AS users_overspending_must_be_zero
FROM (
  SELECT user_id,
         coalesce(sum(amount) FILTER (WHERE kind = 'use'), 0) AS used,
         coalesce(sum(amount) FILTER (WHERE kind = 'grant'
                                        AND expires_at > now()), 0) AS alive
  FROM ch07_r.src_txn GROUP BY user_id
) AS t
WHERE used > alive;

-- 🔴 検査に失敗したら、ここで止める。
--    `CASE WHEN ... THEN 1/0 END` は使えない。PostgreSQL は定数の 1/0 を
--    条件の判定より先に畳み込むので、条件が偽でも必ずエラーになる（実際に踏んだ）。
--    行そのものを 0 で割る形にすれば、違反した行があるときだけエラーになる
SELECT 1 / (0 * count(*)) AS stop_if_overspending
FROM (
  SELECT user_id,
         coalesce(sum(amount) FILTER (WHERE kind = 'use'), 0) AS used,
         coalesce(sum(amount) FILTER (WHERE kind = 'grant'
                                        AND expires_at > now()), 0) AS alive
  FROM ch07_r.src_txn GROUP BY user_id
) AS t
WHERE used > alive
HAVING count(*) > 0;

-- 付与された順と、期限の切れる順が食い違う会員が何人いるか（§6 の教材が成り立つ確認）
SELECT count(*) AS users_with_fifo_fefo_mismatch
FROM (
  SELECT user_id
  FROM ch07_r.src_txn
  WHERE kind = 'grant'
  GROUP BY user_id
  HAVING count(*) > 1
     AND (array_agg(id ORDER BY created_at)) <> (array_agg(id ORDER BY expires_at))
) AS t;
