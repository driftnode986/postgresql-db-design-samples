-- run-as: book_owner
-- expect-error: 23503
-- 1 月からの版の期間を、5 月までに縮める（料金表の手直し）。
-- 契約の 5 月から 7 月が、どの版にも覆われなくなる。
UPDATE ch15_c.plan_prices
   SET valid = '[2026-01-01,2026-05-01)'
 WHERE plan_id = 1 AND lower(valid) = '2026-01-01';
