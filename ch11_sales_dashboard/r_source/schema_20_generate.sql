-- 注文・明細・返品を生成する。
--   SIZE=S … 明細 100 万（読者が手元で数分以内に再現できる量）
--   SIZE=M … 明細 1,000 万（案の差が読み取れる量）
--
-- 🔴 企画は M を 3 億行としていたが、S（100 万）の生成に約 9 秒かかったので
--    3 億は 45 分を超える。読者が再現できないので M は 1,000 万にした
--    （docs/research/ch11_verification.md §12-1）。
--
-- 🔴 この章で偏らせるのは「商品ごとの売れ方」である。
--    全商品が均等に売れると、案C の集計行への更新が分散してしまい、
--    この章の最重要の実測（同じ集計行への集中）が再現しない
--    （ch11_verification.md §7。集中させると tps が 1/5.3 に落ちる）。
--
-- 🔴 WITH ... AS MATERIALIZED を付ける。付けないと random() が外側で再評価され、
--    決めた商品と金額が食い違う（第7章・第10章で踏んだ）。
--
-- 🔴 配列の添字には floor() を使う。::int は四捨五入なので範囲外になる。
--
-- setseed で乱数の種を固定するので、何度実行しても同じ値になる。
SELECT CASE :'size' WHEN 'S' THEN 1000000 WHEN 'M' THEN 10000000
       ELSE 1/0 END AS n_line \gset
SELECT CASE :'size' WHEN 'S' THEN 1000 WHEN 'M' THEN 5000
       ELSE 1/0 END AS n_product \gset

\timing on

SELECT setseed(0.42);

-- 🔴 入れ直しても同じ結果になるようにする（2 回実行して行が倍にならない）
TRUNCATE ch11_r.src_return;
TRUNCATE ch11_r.src_order_line CASCADE;
TRUNCATE ch11_r.src_order CASCADE;
TRUNCATE ch11_r.src_product CASCADE;

\echo '生成する明細数:' :n_line
\echo '生成する商品数:' :n_product

-- 商品。カテゴリは 20 個に散らす
INSERT INTO ch11_r.src_product (id, name, category_id)
SELECT g, '商品' || g, 1 + (g % 20)
FROM generate_series(1, :n_product) AS g;

-- 注文。明細 1 件につき 1 注文にせず、1 注文あたり平均 2.5 明細にする。
-- 直近 365 日に散らす。
-- 🔴 時刻を「足す」と、今日のぶんが翌日にはみ出す。
--    日付の 0 時から 86,400 秒を足すと、今日の 0 時 + 23:59 が
--    タイムゾーンの変換で翌日の日付になる行ができる（実際に 996 行できた）。
--    売上のデータに未来の日付は無いので、**今から過去へ向かって引く**。
--    はみ出した行は案D の「確定日」にも「当日」にも入らず、検査が 516 件の差を出した。
INSERT INTO ch11_r.src_order (id, ordered_at)
SELECT g,
       -- 当日（今日）にも一定数を置く。案D は「当日ぶんだけ都度集計」なので、
       -- 当日の行数が案D の速さを決める
       now() - make_interval(days => floor(random() * 365)::int)
             - make_interval(secs => floor(random() * 86400)::int)
FROM generate_series(1, (:n_line / 2.5)::bigint) AS g;

-- 明細。
--
-- 🔴 商品の売れ方を偏らせる。3 割は「人気商品」（id = 1）に集中させ、
--    残りを全商品に散らす。これが §7 の「集計行への集中」を再現する条件。
INSERT INTO ch11_r.src_order_line
       (id, order_id, product_id, category_id, qty, amount_yen, ordered_at)
