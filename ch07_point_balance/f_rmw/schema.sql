-- 検算用: 残高を読んでアプリ側で計算し、書き戻す案
--
-- 🔴 これは本書の設計案ではない。採取した案（sonnet / haiku）が
--    「残高の列を SELECT ... FOR UPDATE でロックしてから減らす」形だったので、
--    その形が正しく動くのか、そしてロックを外すと何が起きるのかを測るために置く。
--
-- 案B と同じ構造にして、書き込みの方法だけを変える。
CREATE SCHEMA ch07_f;

CREATE TABLE ch07_f.point_balances (
  user_id    bigint PRIMARY KEY,
  balance    bigint      NOT NULL DEFAULT 0 CHECK (balance >= 0),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 台帳。付与したことの記録。
-- 🔴 残高の列が正しいかどうかは、この台帳の合計と突き合わせて判定する
CREATE TABLE ch07_f.point_txns (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id    bigint      NOT NULL,
  amount     bigint      NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX point_txns_user ON ch07_f.point_txns (user_id, id);

GRANT SELECT, INSERT, UPDATE
  ON ch07_f.point_balances, ch07_f.point_txns TO book_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA ch07_f TO book_app;
