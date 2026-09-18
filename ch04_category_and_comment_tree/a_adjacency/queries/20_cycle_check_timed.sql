-- verify.sql と同じ検査を、所要時間つきで測る。
-- verify.sql 側は検査として使うので \timing を入れない（出力に Time: が混ざると
-- 「全行の先頭列が 0」の判定ができなくなる）。
\timing on
WITH RECURSIVE reachable AS (
  SELECT id FROM ch04_a.nodes WHERE parent_id IS NULL
  UNION
  SELECT n.id FROM ch04_a.nodes n JOIN reachable r ON n.parent_id = r.id
)
SELECT count(*) AS unreachable
FROM ch04_a.nodes n
WHERE NOT EXISTS (SELECT 1 FROM reachable r WHERE r.id = n.id);
