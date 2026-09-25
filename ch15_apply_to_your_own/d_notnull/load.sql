-- 10 万行のうち 100 行に 1 行、メールアドレスが入っていない
TRUNCATE ch15_d.users RESTART IDENTITY;

INSERT INTO ch15_d.users (email)
SELECT CASE WHEN i % 100 = 0 THEN NULL
            ELSE 'user' || i || '@example.com' END
  FROM generate_series(1, 100000) AS i
 ORDER BY i;

ANALYZE ch15_d.users;
