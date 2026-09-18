-- 測定の開始点。会員 1 人だけ、残高 0 から始める。
-- 🔴 同じ 1 行に全接続が書き込む条件を作るのが目的なので、会員は 1 人でよい
\timing on
TRUNCATE ch07_f.point_txns, ch07_f.point_balances RESTART IDENTITY CASCADE;
INSERT INTO ch07_f.point_balances (user_id, balance) VALUES (1, 0);
SELECT user_id, balance FROM ch07_f.point_balances;
