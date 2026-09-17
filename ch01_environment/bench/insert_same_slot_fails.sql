-- expect-error: conflicting key value violates exclusion constraint
-- 関数で包まずに、同じ枠へ INSERT し続ける。2 件目が制約違反になり、クライアントが止まる
INSERT INTO resv_excl (room_id, period)
VALUES (1, tstzrange('2026-12-01 10:00+09', '2026-12-01 11:00+09'));
