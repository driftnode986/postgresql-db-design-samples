-- run-as: book_owner
-- 案C で、退会した利用者の個人情報がどこに残っているかを数える。
-- 🔴 案C は profiles と order_shipments の行ごと消えるので、残らない。
SELECT 'c: profiles（退会者ぶん）' AS place, count(*) AS rows
FROM ch14_c.accounts a JOIN ch14_c.profiles p ON p.account_id = a.id
WHERE a.status = 'withdrawn'
UNION ALL
SELECT 'c: order_shipments（退会者の注文ぶん）', count(*)
FROM ch14_c.orders o
JOIN ch14_c.accounts a ON a.id = o.account_id
JOIN ch14_c.order_shipments s ON s.order_id = o.id
WHERE a.status = 'withdrawn'
ORDER BY 1;
