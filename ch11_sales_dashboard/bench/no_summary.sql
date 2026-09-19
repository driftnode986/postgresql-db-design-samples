-- 集計を更新しない（基準）
\set pid random(1, 1000)
SELECT ch11_c.place_order_only(:pid, 1, 15000);
