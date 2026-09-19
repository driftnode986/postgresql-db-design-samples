-- ポリシーを付けた表を、表を作った本人（所有者）で読む。
--
-- FORCE を外すと、所有者にはポリシーが適用されない。
-- 「設定したのに何も制限されていない」という状態は、
-- 所有者のまま動作確認していると気づけない。
--
-- run-as: book_owner
SELECT set_config('app.tenant_id', '50', false);

-- (1) FORCE を外した状態。所有者にはポリシーが効かない
ALTER TABLE ch13_b.deals NO FORCE ROW LEVEL SECURITY;
SELECT count(*)                                  AS rows_visible_to_owner,
       count(*) FILTER (WHERE tenant_id <> 50)  AS other_tenant_rows
FROM ch13_b.deals;

-- (2) FORCE を戻すと、所有者にも効く
ALTER TABLE ch13_b.deals FORCE ROW LEVEL SECURITY;
SELECT count(*)                                  AS rows_visible_to_owner,
       count(*) FILTER (WHERE tenant_id <> 50)  AS other_tenant_rows_must_be_zero
FROM ch13_b.deals;

-- 自分がスーパーユーザーでも BYPASSRLS でもないことを示す
SELECT current_user, rolsuper, rolbypassrls
FROM pg_roles WHERE rolname = current_user;
