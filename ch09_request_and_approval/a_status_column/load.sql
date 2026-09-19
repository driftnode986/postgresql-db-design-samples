-- 案A に元データを写す。
--
-- 🔴 先頭で元データが空でないことを確かめ、空なら何も消す前に止める
--    （検証の実行順のせいで元データより先に走ると、空を写したまま全件 OK になる。CLAUDE.md の規約）。
-- 🔴 入れ直しても同じ結果になるように TRUNCATE ... RESTART IDENTITY してから入れる。
-- 🔴 データを入れてからインデックスを作る（付けたまま入れると充填率が変わり、サイズが実行のたびに変わる）。

DO $$
BEGIN
  IF (SELECT count(*) FROM ch09_r.src_request) = 0 THEN
    RAISE EXCEPTION '元データが空です。先に r_source/schema_20_generate.sql を実行してください';
  END IF;
END $$;

\timing on

-- インデックスを落としてから入れる（再実行できるように）
DROP INDEX IF EXISTS ch09_a.idx_a_submitted;
DROP INDEX IF EXISTS ch09_a.idx_a_transitions;

TRUNCATE ch09_a.transitions;
TRUNCATE ch09_a.requests CASCADE;
TRUNCATE ch09_a.employees CASCADE;
TRUNCATE ch09_a.categories CASCADE;

INSERT INTO ch09_a.employees (id, name, dept)
SELECT id, name, dept FROM ch09_r.src_employee ORDER BY id;

INSERT INTO ch09_a.categories (id, code, name)
SELECT id, code, name FROM ch09_r.src_category ORDER BY id;

-- 申請。状態は「最新の遷移の to_status」を写す。
-- updated_at は最新の遷移の時刻。
INSERT INTO ch09_a.requests (id, applicant_id, status, created_at, updated_at)
SELECT r.id, r.applicant_id, t.to_status, r.created_at, t.changed_at
FROM ch09_r.src_request r
JOIN LATERAL (
  SELECT to_status, changed_at
  FROM ch09_r.src_transition
  WHERE request_id = r.id
  ORDER BY seq DESC
  LIMIT 1
) t ON true
ORDER BY r.id;

INSERT INTO ch09_a.transitions
  (request_id, seq, from_status, to_status, changed_by, changed_at, note)
SELECT request_id, seq, from_status, to_status, changed_by, changed_at, note
FROM ch09_r.src_transition
ORDER BY request_id, seq;

-- インデックスはデータを入れ終えてから作る
CREATE INDEX idx_a_submitted ON ch09_a.requests (created_at DESC, id DESC)
  WHERE status = 'submitted';
CREATE INDEX idx_a_transitions ON ch09_a.transitions (request_id, changed_at);

ANALYZE ch09_a.requests;
ANALYZE ch09_a.transitions;

\timing off

-- 検査: 元データと件数が一致していること（先頭列が 0 なら正常）
SELECT count(*) AS requests_diff FROM (
  (SELECT id FROM ch09_r.src_request EXCEPT SELECT id FROM ch09_a.requests)
  UNION ALL
  (SELECT id FROM ch09_a.requests EXCEPT SELECT id FROM ch09_r.src_request)
) d;

SELECT count(*) AS transitions_diff FROM (
  (SELECT request_id, seq FROM ch09_r.src_transition
   EXCEPT SELECT request_id, seq FROM ch09_a.transitions)
  UNION ALL
  (SELECT request_id, seq FROM ch09_a.transitions
   EXCEPT SELECT request_id, seq FROM ch09_r.src_transition)
) d;

-- 元データが空でないことも同時に見る（0 件どうしの比較は常に 0 になるため）
SELECT CASE WHEN count(*) = 0 THEN 1 ELSE 0 END AS source_is_empty
FROM ch09_r.src_request;
