-- 部屋と、既にある予約を生成する。
--   SIZE=S … 1,000 部屋 × 100 枠 =  100,000 枠
--   SIZE=M … 10,000 部屋 × 100 枠 = 1,000,000 枠
--
-- 枠は 1 時間刻み。部屋ごとに 2026-01-01 09:00 から 100 時間ぶんの枠を並べ、
-- そのうち 3 割を「既にある予約」として埋める。残り 7 割が測定で申し込まれる空き枠になる。
--
-- 🔴 埋まり具合を 3 割にしてあるのは、試作測定（prototype-reservation.md）の反省による。
--    枠が測定中に埋まり切ると、測定時間の大半が「埋まっている枠を断る処理」の測定になる。
--
-- setseed で乱数の種を固定するので、何度実行しても同じ値になる。
--
-- 🔴 サイズは psql の変数 :size で受け取る（run-sql.sh が -v size=$SIZE で渡す）。
--    \set n `echo "${SIZE}"` のようにバッククォートで書くと、コマンドは psql が動いている
--    コンテナの中で実行される。SIZE はホスト側のシェル変数なのでコンテナには渡っておらず、
--    いつも既定値になる。S で測ったつもりが M だった、という取り違えが実際に起きた。
SELECT CASE :'size' WHEN 'S' THEN 1000 WHEN 'M' THEN 10000
       ELSE 1/0 END AS n_rooms \gset

\timing on
SELECT setseed(0.42);

TRUNCATE ch06_r.src_reservation;
TRUNCATE ch06_r.src_room CASCADE;

\echo '生成する部屋数:' :n_rooms

INSERT INTO ch06_r.src_room (id, name)
SELECT g, '会議室' || g
FROM generate_series(1, :n_rooms) AS g;

-- 各部屋の 100 枠のうち 3 割を埋める。
-- id は (部屋, 枠) から決まる式で振るので、どの案でも同じ id が同じ予約を指す。
INSERT INTO ch06_r.src_reservation (id, room_id, user_id, start_at, end_at, cancelled_at)
SELECT (r.id - 1) * 100 + s.slot + 1                      AS id,
       r.id                                               AS room_id,
       1 + (random() * 999)::int                          AS user_id,
       timestamptz '2026-01-01 09:00+09' + s.slot * interval '1 hour' AS start_at,
       timestamptz '2026-01-01 09:00+09' + (s.slot + 1) * interval '1 hour' AS end_at,
       -- 埋めた予約のうち 1 割はキャンセル済みにする。
       -- キャンセル済みの枠は「空いている」ので、測定で申し込みが成功する
       CASE WHEN random() < 0.1
            THEN timestamptz '2026-01-01 08:00+09'
            ELSE NULL END                                  AS cancelled_at
FROM ch06_r.src_room AS r
CROSS JOIN generate_series(0, 99) AS s(slot)
WHERE random() < 0.3;

SELECT count(*)                                   AS rooms          FROM ch06_r.src_room;
SELECT count(*)                                   AS reservations,
       count(*) FILTER (WHERE cancelled_at IS NULL) AS active,
       count(*) FILTER (WHERE cancelled_at IS NOT NULL) AS cancelled
FROM ch06_r.src_reservation;
