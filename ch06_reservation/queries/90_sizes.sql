-- 案ごとの保存サイズ。表とインデックスを分けて出す。
-- 🔴 load の直後に測る（同時実行の測定のあとだと、不要になった行が残って膨らむ）
SELECT 'a 2列+EXCLUDE'      AS plan, 'ch06_a.reservations'  AS rel,
       pg_size_pretty(pg_relation_size('ch06_a.reservations'))       AS table_size,
       pg_size_pretty(pg_indexes_size('ch06_a.reservations'))        AS indexes_size,
       pg_size_pretty(pg_total_relation_size('ch06_a.reservations')) AS total
UNION ALL SELECT 'b 範囲型+EXCLUDE', 'ch06_b.reservations',
       pg_size_pretty(pg_relation_size('ch06_b.reservations')),
       pg_size_pretty(pg_indexes_size('ch06_b.reservations')),
       pg_size_pretty(pg_total_relation_size('ch06_b.reservations'))
UNION ALL SELECT 'c WITHOUT OVERLAPS', 'ch06_c.reservations',
       pg_size_pretty(pg_relation_size('ch06_c.reservations')),
       pg_size_pretty(pg_indexes_size('ch06_c.reservations')),
       pg_size_pretty(pg_total_relation_size('ch06_c.reservations'))
UNION ALL SELECT 'd 枠の行+UNIQUE', 'ch06_d.reservation_slots',
       pg_size_pretty(pg_relation_size('ch06_d.reservation_slots')),
       pg_size_pretty(pg_indexes_size('ch06_d.reservation_slots')),
       pg_size_pretty(pg_total_relation_size('ch06_d.reservation_slots'));

-- 案E は予約の表と枠の表の合計で見る必要がある
SELECT 'd 合計（予約＋枠）' AS plan,
       pg_size_pretty(pg_total_relation_size('ch06_d.reservations')
                    + pg_total_relation_size('ch06_d.reservation_slots')) AS total;

-- 行数（サイズの比を読むときに要る）
SELECT 'a' AS plan, count(*) AS rows FROM ch06_a.reservations
UNION ALL SELECT 'b', count(*) FROM ch06_b.reservations
UNION ALL SELECT 'c', count(*) FROM ch06_c.reservations
UNION ALL SELECT 'd_slots', count(*) FROM ch06_d.reservation_slots
ORDER BY 1;
