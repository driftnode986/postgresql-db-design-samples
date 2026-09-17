-- run-as: book_owner
-- expect-error: 2BP01
-- 写した側が元のシーケンスを使っているので、元のテーブルを消せない
DROP TABLE ch01.t_ser;
