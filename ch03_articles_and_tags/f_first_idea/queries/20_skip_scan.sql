-- run-as: book_owner
-- 主キー (article_id, tag_id) だけでタグから記事を引けるかを見る。
-- 先頭列 article_id の種類が 1,000 万あるので skip scan は選ばれない。
-- 逆引きインデックスを一時的に無効にし、主キーしか無い状態にして確かめる
BEGIN;
DROP INDEX ch03_f.article_tags_tag_id_idx;

-- まず既定の設定で。プランナが主キーを使わず、テーブルの逐次走査を選ぶ
EXPLAIN (ANALYZE)
SELECT count(*) FROM ch03_f.article_tags WHERE tag_id = 150;

-- 逐次走査を禁じて、主キーを使わせる。Index Searches が 1 のままなら
-- 先頭列を読み替えずにインデックス全体を走査している
SET LOCAL enable_seqscan = off;
EXPLAIN (ANALYZE)
SELECT count(*) FROM ch03_f.article_tags WHERE tag_id = 150;

ROLLBACK;
