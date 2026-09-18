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

-- 2. 初期値を入れる。ロットの残りを会員ごとに合計する
--    🔴 ここで期限切れを含めるか外すかを決めることになる。
--    含めないと、案A で見えていた残高と案B で見える残高が食い違う
INSERT INTO ch07_a.point_balances (user_id, balance)
SELECT user_id, sum(remaining) FROM ch07_a.point_lots GROUP BY user_id;

-- 3. 入れた値がロットの合計と一致するか検算する（移行の検算はここでしかできない）
SELECT count(*) AS balance_vs_lots_mismatch
FROM (
  SELECT b.user_id FROM ch07_a.point_balances AS b
  LEFT JOIN (SELECT user_id, sum(remaining) AS r FROM ch07_a.point_lots GROUP BY user_id) AS l
    ON l.user_id = b.user_id
  WHERE b.balance <> coalesce(l.r, 0)
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
