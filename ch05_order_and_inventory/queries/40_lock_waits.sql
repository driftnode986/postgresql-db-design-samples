-- 待ち行列の実測。ロックの順序をそろえない測定を流している最中に、別の接続から実行する。
-- 「デッドロックが主因ではない」ことを、待っている接続の数で示す。
--
-- 自分自身（この問い合わせを流している接続）も active に数えられるので、
-- client_backends は pgbench の接続数より 1 多くなる。
SELECT count(*) FILTER (WHERE wait_event_type = 'Lock') AS waiting_on_lock,
       count(*) AS active_backends
  FROM pg_stat_activity
 WHERE datname = 'book' AND backend_type = 'client backend' AND state = 'active';

-- 何を待っているかの内訳
SELECT wait_event_type, wait_event, count(*)
  FROM pg_stat_activity
 WHERE datname = 'book' AND backend_type = 'client backend' AND state = 'active'
 GROUP BY 1, 2 ORDER BY 3 DESC;
