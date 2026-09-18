-- 採取した案（haiku）の予約登録を、そのまま関数にしたもの。
--
-- 採取した案は BEGIN / SELECT ... FOR UPDATE / INSERT / COMMIT の 3 文だった。
-- pgbench から同じ条件で測るため、関数 1 回にまとめてある（第1章の測り方の規約:
-- 比べる案の間で、データベースとの往復の回数をそろえる）。
-- 関数の本体は 1 つのトランザクションで動くので、採取した案の BEGIN / COMMIT と同じ意味になる。
--
-- 🔴 採取した案の SQL には引数の取り違えがあった（INSERT ... VALUES ($1, $2, $2, $3) で、
--    user_id の位置に start_time が入っていた）。ここは意図どおりに直してある。
--    直さないと型の不一致で止まり、測りたいもの（重なり判定が効くか）に届かない。
CREATE FUNCTION ch06_f.reserve(p_room bigint, p_user bigint,
                               p_start timestamptz, p_end timestamptz)
RETURNS boolean LANGUAGE plpgsql SET search_path = ch06_f, public AS $$
BEGIN
  -- 重なる予約をロックする、つもりの文。
  -- 重なりの条件（start_at < 申込の終了 AND end_at > 申込の開始）は正しい。
  -- 1 行でも返れば、その枠は埋まっている
  PERFORM 1 FROM reservations
   WHERE room_id = p_room
     AND cancelled_at IS NULL
     AND start_at < p_end
     AND end_at   > p_start
     FOR UPDATE;

  IF FOUND THEN
    RETURN false;   -- 埋まっている
  END IF;

  -- 0 行だったので空いている、と判断して入れる。
  -- 🔴 0 行にはロックが掛かっていない。同じ判断をした別の接続も、ここへ到達する
  INSERT INTO reservations (room_id, user_id, start_at, end_at)
  VALUES (p_room, p_user, p_start, p_end);
  RETURN true;
END $$;

GRANT EXECUTE ON FUNCTION ch06_f.reserve(bigint, bigint, timestamptz, timestamptz) TO book_app;
GRANT SELECT, INSERT, UPDATE ON ch06_f.rooms, ch06_f.reservations TO book_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA ch06_f TO book_app;
