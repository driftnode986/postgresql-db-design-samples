-- run-as: book_app
-- expect-error: 23505
-- 🔴 見えない行の存在が、一意制約のエラーから分かる。
--
-- テナント 50 として接続する。テナント 52 の顧客は 1 件も見えない。
-- それなのに、52 が使っているアドレスを登録しようとするとエラーになる。
-- つまり「そのアドレスは他社が使っている」と分かってしまう。
--
-- 公式マニュアルはこれを covert channel として警告している。
-- 参照整合性の検査（一意制約・主キー・外部キー）は、データの整合性を保つため、
-- 常に行レベルセキュリティを迂回する。
--
SELECT set_config('app.tenant_id', '50', false);

-- (1) テナント 50 からは、そのアドレスの行は 1 件も見えない
SELECT count(*) AS visible_rows_with_that_email
FROM ch13_b.customers
WHERE email = 'secret@t52.example.com';

-- (2) だが同じアドレスを自社に登録しようとすると弾かれる
INSERT INTO ch13_b.customers (tenant_id, id, email, name)
VALUES (50, 5000999, 'secret@t52.example.com', 'mine');
