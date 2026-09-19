-- 案B に元データを写す。状態の列が無いので、写すのは申請と遷移だけ。

DO $$
BEGIN
  IF (SELECT count(*) FROM ch09_r.src_request) = 0 THEN
    RAISE EXCEPTION '元データが空です。先に r_source/schema_20_generate.sql を実行してください';
  END IF;
END $$;

\timing on

DROP INDEX IF EXISTS ch09_b.idx_b_transitions;
DROP INDEX IF EXISTS ch09_b.idx_b_to_status;
DROP INDEX IF EXISTS ch09_b.idx_b_current_submitted;
DROP INDEX IF EXISTS ch09_b.idx_b_one_current;

TRUNCATE ch09_b.transitions;
TRUNCATE ch09_b.requests CASCADE;
TRUNCATE ch09_b.employees CASCADE;
TRUNCATE ch09_b.categories CASCADE;

INSERT INTO ch09_b.employees (id, name, dept)
SELECT id, name, dept FROM ch09_r.src_employee ORDER BY id;

INSERT INTO ch09_b.categories (id, code, name)
SELECT id, code, name FROM ch09_r.src_category ORDER BY id;

INSERT INTO ch09_b.requests (id, applicant_id, created_at)
SELECT id, applicant_id, created_at FROM ch09_r.src_request ORDER BY id;

-- 印は最後にまとめて付ける（本文では、この列が無い状態と付けた状態の両方を測る）
INSERT INTO ch09_b.transitions
  (request_id, seq, from_status, to_status, changed_by, changed_at, note, is_current)
SELECT request_id, seq, from_status, to_status, changed_by, changed_at, note,
       seq = max(seq) OVER (PARTITION BY request_id)
FROM ch09_r.src_transition
ORDER BY request_id, seq;

CREATE INDEX idx_b_transitions ON ch09_b.transitions (request_id, seq DESC);
CREATE INDEX idx_b_to_status ON ch09_b.transitions (to_status, changed_at DESC);
CREATE INDEX idx_b_current_submitted ON ch09_b.transitions (changed_at DESC)
  WHERE is_current AND to_status = 'submitted';
CREATE UNIQUE INDEX idx_b_one_current ON ch09_b.transitions (request_id)
  WHERE is_current;

ANALYZE ch09_b.requests;
ANALYZE ch09_b.transitions;

\timing off

-- 検査: 案A と同じ事実が入っていること（先頭列が 0 なら正常）
SELECT count(*) AS requests_diff FROM (
  (SELECT id FROM ch09_r.src_request EXCEPT SELECT id FROM ch09_b.requests)
  UNION ALL
  (SELECT id FROM ch09_b.requests EXCEPT SELECT id FROM ch09_r.src_request)
) d;

SELECT count(*) AS transitions_diff FROM (
  (SELECT request_id, seq FROM ch09_r.src_transition
   EXCEPT SELECT request_id, seq FROM ch09_b.transitions)
  UNION ALL
  (SELECT request_id, seq FROM ch09_b.transitions
   EXCEPT SELECT request_id, seq FROM ch09_r.src_transition)
) d;

-- 印が最新行だけに付いていること（先頭列が 0 なら正常）
SELECT count(*) AS wrong_current FROM (
  SELECT request_id FROM ch09_b.transitions WHERE is_current
  GROUP BY request_id HAVING count(*) <> 1
) d;

SELECT count(*) AS current_not_max FROM ch09_b.transitions t
WHERE t.is_current
  AND t.seq <> (SELECT max(seq) FROM ch09_b.transitions u WHERE u.request_id = t.request_id);

-- 印の付いた行が申請の数と一致すること
SELECT (SELECT count(*) FROM ch09_b.transitions WHERE is_current)
     - (SELECT count(*) FROM ch09_b.requests) AS current_count_diff;

SELECT CASE WHEN count(*) = 0 THEN 1 ELSE 0 END AS source_is_empty
FROM ch09_r.src_request;
