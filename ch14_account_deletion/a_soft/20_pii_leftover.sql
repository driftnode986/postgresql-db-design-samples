-- run-as: book_owner
-- 案A で、退会した利用者の個人情報がどこに残っているかを数える。
-- 🔴 案A は行を残すので、個人情報は「退会した利用者ぶん」がそのまま残る。
SELECT 'a: users（氏名・メール・住所・電話）' AS place, count(*) AS rows
FROM ch14_a.users WHERE deleted_at IS NOT NULL
UNION ALL
SELECT 'a: orders（配送先の宛名・住所・電話）', count(*)
FROM ch14_a.orders o JOIN ch14_a.users u ON u.id = o.user_id
WHERE u.deleted_at IS NOT NULL
ORDER BY 1;
