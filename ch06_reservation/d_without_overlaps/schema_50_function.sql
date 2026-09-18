-- 案D の予約登録。主キーの違反を捕まえる。
-- 🔴 WITHOUT OVERLAPS の違反は unique_violation ではなく exclusion_violation (23P01) で出る。
--    中身が排他制約だからである（実機で確認した）。案B・案C と同じ例外節で書ける
CREATE FUNCTION ch06_d.reserve(p_room bigint, p_user bigint,
                               p_start timestamptz, p_end timestamptz)
RETURNS boolean LANGUAGE plpgsql SET search_path = ch06_d, public AS $$
BEGIN
  INSERT INTO reservations (room_id, period, user_id)
  VALUES (p_room, tstzrange(p_start, p_end, '[)'), p_user);
  RETURN true;
EXCEPTION WHEN exclusion_violation THEN
  RETURN false;
END $$;

GRANT EXECUTE ON FUNCTION ch06_d.reserve(bigint, bigint, timestamptz, timestamptz) TO book_app;
