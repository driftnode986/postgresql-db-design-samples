-- 案B で、同じ「条件を書き忘れた問い合わせ」を実行する。
-- SQL は案A の (1) と 1 文字も変わらない。違うのはポリシーがあることだけ。
--
-- run-as: book_app
\set me 50

SELECT set_config('app.tenant_id', :'me', false);

-- 案A では 999,400 行が返った同じ SQL
SELECT count(*)                                 AS rows_returned,
       count(*) FILTER (WHERE tenant_id <> :me) AS leaked_rows_must_be_zero
FROM ch13_b.deals;

-- 他社の行を 1 件だけ狙って読もうとしても返らない
SELECT count(*) AS other_tenant_rows_must_be_zero
FROM ch13_b.deals
WHERE tenant_id = 51;
