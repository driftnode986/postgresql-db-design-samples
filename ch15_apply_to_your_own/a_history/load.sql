-- 申請を 1 件作り、状態を 2 回変える。変える前の行を履歴に写す。
TRUNCATE ch15_a.requests RESTART IDENTITY;

INSERT INTO ch15_a.requests (applicant_name, reason, status)
VALUES ('佐藤 花子', '通院のため', 'draft');

WITH old AS (
  UPDATE ch15_a.requests SET status = 'submitted' WHERE id = 1
  RETURNING old.*
)
INSERT INTO ch15_a.request_history (request_id, applicant_name, reason, status)
SELECT id, applicant_name, reason, status FROM old;

WITH old AS (
  UPDATE ch15_a.requests SET status = 'approved' WHERE id = 1
  RETURNING old.*
)
INSERT INTO ch15_a.request_history (request_id, applicant_name, reason, status)
SELECT id, applicant_name, reason, status FROM old;
