-- run-as: book_owner
-- 直下の子を、depth = 1 の部分インデックスが無い状態で引く（比較用）。
-- 主キー (ancestor_id, descendant_id) には depth が入っていないので、
-- 子孫を全部読んでから depth = 1 で絞ることになる。
-- インデックスを削除して測り、ROLLBACK で元に戻す（他の測定に影響させない）。
BEGIN;
DROP INDEX ch04_b.paths_child_idx;

EXPLAIN (ANALYZE)
SELECT count(*) FROM ch04_b.paths WHERE ancestor_id = 11 AND depth = 1;

ROLLBACK;
