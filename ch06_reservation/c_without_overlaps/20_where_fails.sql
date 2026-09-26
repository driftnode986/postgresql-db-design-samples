-- run-as: book_owner
-- expect-error: syntax error at or near "WHERE"
--
-- WITHOUT OVERLAPS に WHERE は付けられない。
-- EXCLUDE は WHERE を取れる（案A・案B はこれでキャンセル済みを判定から外している）が、
-- 主キーと一意制約の構文には WHERE が無いので、構文エラーになる。
-- この案でキャンセル済みを外すには、別のテーブルへ移すことになる。
CREATE TABLE ch06_c.where_demo (
  room_id      bigint      NOT NULL,
  period       tstzrange   NOT NULL,
  cancelled_at timestamptz,
  PRIMARY KEY (room_id, period WITHOUT OVERLAPS) WHERE (cancelled_at IS NULL)
);
