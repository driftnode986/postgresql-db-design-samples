-- 変更の手数を 4 点で記録する: 文の数、テーブルの書き換えの有無、取るロック、所要時間。
-- 書き換えの有無は、テーブルのファイル番号（pg_relation_filenode）が変わったかで分かる。
-- 全体を 1 つのトランザクションで行い、最後に ROLLBACK する。列を足して消すだけでも
-- テーブルに跡が残り、ほかの測定のサイズが変わるため。
\timing on
SELECT pg_relation_filenode('ch01.order_items') AS filenode_before \gset
BEGIN;

-- 変更1: 固定の既定値を持つ列を足す
ALTER TABLE ch01.order_items ADD COLUMN gift boolean NOT NULL DEFAULT false;
SELECT mode FROM pg_locks
WHERE relation = 'ch01.order_items'::regclass AND pid = pg_backend_pid();
SELECT pg_relation_filenode('ch01.order_items') = :filenode_before AS not_rewritten;

-- 変更2: 行ごとに値が変わる既定値を持つ列を足す
ALTER TABLE ch01.order_items ADD COLUMN public_id uuid NOT NULL DEFAULT uuidv7();
SELECT pg_relation_filenode('ch01.order_items') = :filenode_before AS not_rewritten;

ROLLBACK;
