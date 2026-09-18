-- 重なっている予約の組を数える。
--
-- 🔴 この案の欠陥を見せるためのファイルなので、verify*.sql という名前にしていない
--    （検査クエリは全行の先頭列が 0 であることを強制される。この案はそこを満たさない）。
--
-- 有効な予約（cancelled_at IS NULL）どうしで、同じ部屋・時間が重なる組を数える。
-- 半開区間なので、10:00-11:00 と 11:00-12:00 は重ならない（a.start_at < b.end_at が偽になる）。
SELECT count(*) AS overlapping_pairs
FROM ch06_f.reservations AS a
JOIN ch06_f.reservations AS b
  ON a.room_id = b.room_id
 AND a.id < b.id                 -- 同じ組を 2 回数えない
 AND a.cancelled_at IS NULL
 AND b.cancelled_at IS NULL
 AND a.start_at < b.end_at
 AND a.end_at   > b.start_at;

-- 測定で何件入ったか（元データの件数との差が、測定中に入った予約）
SELECT count(*) AS total_rows,
       count(*) FILTER (WHERE cancelled_at IS NULL) AS active_rows
FROM ch06_f.reservations;
