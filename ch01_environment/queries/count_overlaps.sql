-- 同じ部屋で時間が重なっている予約の組を数える。0 でなければ約束が破られている
SELECT 'resv_check' AS table_name, count(*) AS rows,
       (SELECT count(*) FROM resv_check a JOIN resv_check b
         ON a.room_id = b.room_id AND a.period && b.period AND a.id < b.id) AS overlaps
FROM resv_check
UNION ALL
SELECT 'resv_excl', count(*),
       (SELECT count(*) FROM resv_excl a JOIN resv_excl b
         ON a.room_id = b.room_id AND a.period && b.period AND a.id < b.id)
FROM resv_excl;
