-- run-as: book_owner
-- 案B に「期限つきの招待」と「大文字・小文字を区別しないログイン名」を足す。
--
-- どちらも案の比較（一覧の速さ）には関係しないが、権限の題材でよく要求される 2 つで、
-- PostgreSQL に制約として書ける。アプリで検査するとすり抜ける類の要件である。
\timing on

DROP TABLE IF EXISTS ch12_b.grants_t;
DROP TABLE IF EXISTS ch12_b.accounts;
DROP COLLATION IF EXISTS ch12_b.ci;

\echo '=== (1) 期限つきの招待（WITHOUT OVERLAPS） ==='
-- 「同じ人・同じ対象に、期間が重なる付与を 2 つ作らない」を主キーで保証する。
-- 🔴 18 の新機能ではない（15 以降の機能）。18 固有のものはこの章には無い。
CREATE TABLE ch12_b.grants_t (
  user_id  bigint    NOT NULL REFERENCES ch12_b.users(id),
  scope_id bigint    NOT NULL REFERENCES ch12_b.scopes(id),
  role_id  int       NOT NULL REFERENCES ch12_b.roles(id),
  valid    tstzrange NOT NULL,
  PRIMARY KEY (user_id, scope_id, valid WITHOUT OVERLAPS)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON ch12_b.grants_t TO book_app;

\echo '--- 主キーの実体（btree ではなく排他制約になる） ---'
-- 🔴 WITHOUT OVERLAPS を付けた主キーは、内部では GiST の排他制約である。
--    そのため違反は 23505（主キー違反）ではなく排他制約違反になる。
SELECT c.conname, c.contype, i.relname AS index_name, am.amname AS index_method
  FROM pg_constraint c
  JOIN pg_class i ON i.oid = c.conindid
  JOIN pg_am am ON am.oid = i.relam
 WHERE c.conrelid = 'ch12_b.grants_t'::regclass;

\echo '--- 1 件目（1 月〜2 月の招待） ---'
INSERT INTO ch12_b.grants_t (user_id, scope_id, role_id, valid)
SELECT 7, 25, r.id, tstzrange('2026-01-01', '2026-02-01')
  FROM ch12_b.roles r WHERE r.code = 'editor';

\echo '--- 隣接する期間（2 月〜3 月）は通る。境界は重ならない扱い ---'
INSERT INTO ch12_b.grants_t (user_id, scope_id, role_id, valid)
SELECT 7, 25, r.id, tstzrange('2026-02-01', '2026-03-01')
  FROM ch12_b.roles r WHERE r.code = 'viewer';

\echo '--- 別の利用者の同じ期間は通る ---'
INSERT INTO ch12_b.grants_t (user_id, scope_id, role_id, valid)
SELECT 42, 25, r.id, tstzrange('2026-01-01', '2026-02-01')
  FROM ch12_b.roles r WHERE r.code = 'viewer';

\echo '--- 入った 3 件 ---'
SELECT g.user_id, g.scope_id, r.code AS role, g.valid
  FROM ch12_b.grants_t g JOIN ch12_b.roles r ON r.id = g.role_id
 ORDER BY g.user_id, lower(g.valid);

\echo '=== 🔴 WITHOUT OVERLAPS は「すき間」を検査しない ==='
-- 「招待が切れてから次の招待までの空白」は防げない。
-- 2 月〜3 月 の次に 4 月〜5 月 を入れると、3 月の 1 か月が無権限になるが、通る。
INSERT INTO ch12_b.grants_t (user_id, scope_id, role_id, valid)
SELECT 7, 25, r.id, tstzrange('2026-04-01', '2026-05-01')
  FROM ch12_b.roles r WHERE r.code = 'viewer';
\echo '--- 3 月のすき間は検出されず、通ってしまう ---'
SELECT count(*) AS grants_for_user7_scope25
  FROM ch12_b.grants_t WHERE user_id = 7 AND scope_id = 25;

\echo '=== (2) 大文字・小文字を区別しないログイン名（非決定的照合順序） ==='
-- 'Alice' と 'ALICE' を同じ人だと扱う。
-- アプリで lower() して比べる形は、比べ忘れた経路が 1 つあれば破れる。
-- 照合順序に書けば、UNIQUE 制約が保証する。
CREATE COLLATION ch12_b.ci (provider = icu, locale = 'und-u-ks-level2',
                            deterministic = false);

CREATE TABLE ch12_b.accounts (
  id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  login text COLLATE ch12_b.ci NOT NULL UNIQUE
);

GRANT SELECT, INSERT ON ch12_b.accounts TO book_app;

INSERT INTO ch12_b.accounts (login) VALUES ('Alice');

\echo '--- 大文字小文字だけが違う値は、同じ値として扱われる（検索で見つかる） ---'
SELECT id, login FROM ch12_b.accounts WHERE login = 'alice';
SELECT id, login FROM ch12_b.accounts WHERE login = 'ALICE';

\echo '=== この節の後片付けはしない（41・42 の *_fails.sql が使う） ==='
