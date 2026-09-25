-- run-as: book_owner
-- 申請者が退会した。本体の個人情報を消す。
UPDATE ch15_a.requests
   SET applicant_name = NULL, reason = NULL
 WHERE id = 1;
