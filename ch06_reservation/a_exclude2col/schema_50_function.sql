-- 案B の予約登録。いきなり INSERT し、制約違反を捕まえる。
-- 空きの確認はしない（確認しても、確認と INSERT の間に他の接続が入る）。
--
-- 🔴 例外を関数の中で捕まえているので、測定値には例外処理の費用が含まれる。
--    pgbench は制約違反でクライアントを止めてしまうため、止めない形にそろえる必要がある。
--    アプリ側で捕まえる形との差は queries/50_exception_cost.sql で測る。
CREATE FUNCTION ch06_a.reserve(p_room bigint, p_user bigint,
                               p_start timestamptz, p_end timestamptz)
RETURNS boolean LANGUAGE plpgsql SET search_path = ch06_a, public AS $$
BEGIN
  INSERT INTO reservations (room_id, user_id, start_at, end_at)
  VALUES (p_room, p_user, p_start, p_end);
  RETURN true;
EXCEPTION WHEN exclusion_violation THEN
  RETURN false;   -- その枠は埋まっている
END $$;

GRANT EXECUTE ON FUNCTION ch06_a.reserve(bigint, bigint, timestamptz, timestamptz) TO book_app;
