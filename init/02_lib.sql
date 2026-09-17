-- 02_lib.sql: 章をまたいで使うのは、データ生成の関数だけ
--
-- lib スキーマにテーブルは置かない。章の実験で使うテーブルは、必ず章と案ごとのスキーマ
-- （ch06_a など）に作る。全章共通のテーブルを作ると、ある章の実験が別の章の測定値を変えてしまう。
-- 関数は各章の執筆時に、必要になった時点で足す。
-- lib は search_path に入れない。呼ぶときは lib.関数名() とスキーマで修飾する
-- （search_path に入れると、章のスキーマを作り忘れたときに、テーブルがエラーなしで lib に出来てしまう）。

CREATE SCHEMA IF NOT EXISTS lib AUTHORIZATION book_owner;
GRANT USAGE ON SCHEMA lib TO book_app;
