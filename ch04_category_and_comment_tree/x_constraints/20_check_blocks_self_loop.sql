-- run-as: book_owner
-- 自分自身を親にすることだけは CHECK で防げる（他の行を見ないため）
ALTER TABLE ch04_x.nodes DROP CONSTRAINT IF EXISTS no_self;
UPDATE ch04_x.nodes SET parent_id = 2 WHERE id = 1;   -- 輪をほどいておく
ALTER TABLE ch04_x.nodes ADD CONSTRAINT no_self CHECK (parent_id <> id);
