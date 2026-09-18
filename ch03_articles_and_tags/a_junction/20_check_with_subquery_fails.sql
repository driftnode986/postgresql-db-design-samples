-- run-as: book_owner
-- expect-error: 0A000
-- 案A では「1 記事のタグは 5 個まで」を CHECK で書けない。
-- CHECK は自分の行だけを見るので、他の行を数える副問い合わせを書けない
CREATE TABLE ch03_a.article_tags_max5 (
  article_id  bigint   NOT NULL,
  tag_id      smallint NOT NULL,
  PRIMARY KEY (article_id, tag_id),
  CHECK ((SELECT count(*) FROM ch03_a.article_tags_max5 x
          WHERE x.article_id = article_id) <= 5)
);
