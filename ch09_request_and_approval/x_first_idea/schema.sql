-- 採取した案の検算に使う表。
--
-- 採取した 3 本のうち opus と sonnet は、内容の版を「開始と終わりの 2 列」で持ち、
-- opus は CHECK (valid_to IS NULL OR valid_from < valid_to) を付けていた。
-- この CHECK が何を守り、何を守らないかを確かめる。

CREATE SCHEMA IF NOT EXISTS ch09_x;

DROP TABLE IF EXISTS ch09_x.revisions;

CREATE TABLE ch09_x.revisions (
  request_id int         NOT NULL,
  rev        int         NOT NULL,
  amount_yen int         NOT NULL,
  valid_from timestamptz NOT NULL,
  valid_to   timestamptz,                    -- 最新の版は NULL
  PRIMARY KEY (request_id, rev),
  -- 採取した案が付けていた CHECK。1 行の中の前後関係だけを見る
  CHECK (valid_to IS NULL OR valid_from < valid_to)
);

-- 最新の版は 1 件の申請に 1 つだけ（これは検査される）
CREATE UNIQUE INDEX idx_x_current ON ch09_x.revisions (request_id) WHERE valid_to IS NULL;
