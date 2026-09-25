TRUNCATE ch15_b.request_pii, ch15_b.requests RESTART IDENTITY;

INSERT INTO ch15_b.requests (status) VALUES ('draft');
INSERT INTO ch15_b.request_pii VALUES (1, '佐藤 花子', '通院のため');

WITH old AS (
  UPDATE ch15_b.requests SET status = 'submitted' WHERE id = 1
  RETURNING old.*
)
INSERT INTO ch15_b.request_history (request_id, status)
SELECT id, status FROM old;

WITH old AS (
  UPDATE ch15_b.requests SET status = 'approved' WHERE id = 1
  RETURNING old.*
)
INSERT INTO ch15_b.request_history (request_id, status)
SELECT id, status FROM old;
