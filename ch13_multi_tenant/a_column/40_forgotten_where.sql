-- 案A で、絞り込みの条件を書き忘れた問い合わせを実行する。
-- テナント 50 のアプリのつもりで実行している。
--
-- run-as: book_app
\set me 50

-- (1) 条件を書き忘れた一覧
SELECT count(*)                                        AS rows_returned,
       count(*) FILTER (WHERE tenant_id <> :me)        AS leaked_rows
FROM ch13_a.deals;

-- (2) 条件を書いた一覧（正しい実装）
SELECT count(*)                                        AS rows_returned,
       count(*) FILTER (WHERE tenant_id <> :me)        AS leaked_rows_must_be_zero
FROM ch13_a.deals
WHERE tenant_id = :me;
