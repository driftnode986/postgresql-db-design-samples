-- 案B: 先祖と子孫の全組み合わせを別の表に持つ（閉包テーブル）
CREATE SCHEMA ch04_b;

CREATE TABLE ch04_b.nodes (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  parent_id  bigint REFERENCES ch04_b.nodes(id),
  body       text NOT NULL,
  pos        int  NOT NULL DEFAULT 0,
  CONSTRAINT nodes_no_self_parent CHECK (parent_id <> id)
);

-- 先祖から子孫へのすべての対（自分自身 depth = 0 を含む）
CREATE TABLE ch04_b.paths (
  ancestor_id    bigint NOT NULL REFERENCES ch04_b.nodes(id) ON DELETE CASCADE,
  descendant_id  bigint NOT NULL REFERENCES ch04_b.nodes(id) ON DELETE CASCADE,
  depth          int    NOT NULL,
  PRIMARY KEY (ancestor_id, descendant_id)
);
