TRUNCATE ch15_e.accounts CASCADE;
INSERT INTO ch15_e.accounts
SELECT i FROM generate_series(1, 100000) AS i ORDER BY i;
ANALYZE ch15_e.accounts;
