-- 第13章の元データを作る。SIZE=S / M で行数を変える。
--
-- 偏りを 2 か所に入れている。実サービスのマルチテナントは必ず偏るので、
-- 均等に配ると案の差が出ない。
--   (1) テナントの大きさ: 1 社（tenant 1）だけが全体の約 4 割を占める
--   (2) 残りのテナント: 小さい会社が多数
--
-- 🔴 決定的に作る（setseed）。乱数が実行ごとに変わると、案の比較が乱数の比較になる。
-- 🔴 日付は now() から「引く」。足すとタイムゾーン変換で未来の行ができる（第11章で実際に踏んだ）。
-- XS は検査を速く回すためだけの量。偏りの作り方は S・M と同じなので、
-- 「1 社だけが大きい」という構造はそのまま再現する。
-- 🔴 本文に載せる測定値は S。XS の値を本文に書かない。
SELECT CASE :'size' WHEN 'XS' THEN 20000  WHEN 'S' THEN 400000  WHEN 'M' THEN 4000000
       ELSE 1/0 END AS big_rows \gset
SELECT CASE :'size' WHEN 'XS' THEN 29970  WHEN 'S' THEN 599400  WHEN 'M' THEN 5994000
       ELSE 1/0 END AS small_rows \gset
SELECT CASE :'size' WHEN 'XS' THEN 100    WHEN 'S' THEN 1000    WHEN 'M' THEN 1000
       ELSE 1/0 END AS tenants \gset

SELECT setseed(0.42);

TRUNCATE ch13_r.src_deal, ch13_r.src_customer, ch13_r.src_tenant RESTART IDENTITY CASCADE;

-- テナント 1,000 社
INSERT INTO ch13_r.src_tenant (id, name)
SELECT g, 'tenant-' || lpad(g::text, 4, '0')
FROM generate_series(1, :tenants) g;

-- 顧客。1 社あたり 50 件（大きい会社は 5,000 件）。
-- email はテナントをまたいで衝突しうる形にする。
-- 一意制約の張り方で何が起きるかを案B で測るため。
INSERT INTO ch13_r.src_customer (tenant_id, id, email, name)
SELECT t.id,
       (t.id::bigint * 100000) + c,
       'user' || c || '@example.com',
       'customer-' || t.id || '-' || c
FROM ch13_r.src_tenant t
CROSS JOIN LATERAL generate_series(1, CASE WHEN t.id = 1 THEN 5000 ELSE 50 END) c;

-- 案件（大きい会社）
INSERT INTO ch13_r.src_deal (tenant_id, id, customer_id, title, amount, created_at)
SELECT 1,
       g,
       100000 + 1 + (g % 5000),
       'deal-' || g,
       (1000 + (g % 9000))::numeric,
       now() - ((g % 200000) * interval '1 minute')
FROM generate_series(1, :big_rows) g;

-- 案件（残りのテナント）
INSERT INTO ch13_r.src_deal (tenant_id, id, customer_id, title, amount, created_at)
SELECT t,
       :big_rows + g,
       (t::bigint * 100000) + 1 + (g % 50),
       'deal-' || (:big_rows + g),
       (1000 + (g % 9000))::numeric,
       now() - ((g % 200000) * interval '1 minute')
FROM generate_series(1, :small_rows) g,
     LATERAL (SELECT 2 + (g % (:tenants - 1)) AS t) s;

-- 🔴 生成の検査。全行の先頭列が 0 になること。
SELECT count(*) FILTER (WHERE created_at > now()) AS future_rows_must_be_zero,
       count(*)                                    AS total_rows,
       count(DISTINCT tenant_id)                   AS tenants
FROM ch13_r.src_deal;
