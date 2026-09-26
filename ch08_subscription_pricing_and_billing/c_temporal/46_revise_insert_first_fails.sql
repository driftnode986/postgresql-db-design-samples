-- run-as: book_owner
-- expect-error: 23P01
-- 順序を入れ替えて、先に新しい版を足す。今の版（上端なし）と期間が重なり、主キーに弾かれる。
INSERT INTO ch08_c.plan_prices (plan_id, valid, price_yen)
SELECT plan_id, daterange(DATE '2024-05-01', NULL), (price_yen * 1.2)::int
FROM ch08_c.plan_prices WHERE upper_inf(valid);
