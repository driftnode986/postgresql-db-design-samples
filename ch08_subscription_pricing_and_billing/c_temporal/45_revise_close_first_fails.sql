-- run-as: book_owner
-- expect-error: 23503
-- 案C の改定を、案B と同じ 2 文で流す（1 文目）。検査を遅らせないと、ここで止まる。
-- 今の版を 2024-05-01 で閉じた瞬間に、上端の無い契約の 5 月以降を覆う版が無くなる。
UPDATE ch08_c.plan_prices SET valid = daterange(lower(valid), DATE '2024-05-01')
WHERE upper_inf(valid);
