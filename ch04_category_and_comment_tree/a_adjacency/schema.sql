-- 案A: 親を指す列だけを持つ（隣接リスト）
CREATE SCHEMA ch04_a;

CREATE TABLE ch04_a.nodes (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  parent_id  bigint REFERENCES ch04_a.nodes(id),
  body       text NOT NULL,
  pos        int  NOT NULL DEFAULT 0,
  -- 自分自身を親にすることだけは制約で防げる。2 ノード以上の輪は防げない
  -- （他の行を見る必要があり、CHECK に副問い合わせを書けない）
  CONSTRAINT nodes_no_self_parent CHECK (parent_id <> id)
);
