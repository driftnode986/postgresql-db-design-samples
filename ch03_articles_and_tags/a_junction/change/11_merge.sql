-- 変更シナリオ 2: タグを統合する（tag002 を tag001 にまとめる）。
-- 案A も、中間テーブルの該当行すべてに触る
\timing on
BEGIN;
-- 統合先をすでに持つ記事は、重複するので先に消す
DELETE FROM ch03_a.article_tags d
WHERE d.tag_id = (SELECT id FROM ch03_a.tags WHERE name = 'tag002')
  AND EXISTS (SELECT 1 FROM ch03_a.article_tags k
              WHERE k.article_id = d.article_id
                AND k.tag_id = (SELECT id FROM ch03_a.tags
                                WHERE name = 'tag001'));
UPDATE ch03_a.article_tags
   SET tag_id = (SELECT id FROM ch03_a.tags WHERE name = 'tag001')
 WHERE tag_id = (SELECT id FROM ch03_a.tags WHERE name = 'tag002');
DELETE FROM ch03_a.tags WHERE name = 'tag002';
ROLLBACK;
