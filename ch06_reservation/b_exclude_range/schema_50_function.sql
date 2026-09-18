-- 案C の予約登録。案B と同じ形で、範囲型を組み立てて入れる
CREATE FUNCTION ch06_b.reserve(p_room bigint, p_user bigint,
                               p_start timestamptz, p_end timestamptz)
RETURNS boolean LANGUAGE plpgsql SET search_path = ch06_b, public AS $$
BEGIN
  INSERT INTO reservations (room_id, user_id, period)
  VALUES (p_room, p_user, tstzrange(p_start, p_end, '[)'));
  RETURN true;
EXCEPTION WHEN exclusion_violation THEN
  RETURN false;
END $$;

GRANT EXECUTE ON FUNCTION ch06_b.reserve(bigint, bigint, timestamptz, timestamptz) TO book_app;
