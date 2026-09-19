-- run-as: book_owner
-- expect-error: 23505
-- 'Alice' が既に入っている表に 'ALICE' を入れる。
--
-- 🔴 非決定的照合順序（deterministic = false）の列では、
--    大文字小文字だけが違う値は**同じ値**なので、一意制約に当たる。
--    期待するエラー: 23505 duplicate key value violates unique constraint "accounts_login_key"
--
-- 🔴 別ファイルに分けている理由: psql は最初のエラーで止まる（確認記録 §4）。
INSERT INTO ch12_b.accounts (login) VALUES ('ALICE');
