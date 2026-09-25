-- run-as: book_owner
-- NOT ENFORCED の制約は、違反する行も受け入れる
INSERT INTO ch15_e.events_ne VALUES (999999, -5);

SELECT count(*) AS violations
  FROM ch15_e.events_ne AS e
 WHERE e.amount <= 0
    OR NOT EXISTS (SELECT 1 FROM ch15_e.accounts AS a
                    WHERE a.id = e.account_id);
