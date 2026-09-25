-- run-as: book_owner
-- 案B で、退会した利用者の個人情報がどこに残っているかを数える。
-- 🔴 案B は users の行ごと消えるが、復元のための控えに写っている。
--    「消した」と言えるのは、控えからも消える 30 日後である。
SELECT 'b: withdrawn_users（復元用の控え。個人情報が残る）' AS place,
       count(*) AS rows
FROM ch14_b.withdrawn_users
UNION ALL
-- 注文は残す（売上集計が変わってはいけない）ので、配送先の個人情報も残る。
-- user_id が NULL の注文 = 退会した利用者の注文。
SELECT 'b: orders（配送先の宛名・住所・電話）', count(*)
FROM ch14_b.orders WHERE user_id IS NULL
ORDER BY 1;
