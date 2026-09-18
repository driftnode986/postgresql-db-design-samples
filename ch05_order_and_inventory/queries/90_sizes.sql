-- 3 案の保存サイズ。本体とインデックスを分けて出す。
-- 🔴 単位を kB にそろえて出す。pg_size_pretty は行ごとに kB と MB を使い分けるので、
--    図に載せる数値がログの文字列と一致しなくなる（図の生成器がログ本文と照合する）。
SELECT c.relname::text AS rel,
       pg_relation_size(c.oid) / 1024        AS heap_kb,
       pg_indexes_size(c.oid) / 1024         AS indexes_kb,
       pg_total_relation_size(c.oid) / 1024  AS total_kb
  FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
 WHERE (n.nspname, c.relname) IN
       (('ch05_a','inventory'), ('ch05_b','inventory'), ('ch05_c','inventory_entries'))
 ORDER BY n.nspname;
