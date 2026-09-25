-- expect-error: duplicate key value violates unique constraint "x_email_active"
-- run-as: book_owner
-- standalone
--
-- 🔴 この章の入口。「同じメールで再登録できる」と「30日以内なら戻せる」は
--    両方をメールの一意で実現しようとすると衝突する。
--
-- 採取した案（opus）が 1 回目の応答で、DDL を出す前にこれを指摘した（採取記録からの要約）:
--   退会の 3 日後に同じメールアドレスで別のアカウントが登録され、その 10 日後に
--   元のアカウントを戻そうとすると、メールアドレスは新しいアカウントが使っている。
--
-- 部分一意インデックスで再登録を通した場合に、本当に戻せなくなるかを確かめる。
CREATE SCHEMA IF NOT EXISTS ch14_x;
DROP TABLE IF EXISTS ch14_x.collide;

CREATE TABLE ch14_x.collide (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email      text NOT NULL,
    full_name  text NOT NULL,
    deleted_at timestamptz
);
CREATE UNIQUE INDEX x_email_active ON ch14_x.collide (email) WHERE deleted_at IS NULL;

-- 1. 田中さんが登録する
INSERT INTO ch14_x.collide (email, full_name) VALUES ('t@example.com', '田中');

-- 2. 退会する
UPDATE ch14_x.collide SET deleted_at = now() - interval '13 day' WHERE id = 1;

-- 3. 3 日後、同じメールで登録する（部分一意なので通る）
INSERT INTO ch14_x.collide (email, full_name) VALUES ('t@example.com', '田中（新）');

SELECT id, email, full_name, (deleted_at IS NULL) AS active
FROM ch14_x.collide ORDER BY id;

-- 4. さらに 10 日後（退会から 13 日 = 30 日以内）、元に戻したいと申し出る
UPDATE ch14_x.collide SET deleted_at = NULL WHERE id = 1;
