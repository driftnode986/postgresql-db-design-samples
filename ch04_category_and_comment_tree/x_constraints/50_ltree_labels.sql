-- ltree のラベルに使える文字は、データベースのロケールで変わる。
-- このデータベースは en_US.utf8 なので、日本語のラベルが通る。
SELECT '電子機器.ノートPC'::ltree AS japanese_label;
SELECT 'top.1.42'::ltree          AS digits_only;
SELECT 'a_b-c.d'::ltree           AS underscore_and_hyphen;
