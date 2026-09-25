-- run-as: book_owner
-- expect-error: request_history is append-only
-- 履歴に写した個人情報も消そうとする。トリガーがエラーを返す。
UPDATE ch15_a.request_history
   SET applicant_name = NULL, reason = NULL
 WHERE request_id = 1;
