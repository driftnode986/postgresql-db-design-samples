-- PostgreSQL 18 の WITHOUT OVERLAPS と、EXCLUDE との機能の違いを実機で確かめる。
-- どちらを選ぶかは速さでは決まらないので、ここが選び方の根拠になる。

-- 1. WITHOUT OVERLAPS は内部的に一意な GiST インデックスとして作られる
SELECT conname, contype, pg_get_constraintdef(oid) AS definition
FROM pg_constraint WHERE conrelid = 'ch06_d.reservations'::regclass AND contype = 'p';

SELECT indexname, indexdef FROM pg_indexes
WHERE schemaname = 'ch06_d' AND tablename = 'reservations';

-- 2. 違反の SQLSTATE は 23P01（exclusion_violation）。EXCLUDE と同じなので、
--    アプリ側の例外処理は 1 つで済む
DO $$
BEGIN
  INSERT INTO ch06_d.reservations (room_id, period, user_id)
  VALUES (1, tstzrange('2026-06-01 10:00+09','2026-06-01 11:00+09','[)'), 1);
  INSERT INTO ch06_d.reservations (room_id, period, user_id)
  VALUES (1, tstzrange('2026-06-01 10:30+09','2026-06-01 11:30+09','[)'), 2);
EXCEPTION WHEN exclusion_violation THEN
  -- 🔴 メッセージは 80 桁に収まるように短く出す（本文にそのまま載せるため）
  RAISE NOTICE 'SQLSTATE=% で捕まえた', SQLSTATE;
END $$;

-- 3. 空の範囲の扱い。WITHOUT OVERLAPS は自分で拒否する
DO $$
BEGIN
  INSERT INTO ch06_d.reservations (room_id, period, user_id) VALUES (2, 'empty', 1);
  RAISE NOTICE '空の範囲が入った（想定外）';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '空の範囲は拒否された SQLSTATE=%: %', SQLSTATE, SQLERRM;
END $$;

-- 後片付け
DELETE FROM ch06_d.reservations WHERE lower(period) >= timestamptz '2026-06-01 00:00+09';
