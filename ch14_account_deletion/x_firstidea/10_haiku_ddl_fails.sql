-- expect-error: syntax error at or near "WHERE"
-- run-as: book_owner
-- standalone
--
-- 採取した案（haiku）の DDL をそのまま実行する。
-- 部分的な一意を「制約」として書いているが、PostgreSQL にこの構文は無い。
-- 部分的な一意は「部分一意インデックス」でしか作れない。
CREATE SCHEMA IF NOT EXISTS ch14_x;

CREATE TABLE ch14_x.haiku_users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    phone_number VARCHAR(20),
    address TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,

    CONSTRAINT email_unique_when_active
        UNIQUE (email) WHERE (deleted_at IS NULL)
);
