-- 退会した申請者の個人情報が、どこに何行残っているか
SELECT 'requests' AS tbl, count(*) AS pii_rows
  FROM ch15_a.requests
 WHERE id = 1 AND applicant_name IS NOT NULL
UNION ALL
SELECT 'request_history', count(*)
  FROM ch15_a.request_history
 WHERE request_id = 1 AND applicant_name IS NOT NULL;
