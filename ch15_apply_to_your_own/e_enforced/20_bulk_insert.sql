-- run-as: book_owner
-- 100 万行を一括で入れる。3 つの表を交互に 5 回ずつ入れ、Time の中央値で比べる
SELECT setseed(0.15);
CREATE TEMP TABLE src AS
SELECT (random() * 99999)::bigint + 1 AS account_id,
       (random() * 999)::int + 1      AS amount
  FROM generate_series(1, 1000000);

\timing on
-- 1 回目
TRUNCATE ch15_e.events_none;
INSERT INTO ch15_e.events_none SELECT * FROM src;
TRUNCATE ch15_e.events_fk;
INSERT INTO ch15_e.events_fk SELECT * FROM src;
TRUNCATE ch15_e.events_ne;
INSERT INTO ch15_e.events_ne SELECT * FROM src;
-- 2 回目
TRUNCATE ch15_e.events_none;
INSERT INTO ch15_e.events_none SELECT * FROM src;
TRUNCATE ch15_e.events_fk;
INSERT INTO ch15_e.events_fk SELECT * FROM src;
TRUNCATE ch15_e.events_ne;
INSERT INTO ch15_e.events_ne SELECT * FROM src;
-- 3 回目
TRUNCATE ch15_e.events_none;
INSERT INTO ch15_e.events_none SELECT * FROM src;
TRUNCATE ch15_e.events_fk;
INSERT INTO ch15_e.events_fk SELECT * FROM src;
TRUNCATE ch15_e.events_ne;
INSERT INTO ch15_e.events_ne SELECT * FROM src;
-- 4 回目
TRUNCATE ch15_e.events_none;
INSERT INTO ch15_e.events_none SELECT * FROM src;
TRUNCATE ch15_e.events_fk;
INSERT INTO ch15_e.events_fk SELECT * FROM src;
TRUNCATE ch15_e.events_ne;
INSERT INTO ch15_e.events_ne SELECT * FROM src;
-- 5 回目
TRUNCATE ch15_e.events_none;
INSERT INTO ch15_e.events_none SELECT * FROM src;
TRUNCATE ch15_e.events_fk;
INSERT INTO ch15_e.events_fk SELECT * FROM src;
TRUNCATE ch15_e.events_ne;
INSERT INTO ch15_e.events_ne SELECT * FROM src;
\timing off
