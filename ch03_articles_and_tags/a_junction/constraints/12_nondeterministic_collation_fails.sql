-- run-as: book_owner
-- expect-error: 23505
-- 同じ表記ゆれは、2 件目の時点で一意制約に弾かれる
INSERT INTO ch03_a.tags_ci VALUES ('postgresql');
