-- run-as: book_owner
-- 直下の子を、depth = 1 の部分インデックスが無い状態で引く（比較用）。
-- 主キー (ancestor_id, descendant_id) には depth が入っていないので、
-- 子孫を全部読んでから depth = 1 で絞ることになる。
-- インデックスを削除して測り、ROLLBACK で元に戻す（他の測定に影響させない）。
BEGIN;
DROP INDEX ch04_b.paths_child_idx;

-- 🔴 12_children.sql と同じ問い合わせにする（返す列も並べ替えも同じ）。
--    片方が count(*) だと、インデックスの差ではなく問い合わせの差を測ることになる。
EXPLAIN (ANALYZE)
SELECT descendant_id FROM ch04_b.paths
WHERE ancestor_id = 11 AND depth = 1
ORDER BY descendant_id;

ROLLBACK;
