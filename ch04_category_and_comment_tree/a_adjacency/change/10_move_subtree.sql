-- ノード 11 の部分木（子孫 84,700 件）を、別の親（ノード 3）へ移す。
-- 親を指す 1 行を書き換えるだけで、子孫の行には触れない。
-- 測ったあとは ROLLBACK で戻す（他の測定に影響させない）。
\timing on
BEGIN;
UPDATE ch04_a.nodes SET parent_id = 3 WHERE id = 11;
ROLLBACK;
