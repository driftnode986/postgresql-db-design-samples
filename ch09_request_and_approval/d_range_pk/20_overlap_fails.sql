-- run-as: book_owner
-- expect-error: 23P01
--
-- 採取した案で通ってしまった INSERT を、WITHOUT OVERLAPS の表に入れると拒否されることを示す。
-- x_first_idea/load.sql で入れたのと同じ 3 行を、同じ順で入れる。

CREATE SCHEMA IF NOT EXISTS ch09_d;

DROP TABLE IF EXISTS ch09_d.overlap_demo;

CREATE TABLE ch09_d.overlap_demo (
  request_id int       NOT NULL,
  valid      tstzrange NOT NULL,
  rev        int       NOT NULL,
  amount_yen int       NOT NULL,
  PRIMARY KEY (request_id, valid WITHOUT OVERLAPS)
);

-- 正しい 2 版（採取した案と同じ）
INSERT INTO ch09_d.overlap_demo VALUES
  (1, tstzrange('2026-01-01 00:00+09', '2026-01-10 00:00+09', '[)'), 1, 1000),
  (1, tstzrange('2026-01-10 00:00+09', NULL,                  '[)'), 2, 1500);

-- 重なる版。採取した案では通ったが、ここでは拒否される
INSERT INTO ch09_d.overlap_demo VALUES
  (1, tstzrange('2026-01-05 00:00+09', '2026-01-20 00:00+09', '[)'), 3, 9999);
