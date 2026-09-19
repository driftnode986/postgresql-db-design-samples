-- 案D: 内容の版を、期間の範囲型 1 列で持ち、重なりをデータベースに検査させる。
--
-- 🔴 採取した 3 本の中に、この形は 1 本も無かった。
--    3 本とも開始と終わりの 2 列で持ち、重なりは検査していない。
--
-- PRIMARY KEY (request_id, valid WITHOUT OVERLAPS) により、
-- 同じ申請で期間が重なる行を入れようとすると主キー違反になる。
-- bigint と範囲型を組み合わせるので btree_gist が要る（init/01_extensions.sql で入れてある）。

CREATE SCHEMA IF NOT EXISTS ch09_d;

CREATE TABLE ch09_d.employees (
  id   bigint PRIMARY KEY,
  name text   NOT NULL,
  dept text   NOT NULL
);

CREATE TABLE ch09_d.categories (
  id   int  PRIMARY KEY,
  code text NOT NULL UNIQUE,
  name text NOT NULL
);

CREATE TABLE ch09_d.requests (
  id            bigint      PRIMARY KEY,
  applicant_id  bigint      NOT NULL REFERENCES ch09_d.employees(id),
  created_at    timestamptz NOT NULL
);

CREATE TABLE ch09_d.revisions (
  request_id   bigint    NOT NULL REFERENCES ch09_d.requests(id),
  valid        tstzrange NOT NULL,
  rev          int       NOT NULL,
  amount_yen   int       NOT NULL,
  category_id  int       NOT NULL REFERENCES ch09_d.categories(id),
  reason       text      NOT NULL,
  edited_by    bigint    NOT NULL REFERENCES ch09_d.employees(id),
  PRIMARY KEY (request_id, valid WITHOUT OVERLAPS)
);

-- 🔴 この 2 つのインデックスは、案C と公平に比べるために必ず張る。
--    張らないと現在値の 1 件取得が並列の全体走査になり、案の性質ではなく
--    「インデックスを張っていないだけ」の差を測ってしまう（ch09_verification.md §7-1）。
--
-- 現在の版（上限が無限の行）を引く
CREATE INDEX idx_d_current ON ch09_d.revisions (request_id) WHERE upper_inf(valid);
-- ある時点を含む版を、全申請にわたって引く
CREATE INDEX idx_d_valid_gist ON ch09_d.revisions USING gist (valid);
