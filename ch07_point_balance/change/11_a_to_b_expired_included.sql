-- 検算が誤りを見つけられるかを確かめる（canary）。
-- 10_a_to_b.sql と同じ手順で、初期値を入れるときだけ期限切れを外さない（2026-09-26 以前の誤った移行）。
-- balance_vs_case_a_mismatch が 0 でなければ、検算は働いている。BEGIN ... ROLLBACK で何も残さない。
BEGIN;
\timing on

-- 移す前のファイルノード（表が書き換わったかを見る）
SELECT pg_relation_filenode('ch07_a.point_lots') AS filenode_before \gset

-- 1. 残高の表を作る
CREATE TABLE ch07_a.point_balances (
  user_id    bigint PRIMARY KEY,
  balance    bigint      NOT NULL DEFAULT 0 CHECK (balance >= 0),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 2. 初期値を入れる。🔴 わざと期限切れのロットも含めて合計する（以前の誤った移行）
INSERT INTO ch07_a.point_balances (user_id, balance)
SELECT user_id, sum(remaining) FROM ch07_a.point_lots
 GROUP BY user_id;

-- 3. 入れた値が、案A の残高照会（queries/10_balance_plans.sql と同じ条件）と一致するか検算する。
--    🔴 全会員について、案A が表示していた残高と比べる。入れたときと同じ式どうしを比べると、
--    同じ誤りを両側に含んだまま 0 件になる（第8章の教訓）。ここでは会員の表から出発し、
--    どちらか片方にしかいない会員も数える
SELECT count(*) AS balance_vs_case_a_mismatch
FROM (
  SELECT u.user_id
  FROM (SELECT DISTINCT user_id FROM ch07_a.point_lots) AS u
  LEFT JOIN ch07_a.point_balances AS b ON b.user_id = u.user_id
  CROSS JOIN LATERAL (
    SELECT coalesce(sum(remaining), 0) AS shown
    FROM ch07_a.point_lots
    WHERE user_id = u.user_id AND remaining > 0 AND expires_at > now()
  ) AS a
  WHERE coalesce(b.balance, 0) <> a.shown
) AS t;

ROLLBACK;
