-- 変更の手数: 残高の列を持たない案A に、あとから残高の列（案B の形）を足す。
--
-- 🔴 BEGIN ... ROLLBACK で囲む。確定させるとサイズが変わり、以降の測定に効く
--    （消した列の定義は表に残り、繰り返すと本体が膨らむ）。
--
-- 測るのは 4 つ。SQL 文の数 / 既存の表が書き換わるか / 取るロック / 所要時間。
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

-- 2. 初期値を入れる。期限の切れていないロットの残りを、会員ごとに合計する
--    🔴 期限切れを外す。案A の残高は期限切れを数えないので、含めると、
--    移行した瞬間に表示される残高が増える（2026-09-26 最終レビューで検出。以前は含めていた）。
--    案B では、この先の期限切れは失効の処理で残高から引く
INSERT INTO ch07_a.point_balances (user_id, balance)
SELECT user_id, sum(remaining) FROM ch07_a.point_lots
 WHERE expires_at > now()
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

-- 既にある表（ロット）が書き換わったか。filenode が変わっていれば書き換え
SELECT :'filenode_before' AS filenode_before,
       pg_relation_filenode('ch07_a.point_lots') AS filenode_after,
       (:'filenode_before' = pg_relation_filenode('ch07_a.point_lots')::text)
         AS lots_untouched;

-- このトランザクションが取っているロック（既存の表を止めるかどうか）
SELECT c.relname, l.mode
FROM pg_locks AS l JOIN pg_class AS c ON c.oid = l.relation
JOIN pg_namespace AS n ON n.oid = c.relnamespace
WHERE l.pid = pg_backend_pid() AND n.nspname = 'ch07_a'
ORDER BY c.relname, l.mode;

ROLLBACK;
