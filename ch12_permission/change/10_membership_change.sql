-- run-as: book_owner
-- 所属を変えたときの費用を、案A と案C で比べる。
--
-- 🔴 案A は所属の表を 1 行書き換えるだけで済む（判定表を持たないため）。
--    案C は、その変更で見え方が変わる分だけ判定表を作り直す。
--    同じ 1 つの操作で、書き換える行数が何桁違うかを測る。
--
-- 🔴 この操作はデータを変えるので、サイズと読み取りの測定より**後**に実行する
--    （第10章・第11章の教訓）。run_measure.sh がその順序を守る。
--
-- 🔴 案A 側の操作も、案C 側の操作も、測ったあとに元に戻す
--    （戻さないと後続の検査が「元データと違う」を検出してしまう）。
\timing on

\echo '=== シナリオ1「大きなチームに 1 人足す」 ==='

\echo '--- 案A: 所属を 1 行足すだけ ---'
BEGIN;
INSERT INTO ch12_a.memberships (id, user_id, scope_id, role)
VALUES ((SELECT max(id) + 1 FROM ch12_a.memberships), 7, 2, 'viewer');
\echo '案A の書き換えた行数: 上の INSERT の件数（1 行）'
ROLLBACK;

\echo '--- 案C: 判定表に、その人が新しく見られる文書ぶんを追記する ---'
-- 大きなチーム（scope 2）に利用者7 を足すと、その配下の文書がすべて見えるようになる。
BEGIN;
INSERT INTO ch12_c.memberships (id, user_id, scope_id, role)
VALUES ((SELECT max(id) + 1 FROM ch12_c.memberships), 7, 2, 'viewer');

INSERT INTO ch12_c.effective_access (user_id, document_id, role, created_at)
SELECT 7, d.id, 'viewer', d.created_at
  FROM ch12_c.documents d
  JOIN ch12_c.scopes p ON p.id = d.project_id
 WHERE p.parent_id = 2
 ORDER BY d.id
    ON CONFLICT (user_id, document_id) DO NOTHING;
\echo '案C の追記した行数: 上の INSERT の件数'
ROLLBACK;

\echo '=== シナリオ2「プロジェクトを別のチームへ移す」 ==='
-- 移すのは、文書がいちばん多いプロジェクト（偏らせたので project 22 になる）。
-- 移し先は team2（scope 3）。利用者7 のように team1 に居ない人の見え方が変わる。
\echo '--- 移すプロジェクトと、その文書数 ---'
SELECT d.project_id, count(*) AS docs, s.parent_id AS current_team
  FROM ch12_c.documents d JOIN ch12_c.scopes s ON s.id = d.project_id
 GROUP BY d.project_id, s.parent_id
 ORDER BY docs DESC LIMIT 1;

\echo '--- 案A: scopes.parent_id を 1 行書き換えるだけ ---'
BEGIN;
UPDATE ch12_a.scopes SET parent_id = 3 WHERE id = 22;
\echo '案A の書き換えた行数: 上の UPDATE の件数（1 行）'
ROLLBACK;

\echo '--- 案C: その文書に対する全利用者ぶんを作り直す ---'
BEGIN;
UPDATE ch12_c.scopes SET parent_id = 3 WHERE id = 22;

\echo '案C の削除（このプロジェクトの文書に対する判定を全部消す）'
DELETE FROM ch12_c.effective_access ea
 WHERE ea.document_id IN (SELECT id FROM ch12_c.documents WHERE project_id = 22);

\echo '案C の再作成（移動後の階層でたどり直す）'
INSERT INTO ch12_c.effective_access (user_id, document_id, role, created_at)
WITH RECURSIVE vis AS (
  SELECT m.user_id, m.scope_id AS id, m.role FROM ch12_c.memberships m
  UNION
  SELECT v.user_id, s.id, v.role FROM ch12_c.scopes s JOIN vis v ON s.parent_id = v.id
)
SELECT DISTINCT ON (v.user_id, d.id) v.user_id, d.id, v.role, d.created_at
  FROM vis v JOIN ch12_c.documents d ON d.project_id = v.id
 WHERE d.project_id = 22
 ORDER BY v.user_id, d.id, v.role;
ROLLBACK;

\echo '=== 🔴 元に戻っていること（先頭列が 0 であること） ==='
SELECT (SELECT count(*) FROM ch12_a.memberships)
       - (SELECT count(*) FROM ch12_r.src_membership) AS a_membership_delta,
       (SELECT count(*) FROM ch12_c.memberships)
       - (SELECT count(*) FROM ch12_r.src_membership) AS c_membership_delta,
       (SELECT count(*) FROM ch12_a.scopes WHERE id = 22 AND parent_id <> 2) AS a_scope_moved,
       (SELECT count(*) FROM ch12_c.scopes WHERE id = 22 AND parent_id <> 2) AS c_scope_moved;

\echo '=== シナリオ3「役割を 1 つ足す（案B の変更シナリオ）」 ==='
-- 「閲覧者だが招待もできる」役割を足す。案B は表に 2 行足すだけ。
-- 案A では、role という文字列を解釈しているコード全部を直すことになる。
BEGIN;
INSERT INTO ch12_b.roles (code, label) VALUES ('inviter', '招待できる閲覧者');
INSERT INTO ch12_b.role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM ch12_b.roles r, ch12_b.permissions p
 WHERE r.code = 'inviter' AND p.code IN ('document.read', 'member.invite');
\echo '案B の手数: INSERT 2 文（roles 1 行 + role_permissions 2 行）。DDL は無い'
SELECT r.code, string_agg(p.code, ', ' ORDER BY p.code) AS permissions
  FROM ch12_b.roles r
  JOIN ch12_b.role_permissions rp ON rp.role_id = r.id
  JOIN ch12_b.permissions p ON p.id = rp.permission_id
 WHERE r.code = 'inviter' GROUP BY r.code;
ROLLBACK;

\echo '=== 🔴 案B も元に戻っていること（先頭列が 0 であること） ==='
SELECT count(*) AS b_extra_roles FROM ch12_b.roles WHERE code = 'inviter';
