-- expect-error: duplicate key value violates unique constraint
-- run-as: book_owner
-- standalone
--
-- 構文を直して通常の UNIQUE(email) にすると作れる。しかし、
-- 退会したあとに同じメールで再登録できない（一意制約は退会した行も見続ける）。
CREATE SCHEMA IF NOT EXISTS ch14_x;
DROP TABLE IF EXISTS ch14_x.plain_users;

CREATE TABLE ch14_x.plain_users (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email      text NOT NULL UNIQUE,
    full_name  text NOT NULL,
    deleted_at timestamptz
);

INSERT INTO ch14_x.plain_users (email, full_name) VALUES ('t@example.com', '田中');
UPDATE ch14_x.plain_users SET deleted_at = now() WHERE email = 't@example.com';

-- 退会した本人が、同じメールでもう一度登録しようとする
INSERT INTO ch14_x.plain_users (email, full_name) VALUES ('t@example.com', '田中');
