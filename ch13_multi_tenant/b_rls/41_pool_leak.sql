-- 🔴 ポリシーを正しく設定していても、設定の寿命を間違えると他社の行が見える。
--
-- set_config の第 3 引数（is_local）が true なら、その設定はトランザクションが
-- 終わると消える。false にすると接続が閉じるまで残る。
-- 接続プールは同じ接続を次の利用者に渡すので、false にすると前の利用者の
-- テナント ID が残ったままになる。
--
-- run-as: book_app

-- (1) 利用者A（テナント 50）のリクエスト。is_local = false で設定してしまった
BEGIN;
  SELECT set_config('app.tenant_id', '50', false) AS set_with_is_local_false;
  SELECT count(*) AS rows_visible_to_user_a FROM ch13_b.deals;
COMMIT;

-- (2) 接続がプールに返り、利用者B（テナント 51）が借りた。
--     利用者B のコードは set_config を呼び忘れている。
BEGIN;
  SELECT current_setting('app.tenant_id') AS tenant_id_still_set,
         count(*)                         AS rows_visible_to_user_b
  FROM ch13_b.deals;
COMMIT;

-- (3) 正しい書き方。is_local = true なら次のトランザクションに残らない。
BEGIN;
  SELECT set_config('app.tenant_id', '50', true) AS set_with_is_local_true;
  SELECT count(*) AS rows_visible_inside_tx FROM ch13_b.deals;
COMMIT;

SELECT current_setting('app.tenant_id', true) AS tenant_id_after_commit;

-- 後片付け。次の測定に影響させない。
SELECT set_config('app.tenant_id', '50', false);
