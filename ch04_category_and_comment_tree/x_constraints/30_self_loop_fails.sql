-- expect-error: 23514
-- run-as: book_owner
-- 自己ループは CHECK に弾かれる
UPDATE ch04_x.nodes SET parent_id = 1 WHERE id = 1;
