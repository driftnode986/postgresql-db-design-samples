-- 採取した案の検算。
-- 正しい 2 版を入れたあと、重なる版とすき間のある版を入れてみる。
-- どちらも通ってしまうこと、その結果「ある時点の内容」が一意に決まらなくなることを示す。

TRUNCATE ch09_x.revisions;

\echo '--- 正しい 2 版（申請 1） ---'
INSERT INTO ch09_x.revisions VALUES
  (1, 1, 1000, '2026-01-01 00:00+09', '2026-01-10 00:00+09'),
  (1, 2, 1500, '2026-01-10 00:00+09', NULL);

\echo '--- 重なる版を入れる（1/05〜1/20 は版 1 とも版 2 とも重なる） ---'
INSERT INTO ch09_x.revisions VALUES
  (1, 3, 9999, '2026-01-05 00:00+09', '2026-01-20 00:00+09');

\echo '--- すき間のある版を入れる（申請 2。1/10 で閉じ、1/20 から始める） ---'
INSERT INTO ch09_x.revisions VALUES
  (2, 1, 2000, '2026-01-01 00:00+09', '2026-01-10 00:00+09'),
  (2, 2, 2500, '2026-01-20 00:00+09', NULL);

\echo '--- 入った行 ---'
SELECT request_id, rev, amount_yen, valid_from, valid_to
FROM ch09_x.revisions ORDER BY request_id, rev;

\echo '--- 申請 1 の 2026-01-07 時点の内容を聞く（1 つに決まらない） ---'
SELECT request_id, rev, amount_yen FROM ch09_x.revisions
WHERE request_id = 1
  AND valid_from <= '2026-01-07 00:00+09'
  AND (valid_to IS NULL OR valid_to > '2026-01-07 00:00+09')
ORDER BY rev;

\echo '--- 申請 2 の 2026-01-15 時点の内容を聞く（1 件も返らない） ---'
SELECT request_id, rev, amount_yen FROM ch09_x.revisions
WHERE request_id = 2
  AND valid_from <= '2026-01-15 00:00+09'
  AND (valid_to IS NULL OR valid_to > '2026-01-15 00:00+09')
ORDER BY rev;

\echo '--- 重なりとすき間を数える検査（0 でないことが問題である） ---'
SELECT count(*) AS overlapping FROM ch09_x.revisions a
JOIN ch09_x.revisions b
  ON a.request_id = b.request_id AND a.rev < b.rev
 AND tstzrange(a.valid_from, a.valid_to) && tstzrange(b.valid_from, b.valid_to);

SELECT count(*) AS gapped FROM (
  SELECT request_id, valid_to,
         lead(valid_from) OVER (PARTITION BY request_id ORDER BY valid_from) AS next_from
  FROM ch09_x.revisions
) s
WHERE next_from IS NOT NULL AND valid_to IS DISTINCT FROM next_from;
