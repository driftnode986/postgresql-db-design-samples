-- run-as: book_owner
-- expect-error: contains null values
-- 古い NULL が残っているあいだは、検査を通せない
ALTER TABLE ch15_d.users VALIDATE CONSTRAINT users_email_nn;
