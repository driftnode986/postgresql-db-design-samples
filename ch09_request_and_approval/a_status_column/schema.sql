-- 案A: 申請に状態の列を持ち、遷移の履歴を別の表に追記する。
--
-- 採取した案のうち opus と sonnet がこの形だった。
-- 現在の状態を 1 か所から読めるので一覧が速い。代わりに、状態の列と遷移の履歴が
-- 食い違う経路（片方だけ書く）があり、食い違いはデータベースには見えない。

CREATE SCHEMA IF NOT EXISTS ch09_a;

-- 状態の型は「状態マスタへの外部キー」にする（案の比較とは別に、第5節で 4 通りを比べる）。
CREATE TABLE ch09_a.statuses (
  code        text PRIMARY KEY,
  label       text NOT NULL,
  is_open     boolean NOT NULL          -- 一覧に出す対象かどうか
);

INSERT INTO ch09_a.statuses (code, label, is_open) VALUES
  ('draft',     '下書き',   true),
  ('submitted', '申請中',   true),
  ('approved',  '承認',     true),
  ('rejected',  '差戻し',   true),
  ('paid',      '支払済み', false);

CREATE TABLE ch09_a.employees (
  id   bigint PRIMARY KEY,
  name text   NOT NULL,
  dept text   NOT NULL
);

CREATE TABLE ch09_a.categories (
  id   int  PRIMARY KEY,
  code text NOT NULL UNIQUE,
  name text NOT NULL
);

CREATE TABLE ch09_a.requests (
  id            bigint      PRIMARY KEY,
  applicant_id  bigint      NOT NULL REFERENCES ch09_a.employees(id),
  status        text        NOT NULL REFERENCES ch09_a.statuses(code),
  created_at    timestamptz NOT NULL,
  updated_at    timestamptz NOT NULL
);

-- 遷移の履歴。「いつ・誰が・なぜ」はここが答える。追記だけで更新しない。
CREATE TABLE ch09_a.transitions (
  request_id  bigint      NOT NULL REFERENCES ch09_a.requests(id),
  seq         int         NOT NULL,
  from_status text        REFERENCES ch09_a.statuses(code),
  to_status   text        NOT NULL REFERENCES ch09_a.statuses(code),
  changed_by  bigint      NOT NULL REFERENCES ch09_a.employees(id),
  changed_at  timestamptz NOT NULL,
  note        text,
  PRIMARY KEY (request_id, seq)
);

-- 一覧「申請中を新しい順に 20 件」専用の部分インデックス。
-- 申請中は全体の約 1% なので、全体に張るより小さくなる。
CREATE INDEX idx_a_submitted ON ch09_a.requests (created_at DESC, id DESC)
  WHERE status = 'submitted';

-- 1 件の申請の履歴を引く
CREATE INDEX idx_a_transitions ON ch09_a.transitions (request_id, changed_at);
