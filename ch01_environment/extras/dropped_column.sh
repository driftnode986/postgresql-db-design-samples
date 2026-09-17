#!/usr/bin/env bash
# 列を足して消す操作を繰り返すと、テーブルのサイズに影響が残るかを確かめる。
# 消した列はカタログに残る。列の数（消した列を含む）が 8 を超えると、行ごとの管理情報が大きくなる。
#   bash ch01_environment/extras/dropped_column.sh > ch01_environment/results/dropped_column.txt
# 確認用のテーブル ch01.items_trace を作り、終わったら消す。
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
F="$(mktemp)"; trap 'rm -f "$F"' EXIT
cat > "$F" <<'SQL'
CREATE TABLE ch01.items_trace (LIKE ch01.order_items INCLUDING ALL);
INSERT INTO ch01.items_trace (product_id, qty, ordered_at)
SELECT product_id, qty, ordered_at FROM ch01.order_items ORDER BY id;
SELECT pg_size_pretty(pg_relation_size('ch01.items_trace')) AS heap_before;

-- 列を 2 つ足して、すぐに消す（確定させる）。これを 3 回繰り返す
ALTER TABLE ch01.items_trace ADD COLUMN gift boolean NOT NULL DEFAULT false;
ALTER TABLE ch01.items_trace ADD COLUMN public_id uuid NOT NULL DEFAULT uuidv7();
ALTER TABLE ch01.items_trace DROP COLUMN gift, DROP COLUMN public_id;
ALTER TABLE ch01.items_trace ADD COLUMN gift boolean NOT NULL DEFAULT false;
ALTER TABLE ch01.items_trace ADD COLUMN public_id uuid NOT NULL DEFAULT uuidv7();
ALTER TABLE ch01.items_trace DROP COLUMN gift, DROP COLUMN public_id;
ALTER TABLE ch01.items_trace ADD COLUMN gift boolean NOT NULL DEFAULT false;
ALTER TABLE ch01.items_trace ADD COLUMN public_id uuid NOT NULL DEFAULT uuidv7();
ALTER TABLE ch01.items_trace DROP COLUMN gift, DROP COLUMN public_id;

-- 同じデータを入れ直す
TRUNCATE ch01.items_trace;
INSERT INTO ch01.items_trace (product_id, qty, ordered_at)
SELECT product_id, qty, ordered_at FROM ch01.order_items ORDER BY id;
SELECT pg_size_pretty(pg_relation_size('ch01.items_trace')) AS heap_after;

-- 消した列は、カタログに残っている
SELECT attnum, attname, attisdropped FROM pg_attribute
WHERE attrelid = 'ch01.items_trace'::regclass AND attnum > 0 ORDER BY attnum;
DROP TABLE ch01.items_trace;
SQL
bash scripts/collect-env.sh
bash scripts/run-sql.sh book_owner ch01 "$F"
