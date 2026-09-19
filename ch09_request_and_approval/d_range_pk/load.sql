-- 案D に元データを写す。
-- 案C と同じ事実を、2 列ではなく範囲型 1 列に入れる。半開区間 '[)' にする
-- （終わりの時刻はその版に含めない。境目の時刻がどちらの版に属するかが一意に決まる）。

DO $$
BEGIN
  IF (SELECT count(*) FROM ch09_r.src_revision) = 0 THEN
    RAISE EXCEPTION '元データが空です。先に r_source/schema_20_generate.sql を実行してください';
  END IF;
END $$;

\timing on

-- 主キー（GiST）は落とせないが、後から足した 2 つは落としてから入れる
DROP INDEX IF EXISTS ch09_d.idx_d_current;
DROP INDEX IF EXISTS ch09_d.idx_d_valid_gist;

TRUNCATE ch09_d.revisions;
TRUNCATE ch09_d.requests CASCADE;
TRUNCATE ch09_d.employees CASCADE;
TRUNCATE ch09_d.categories CASCADE;

INSERT INTO ch09_d.employees (id, name, dept)
SELECT id, name, dept FROM ch09_r.src_employee ORDER BY id;

INSERT INTO ch09_d.categories (id, code, name)
SELECT id, code, name FROM ch09_r.src_category ORDER BY id;

INSERT INTO ch09_d.requests (id, applicant_id, created_at)
SELECT id, applicant_id, created_at FROM ch09_r.src_request ORDER BY id;

-- 主キーが GiST インデックスなので、ここではインデックスを落とせない（主キーの一部）。
INSERT INTO ch09_d.revisions
  (request_id, valid, rev, amount_yen, category_id, reason, edited_by)
SELECT request_id,
       tstzrange(valid_from,
                 lead(valid_from) OVER (PARTITION BY request_id ORDER BY rev),
                 '[)'),
       rev, amount_yen, category_id, reason, edited_by
FROM ch09_r.src_revision
ORDER BY request_id, rev;

-- インデックスはデータを入れ終えてから作る
CREATE INDEX idx_d_current ON ch09_d.revisions (request_id) WHERE upper_inf(valid);
CREATE INDEX idx_d_valid_gist ON ch09_d.revisions USING gist (valid);

ANALYZE ch09_d.requests;
ANALYZE ch09_d.revisions;

\timing off

-- 検査（すべて先頭列が 0 なら正常）
SELECT count(*) AS revisions_diff FROM (
  (SELECT request_id, rev FROM ch09_r.src_revision
   EXCEPT SELECT request_id, rev FROM ch09_d.revisions)
  UNION ALL
  (SELECT request_id, rev FROM ch09_d.revisions
   EXCEPT SELECT request_id, rev FROM ch09_r.src_revision)
) d;

-- 案C（本体 + 履歴）と同じ内容が入っていること（金額・科目・理由まで突き合わせる）
SELECT count(*) AS content_diff FROM (
  (
    SELECT id AS request_id, rev, amount_yen, category_id, reason FROM ch09_c.requests
    UNION ALL
    SELECT request_id, rev, amount_yen, category_id, reason FROM ch09_c.request_history
  )
  EXCEPT
  SELECT request_id, rev, amount_yen, category_id, reason FROM ch09_d.revisions
) d;

SELECT CASE WHEN count(*) = 0 THEN 1 ELSE 0 END AS source_is_empty
FROM ch09_r.src_revision;
