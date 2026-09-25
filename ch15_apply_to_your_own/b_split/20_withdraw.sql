-- run-as: book_owner
-- 退会したら、個人情報のテーブルから行を消す。履歴には触れない
DELETE FROM ch15_b.request_pii WHERE request_id = 1;
