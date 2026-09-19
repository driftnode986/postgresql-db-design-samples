-- 元データ。4 つの案は、ここから同じ中身を写して作る。
--
-- 🔴 元データを作るファイルは schema で始まる名前にする。検証の実行順が schema → load なので、
--    load という名前にすると各案の load.sql より後に走り、全案が空を写したまま全件 OK になる
--    （第2章で実際に起きた。CLAUDE.md の規約）。
--
-- 申請そのもの（src_request）、状態の遷移（src_transition）、内容の版（src_revision）の 3 つを持つ。
-- どの案も、この 3 つを自分の形に並べ替えるだけで、入っている事実は同じにする。

CREATE SCHEMA IF NOT EXISTS ch09_r;

DROP TABLE IF EXISTS ch09_r.src_revision;
DROP TABLE IF EXISTS ch09_r.src_transition;
DROP TABLE IF EXISTS ch09_r.src_request;
DROP TABLE IF EXISTS ch09_r.src_employee;
DROP TABLE IF EXISTS ch09_r.src_category;

-- 申請者と承認者。1,000 人
CREATE TABLE ch09_r.src_employee (
  id       bigint PRIMARY KEY,
  name     text   NOT NULL,
  dept     text   NOT NULL
);

-- 経費の科目
CREATE TABLE ch09_r.src_category (
  id    int  PRIMARY KEY,
  code  text NOT NULL UNIQUE,
  name  text NOT NULL
);

-- 申請。状態は持たない（状態の持ち方は案ごとに違うため、元データには入れない）
CREATE TABLE ch09_r.src_request (
  id            bigint      PRIMARY KEY,
  applicant_id  bigint      NOT NULL REFERENCES ch09_r.src_employee(id),
  created_at    timestamptz NOT NULL
);

-- 状態の遷移。1 件の申請につき平均 5 回。
-- 「いつ・誰が・なぜ」を持つのはこの表であり、どの案でもここは変わらない。
CREATE TABLE ch09_r.src_transition (
  request_id  bigint      NOT NULL REFERENCES ch09_r.src_request(id),
  seq         int         NOT NULL,
  from_status text,                       -- 最初の行は NULL
  to_status   text        NOT NULL,
  changed_by  bigint      NOT NULL REFERENCES ch09_r.src_employee(id),
  changed_at  timestamptz NOT NULL,
  note        text,                       -- 差戻しの理由など
  PRIMARY KEY (request_id, seq)
);

-- 内容の版。1 件の申請につき平均 2 回の修正（＝版は平均 3 つ）。
-- 終わりの時刻は持たない。期間の持ち方は案ごとに違うので、元データは「この時刻からこの内容」だけを持つ。
CREATE TABLE ch09_r.src_revision (
  request_id   bigint      NOT NULL REFERENCES ch09_r.src_request(id),
  rev          int         NOT NULL,
  amount_yen   int         NOT NULL,
  category_id  int         NOT NULL REFERENCES ch09_r.src_category(id),
  reason       text        NOT NULL,
  edited_by    bigint      NOT NULL REFERENCES ch09_r.src_employee(id),
  valid_from   timestamptz NOT NULL,
  PRIMARY KEY (request_id, rev)
);