WITH base AS MATERIALIZED (
  SELECT g,
         1 + floor(random() * (:n_line / 2.5))::bigint AS order_id,
         CASE WHEN random() < 0.30
              THEN 1                                            -- 人気商品に集中
              ELSE 1 + floor(random() * :n_product)::bigint     -- 全体に散らす
         END AS product_id,
         1 + floor(random() * 3)::int  AS qty,
         (100 + floor(random() * 100)::int) * 100 AS unit_yen
    FROM generate_series(1, :n_line) AS g
)
SELECT b.g, b.order_id, b.product_id, p.category_id,
       b.qty, b.qty * b.unit_yen, o.ordered_at
  FROM base b
  JOIN ch11_r.src_product p ON p.id = b.product_id
  JOIN ch11_r.src_order   o ON o.id = b.order_id
 ORDER BY b.g;

-- 返品。明細の 2% が返品される。
--
-- 🔴 返品は「あとの日」に起きるが、減るのは「元の注文日」の売上である。
--    この食い違いが、この章で集計を作り直す理由そのものになる。
INSERT INTO ch11_r.src_return
       (id, order_line_id, sales_date, returned_at, qty, refund_yen)
WITH picked AS MATERIALIZED (
  SELECT l.id, l.ordered_at, l.qty, l.amount_yen, random() AS r_lag
    FROM ch11_r.src_order_line l
   WHERE (l.id % 50) = 0                       -- 2%（決定的に選ぶ）
)
SELECT row_number() OVER (ORDER BY id),
       id,
       (ordered_at AT TIME ZONE 'Asia/Tokyo')::date,
       ordered_at + make_interval(days => 1 + floor(r_lag * 14)::int),
       qty,
       amount_yen
  FROM picked;

ANALYZE ch11_r.src_product;
ANALYZE ch11_r.src_order;
ANALYZE ch11_r.src_order_line;
ANALYZE ch11_r.src_return;

-- 生成できたものを確認する。本文はここに出る数値を引用する。
\echo '=== 元データの件数 ==='
SELECT (SELECT count(*) FROM ch11_r.src_product)    AS products,
       (SELECT count(*) FROM ch11_r.src_order)      AS orders,
       (SELECT count(*) FROM ch11_r.src_order_line) AS lines,
       (SELECT count(*) FROM ch11_r.src_return)     AS returns;

\echo '=== 売れ方の偏り（上位 3 商品の占める割合） ==='
SELECT product_id,
       count(*)                                                    AS lines,
       round(100.0 * count(*) / (SELECT count(*)
                                   FROM ch11_r.src_order_line), 1) AS pct
  FROM ch11_r.src_order_line
 GROUP BY product_id ORDER BY lines DESC LIMIT 3;

\echo '=== 集計はどれだけ畳めるか（粒度ごとの行数） ==='
-- 🔴 この章の発見（ch11_verification.md §10）。
--    集計表の効き目は「元データの行数」ではなく「粒度の組み合わせの数」で決まる。
SELECT (SELECT count(*) FROM ch11_r.src_order_line) AS src_rows,
       (SELECT count(*) FROM (SELECT DISTINCT
               (ordered_at AT TIME ZONE 'Asia/Tokyo')::date, product_id
          FROM ch11_r.src_order_line) t)            AS by_date_product,
       (SELECT count(*) FROM (SELECT DISTINCT
               (ordered_at AT TIME ZONE 'Asia/Tokyo')::date
          FROM ch11_r.src_order_line) t)            AS by_date;

\echo '=== 🔴 未来の日付が無いこと（0 でなければ案D の検査が差を出す） ==='
-- 先頭列が 0 になる形で書く（検証スクリプトが 0 でない行を FAIL にする）
SELECT count(*) AS lines_in_the_future
  FROM ch11_r.src_order_line
 WHERE (ordered_at AT TIME ZONE 'Asia/Tokyo')::date
     > (now() AT TIME ZONE 'Asia/Tokyo')::date;

\echo '=== 当日ぶんの明細数（案D の速さを決める） ==='
SELECT count(*) AS today_lines
  FROM ch11_r.src_order_line
 WHERE (ordered_at AT TIME ZONE 'Asia/Tokyo')::date
     = (now() AT TIME ZONE 'Asia/Tokyo')::date;
