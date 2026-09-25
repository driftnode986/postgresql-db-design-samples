TRUNCATE ch15_c.contracts, ch15_c.plan_prices;

INSERT INTO ch15_c.plan_prices VALUES
  (1, '[2026-01-01,2026-07-01)', 980),
  (1, '[2026-07-01,)',           1200);

-- 3 月から 9 月までの契約は、2 つの版にまたがる
INSERT INTO ch15_c.contracts VALUES (10, 1, '[2026-03-01,2026-09-01)');
