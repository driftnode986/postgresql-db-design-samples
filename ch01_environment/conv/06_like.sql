-- run-as: book_owner
-- テーブルの定義を写して、新しいテーブルを作る
CREATE TABLE ch01.t_ser_copy (LIKE ch01.t_ser INCLUDING ALL);
CREATE TABLE ch01.t_idn_copy (LIKE ch01.t_idn INCLUDING ALL);

-- 写したテーブルの id が、どのシーケンスから値を取るか
SELECT c.relname AS table_name, pg_get_expr(d.adbin, d.adrelid) AS id_default,
       pg_get_serial_sequence('ch01.' || c.relname, 'id') AS own_sequence
FROM pg_class c
LEFT JOIN pg_attrdef d ON d.adrelid = c.oid
WHERE c.relname IN ('t_ser_copy', 't_idn_copy') AND c.relkind = 'r'
ORDER BY c.relname;
