-- run-as: book_owner
-- 18 の RETURNING old / new で、更新と履歴への保存を 1 文で書く。
--
-- 案C は「更新前の行を履歴へ写す」設計なので、写し忘れる経路がある。
-- 18 では UPDATE ... RETURNING old.* を CTE で受けて履歴へ INSERT できるため、
-- 「更新したのに履歴を書かない」が構文の上で起きにくくなる。

\echo '=== 更新前の内容（申請 50000） ==='
SELECT id, rev, amount_yen, reason, updated_at FROM ch09_c.requests WHERE id = 50000;

SELECT count(*) AS history_rows_before
FROM ch09_c.request_history WHERE request_id = 50000;

\echo '=== 1 文で「更新」と「更新前の行の保存」を行う ==='
WITH upd AS (
  UPDATE ch09_c.requests
     SET amount_yen = amount_yen + 5000,
         reason     = '訂正（領収書の再提出）',
         rev        = rev + 1,
         updated_at = timestamptz '2026-03-01 10:00:00+09'
   WHERE id = 50000
  RETURNING old.id          AS request_id,
            old.rev         AS rev,
            old.amount_yen  AS amount_yen,
            old.category_id AS category_id,
            old.reason      AS reason,
            old.edited_by   AS edited_by,
            old.updated_at  AS valid_from
)
INSERT INTO ch09_c.request_history
  (request_id, rev, amount_yen, category_id, reason, edited_by, valid_from)
SELECT request_id, rev, amount_yen, category_id, reason, edited_by, valid_from
FROM upd;

\echo '=== 更新後の内容と、履歴に入った更新前の行 ==='
SELECT id, rev, amount_yen, reason, updated_at FROM ch09_c.requests WHERE id = 50000;

SELECT rev, amount_yen, reason, valid_from
FROM ch09_c.request_history WHERE request_id = 50000 ORDER BY rev;

\echo '=== old と new を同じ文で返す（遷移の from と to を 1 回で取る） ==='
UPDATE ch09_c.requests
   SET amount_yen = amount_yen - 5000,
       rev        = rev + 1,
       updated_at = timestamptz '2026-03-02 10:00:00+09'
 WHERE id = 50000
RETURNING old.amount_yen AS 更新前, new.amount_yen AS 更新後,
          new.amount_yen - old.amount_yen AS 差;

\echo '=== 🔴 old.*, new.* は列名が重複したまま返る（INSERT ... SELECT * に渡すとずれる） ==='
UPDATE ch09_c.requests SET rev = rev WHERE id = 50000
RETURNING old.id, new.id;

\echo '=== 後片付け（測定を繰り返せるように元へ戻す） ==='
-- 🔴 履歴は「元データに無い行を消す」で戻す。rev の番号で消すと、
--    元から履歴にあった版（この申請では rev 2）まで残したり消したりしてしまう。
--    実際に rev >= 3 だけを消したところ、本体と履歴に同じ (request_id, rev) が
--    二重に残り、案D への移行で空の範囲ができて WITHOUT OVERLAPS に弾かれた。
DELETE FROM ch09_c.request_history h
WHERE h.request_id = 50000
  AND h.rev >= (SELECT max(rev) FROM ch09_r.src_revision WHERE request_id = 50000);

UPDATE ch09_c.requests c
   SET rev = v.rev, amount_yen = v.amount_yen, category_id = v.category_id,
       reason = v.reason, edited_by = v.edited_by, updated_at = v.valid_from
  FROM (SELECT rev, amount_yen, category_id, reason, edited_by, valid_from
        FROM ch09_r.src_revision WHERE request_id = 50000
        ORDER BY rev DESC LIMIT 1) v
 WHERE c.id = 50000;

-- 戻ったことの検査（すべて先頭列が 0 なら正常）
SELECT count(*) AS not_restored FROM ch09_c.requests c
JOIN (SELECT rev, amount_yen FROM ch09_r.src_revision WHERE request_id = 50000
      ORDER BY rev DESC LIMIT 1) v ON true
WHERE c.id = 50000 AND (c.rev <> v.rev OR c.amount_yen <> v.amount_yen);

-- 本体と履歴を合わせた版が、元データと一致していること
SELECT count(*) AS restore_diff FROM (
  SELECT request_id, rev, amount_yen FROM ch09_r.src_revision WHERE request_id = 50000
  EXCEPT (
    SELECT id, rev, amount_yen FROM ch09_c.requests WHERE id = 50000
    UNION ALL
    SELECT request_id, rev, amount_yen FROM ch09_c.request_history WHERE request_id = 50000
  )
  UNION ALL
  (
    SELECT id, rev, amount_yen FROM ch09_c.requests WHERE id = 50000
    UNION ALL
    SELECT request_id, rev, amount_yen FROM ch09_c.request_history WHERE request_id = 50000
  )
  EXCEPT SELECT request_id, rev, amount_yen FROM ch09_r.src_revision WHERE request_id = 50000
) d;
