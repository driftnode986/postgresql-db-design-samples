-- run-as: book_owner
-- standalone
--
-- 変更シナリオ「個人情報の列を 1 つ足す（生年月日）」。
-- 消す対象の一覧を直す箇所が、3 案で何か所になるかを比べる。
--
-- 🔴 「何か所」は数え上げではなく、各案のカタログから実測する。
--    個人情報の列（氏名・メール・住所・電話・生年月日に当たる名前）を持つ
--    テーブルの数が、退会処理で触る必要のある場所の数である。
--
-- 🔴 BEGIN ... ROLLBACK で囲む。列を足して消すのを確定させると、
--    消した列の定義がテーブルに残ってサイズが変わる（第1章の教訓）。

-- 変更の前に、各案で個人情報を持つテーブルを数える
SELECT n.nspname AS plan_schema,
       count(DISTINCT c.relname) AS tables_holding_pii,
       string_agg(DISTINCT c.relname, ', ' ORDER BY c.relname) AS tables
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum > 0 AND NOT a.attisdropped
WHERE n.nspname IN ('ch14_a','ch14_b','ch14_c')
  AND c.relkind = 'r'
  AND a.attname IN ('email','full_name','postal','address','phone',
                    'recipient','ship_addr','ship_phone')
GROUP BY n.nspname
ORDER BY n.nspname;

-- 案A: users に足す。個人情報を持つ表は users と orders の 2 つなので、
--      退会処理（つぶす UPDATE）は 2 つの表に対して書かれている。
BEGIN;
\timing on
ALTER TABLE ch14_a.users ADD COLUMN birthday date;
\timing off
ROLLBACK;

-- 案B: users と控えの両方に足す。控えを忘れると復元で欠ける。
BEGIN;
\timing on
ALTER TABLE ch14_b.users ADD COLUMN birthday date;
ALTER TABLE ch14_b.withdrawn_users ADD COLUMN birthday date;
\timing off
ROLLBACK;

-- 案C: profiles だけに足す。消す対象は profiles の「行」なので、
--      列が増えても退会処理の SQL は変わらない。
BEGIN;
\timing on
ALTER TABLE ch14_c.profiles ADD COLUMN birthday date;
\timing off
ROLLBACK;
