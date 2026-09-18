-- 案F: 人気の部屋への集中。
-- 🔴 枠が測定中に埋まり切らないようにする（試作測定の反省。prototype-reservation.md の「注意」）。
--    埋まり切ると、測定時間の大半が「埋まっている枠を断る処理」の測定になり、
--    案の比較ではなく「違反を返す速さ」の比較になってしまう。
--    そこで枠を日付方向に広げ、pgbench の実行ごとに使い切らない広さを取る。
--    20 部屋 × 10 日 × 8 枠 = 1,600 通り。
\set room random(1, 20)
\set day  random(0, 9)
\set slot random(0, 7)
SELECT ch06_f.reserve(
  :room, 1,
  timestamptz '2026-02-01 09:00+09' + :day * interval '1 day' + :slot * interval '1 hour',
  timestamptz '2026-02-01 09:00+09' + :day * interval '1 day' + (:slot + 1) * interval '1 hour');
