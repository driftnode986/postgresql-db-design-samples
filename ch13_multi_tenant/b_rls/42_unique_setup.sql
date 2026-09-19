-- 一意制約からの情報漏れを再現するための準備。
--
-- 「全社を通じて 1 つのメールアドレスは 1 アカウント」という要件があると、
-- 一意制約は tenant_id を含まない形になる。
-- 元データは意図的に、テナントをまたいで同じ email を持たせてある
-- （user1@example.com が全社にある）ので、
-- まず衝突する行を消してから制約を張る。
--
-- run-as: book_owner

-- 🔴 FORCE ROW LEVEL SECURITY を付けてあるので、所有者による管理作業にも
--    ポリシーが適用される。app.tenant_id を設定しないと、ポリシー式の評価が
--    失敗して DELETE すらできない。
--    ここでは準備のために、いったんポリシーを外して作業する。
ALTER TABLE ch13_b.customers NO FORCE ROW LEVEL SECURITY;
ALTER TABLE ch13_b.deals     NO FORCE ROW LEVEL SECURITY;

-- 衝突する行を消す（テナント 50 と 52 の 2 社だけ残す実験用）。
-- 案件が顧客を参照しているので、案件から先に消す。
DELETE FROM ch13_b.deals;
DELETE FROM ch13_b.customers WHERE tenant_id NOT IN (50, 52);
-- 50 と 52 は同じアドレスの並び（user1〜user50）を持つので、52 側を消す
DELETE FROM ch13_b.customers WHERE tenant_id = 52;

-- テナント 52 にだけ存在するアドレスを 1 件用意する
INSERT INTO ch13_b.customers (tenant_id, id, email, name)
VALUES (52, 5200999, 'secret@t52.example.com', 'only-in-52');

-- 全社で一意（tenant_id を含まない）
CREATE UNIQUE INDEX customers_email_global ON ch13_b.customers (email);

SELECT count(*) AS customers_left,
       count(*) FILTER (WHERE email = 'secret@t52.example.com') AS secret_rows
FROM ch13_b.customers;

-- ポリシーを戻す。ここから先は所有者にもポリシーが適用される。
ALTER TABLE ch13_b.customers FORCE ROW LEVEL SECURITY;
