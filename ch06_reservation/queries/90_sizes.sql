-- 案ごとの保存サイズ。表とインデックスを分けて出す。
-- 🔴 load の直後に測る（同時実行の測定のあとだと、不要になった行が残って膨らむ）
SELECT 'b 2列+EXCLUDE'      AS plan, 'ch06_b.reservations'  AS rel,
       pg_size_pretty(pg_relation_size('ch06_b.reservations'))       AS table_size,
       pg_size_pretty(pg_indexes_size('ch06_b.reservations'))        AS indexes_size,
       pg_size_pretty(pg_total_relation_size('ch06_b.reservations')) AS total
UNION ALL SELECT 'c 範囲型+EXCLUDE', 'ch06_c.reservations',
       pg_size_pretty(pg_relation_size('ch06_c.reservations')),
       pg_size_pretty(pg_indexes_size('ch06_c.reservations')),
       pg_size_pretty(pg_total_relation_size('ch06_c.reservations'))
UNION ALL SELECT 'd WITHOUT OVERLAPS', 'ch06_d.reservations',
       pg_size_pretty(pg_relation_size('ch06_d.reservations')),
       pg_size_pretty(pg_indexes_size('ch06_d.reservations')),
       pg_size_pretty(pg_total_relation_size('ch06_d.reservations'))
UNION ALL SELECT 'e 枠の行+UNIQUE', 'ch06_e.reservation_slots',
       pg_size_pretty(pg_relation_size('ch06_e.reservation_slots')),
       pg_size_pretty(pg_indexes_size('ch06_e.reservation_slots')),
       pg_size_pretty(pg_total_relation_size('ch06_e.reservation_slots'));

-- 案E は予約の表と枠の表の合計で見る必要がある
SELECT 'e 合計（予約＋枠）' AS plan,
       pg_size_pretty(pg_total_relation_size('ch06_e.reservations')
                    + pg_total_relation_size('ch06_e.reservation_slots')) AS total;

-- 行数（サイズの比を読むときに要る）
SELECT 'b' AS plan, count(*) AS rows FROM ch06_b.reservations
UNION ALL SELECT 'c', count(*) FROM ch06_c.reservations
UNION ALL SELECT 'd', count(*) FROM ch06_d.reservations
UNION ALL SELECT 'e_slots', count(*) FROM ch06_e.reservation_slots
ORDER BY 1;
