-- 案C に元データを写す。
-- 最新の版は本体（requests）へ、それより前の版は履歴（request_history）へ入れる。

DO $$
BEGIN
  IF (SELECT count(*) FROM ch09_r.src_revision) = 0 THEN
    RAISE EXCEPTION '元データが空です。先に r_source/schema_20_generate.sql を実行してください';
  END IF;
END $$;

\timing on

DROP INDEX IF EXISTS ch09_c.idx_c_hist_asof;

TRUNCATE ch09_c.request_history;
TRUNCATE ch09_c.requests CASCADE;
TRUNCATE ch09_c.employees CASCADE;
TRUNCATE ch09_c.categories CASCADE;

INSERT INTO ch09_c.employees (id, name, dept)
SELECT id, name, dept FROM ch09_r.src_employee ORDER BY id;

INSERT INTO ch09_c.categories (id, code, name)
SELECT id, code, name FROM ch09_r.src_category ORDER BY id;

-- 本体には最新の版（rev が最大のもの）を入れる
INSERT INTO ch09_c.requests
  (id, applicant_id, rev, amount_yen, category_id, reason, edited_by, created_at, updated_at)
SELECT r.id, r.applicant_id, v.rev, v.amount_yen, v.category_id, v.reason, v.edited_by,
       r.created_at, v.valid_from
FROM ch09_r.src_request r
JOIN LATERAL (
  SELECT rev, amount_yen, category_id, reason, edited_by, valid_from
  FROM ch09_r.src_revision
  WHERE request_id = r.id
  ORDER BY rev DESC
  LIMIT 1
) v ON true
ORDER BY r.id;

-- 履歴には、最新より前の版を入れる
INSERT INTO ch09_c.request_history
  (request_id, rev, amount_yen, category_id, reason, edited_by, valid_from)
SELECT s.request_id, s.rev, s.amount_yen, s.category_id, s.reason, s.edited_by, s.valid_from
FROM ch09_r.src_revision s
JOIN ch09_c.requests c ON c.id = s.request_id
WHERE s.rev < c.rev
ORDER BY s.request_id, s.rev;

CREATE INDEX idx_c_hist_asof ON ch09_c.request_history (request_id, valid_from DESC);

ANALYZE ch09_c.requests;
ANALYZE ch09_c.request_history;

\timing off

-- 検査（すべて先頭列が 0 なら正常）
-- 本体と履歴を合わせると元データの全版になること
SELECT count(*) AS versions_diff FROM (
  SELECT request_id, rev FROM ch09_r.src_revision
  EXCEPT (
    SELECT id, rev FROM ch09_c.requests
    UNION ALL SELECT request_id, rev FROM ch09_c.request_history
  )
  UNION ALL
  (
    SELECT id, rev FROM ch09_c.requests
    UNION ALL SELECT request_id, rev FROM ch09_c.request_history
  )
  EXCEPT SELECT request_id, rev FROM ch09_r.src_revision
) d;

-- 本体の版が、その申請の最大の版であること
SELECT count(*) AS body_not_latest FROM ch09_c.requests c
WHERE c.rev <> (SELECT max(rev) FROM ch09_r.src_revision s WHERE s.request_id = c.id);

-- 内容まで一致していること（金額・科目・理由）
SELECT count(*) AS content_diff FROM (
  SELECT request_id, rev, amount_yen, category_id, reason FROM ch09_r.src_revision
  EXCEPT (
    SELECT id, rev, amount_yen, category_id, reason FROM ch09_c.requests
    UNION ALL
    SELECT request_id, rev, amount_yen, category_id, reason FROM ch09_c.request_history
  )
) d;

SELECT CASE WHEN count(*) = 0 THEN 1 ELSE 0 END AS source_is_empty
FROM ch09_r.src_revision;
