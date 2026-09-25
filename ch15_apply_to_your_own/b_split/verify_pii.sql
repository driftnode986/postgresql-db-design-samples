-- 退会した申請者の個人情報が残っている行数（0 であること）と、履歴の行数
SELECT (SELECT count(*) FROM ch15_b.request_pii WHERE request_id = 1)
         AS pii_rows,
       (SELECT count(*) FROM ch15_b.request_history WHERE request_id = 1)
         AS history_rows;
