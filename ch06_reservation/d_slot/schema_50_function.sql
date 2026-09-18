-- 案E の予約登録。予約の行を入れ、占める枠を展開して入れる。
-- 枠のどれか 1 つでも埋まっていれば一意制約の違反になり、予約ごと取り消される
-- （関数の中の INSERT は同じトランザクションなので、途中で失敗すれば予約の行も残らない）。
CREATE FUNCTION ch06_d.reserve(p_room bigint, p_user bigint,
                               p_start timestamptz, p_end timestamptz)
RETURNS boolean LANGUAGE plpgsql SET search_path = ch06_d, public AS $$
DECLARE
  v_id bigint;
BEGIN
  INSERT INTO reservations (room_id, user_id) VALUES (p_room, p_user)
  RETURNING id INTO v_id;

  INSERT INTO reservation_slots (room_id, slot_start, reservation_id)
  SELECT p_room, s.slot_start, v_id
  FROM generate_series(p_start, p_end - interval '1 second', interval '1 hour')
       AS s(slot_start);
  RETURN true;
EXCEPTION WHEN unique_violation THEN
  RETURN false;   -- 枠のどれかが埋まっている
END $$;

GRANT EXECUTE ON FUNCTION ch06_d.reserve(bigint, bigint, timestamptz, timestamptz) TO book_app;
