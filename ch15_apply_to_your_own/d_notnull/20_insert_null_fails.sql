-- run-as: book_owner
-- expect-error: 23502
-- 足した直後から、新しい NULL は拒否される
INSERT INTO ch15_d.users (email) VALUES (NULL);
