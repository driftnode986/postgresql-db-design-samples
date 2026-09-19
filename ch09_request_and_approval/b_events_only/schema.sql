-- 案B: 状態の列を持たず、遷移の追記だけで状態を表す。
--
-- 採取した案のうち haiku がこの形だった。現在の状態は「最新の遷移の to_status」である。
-- 状態の列と履歴が食い違う経路が原理的に無い代わりに、一覧を出すたびに最新行を探す。

CREATE SCHEMA IF NOT EXISTS ch09_b;

CREATE TABLE ch09_b.statuses (
  code    text PRIMARY KEY,
  label   text NOT NULL,
  is_open boolean NOT NULL
);

INSERT INTO ch09_b.statuses (code, label, is_open) VALUES
  ('draft',     '下書き',   true),
  ('submitted', '申請中',   true),
  ('approved',  '承認',     true),
  ('rejected',  '差戻し',   true),
  ('paid',      '支払済み', false);

CREATE TABLE ch09_b.employees (
  id   bigint PRIMARY KEY,
  name text   NOT NULL,
  dept text   NOT NULL
);

CREATE TABLE ch09_b.categories (
  id   int  PRIMARY KEY,
  code text NOT NULL UNIQUE,
  name text NOT NULL
);

-- 申請の本体。状態の列を持たない。
CREATE TABLE ch09_b.requests (
  id            bigint      PRIMARY KEY,
  applicant_id  bigint      NOT NULL REFERENCES ch09_b.employees(id),
  created_at    timestamptz NOT NULL
);

CREATE TABLE ch09_b.transitions (
  request_id  bigint      NOT NULL REFERENCES ch09_b.requests(id),
  seq         int         NOT NULL,
  from_status text        REFERENCES ch09_b.statuses(code),
  to_status   text        NOT NULL REFERENCES ch09_b.statuses(code),
  changed_by  bigint      NOT NULL REFERENCES ch09_b.employees(id),
  changed_at  timestamptz NOT NULL,
  note        text,
  -- 最新の遷移に付ける印。既定は false で、追記のたびに前の行を false にする。
  -- 🔴 この列を持つと、案B は「追記のみ」ではなくなる（前の行を更新するため）。
  --    代償がここにあることを実測で示すので、列自体は持たせておく。
  is_current  boolean     NOT NULL DEFAULT false,
  PRIMARY KEY (request_id, seq)
);

CREATE INDEX idx_b_transitions ON ch09_b.transitions (request_id, seq DESC);

-- 状態で絞るためのインデックス。最新行かどうかはこのインデックスだけでは判定できない
-- （最新でない行も to_status = 'submitted' を持つため）。
CREATE INDEX idx_b_to_status ON ch09_b.transitions (to_status, changed_at DESC);

-- 印を使う場合の一覧用の部分インデックス。案A の idx_a_submitted と同じ役割
CREATE INDEX idx_b_current_submitted ON ch09_b.transitions (changed_at DESC)
  WHERE is_current AND to_status = 'submitted';

-- 最新の印は 1 件の申請に 1 つだけ
CREATE UNIQUE INDEX idx_b_one_current ON ch09_b.transitions (request_id)
  WHERE is_current;
