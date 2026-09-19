-- 第12章の元データ。3 案（案A・案B・案C）はここから同じ中身を写す。
--
-- 🔴 案ごとにデータを作り直すと、案の違いではなく乱数の違いを測ることになる。
--    元データを 1 回だけ作り、各案の load.sql が ORDER BY id で写す。
--
-- 元データが持つのは「階層（組織・チーム・プロジェクト）」「利用者」「文書」
-- 「誰がどこに、どの役割で所属しているか」の 4 つだけである。
-- それを都度たどるか（案A）、役割と権限の対応を表で持つか（案B）、
-- 判定結果を実体化するか（案C）は、各案が決める。
CREATE SCHEMA IF NOT EXISTS ch12_r;

DROP TABLE IF EXISTS ch12_r.src_membership;
DROP TABLE IF EXISTS ch12_r.src_document;
DROP TABLE IF EXISTS ch12_r.src_user;
DROP TABLE IF EXISTS ch12_r.src_scope;

-- 階層。組織 → チーム → プロジェクトを 1 つの表で持つ（第4章の隣接リスト）。
-- path は第4章の ltree 版のためにも持たせる。案A は両方の書き方を比べる。
CREATE TABLE ch12_r.src_scope (
  id        bigint PRIMARY KEY,
  parent_id bigint REFERENCES ch12_r.src_scope(id),
  kind      text   NOT NULL,          -- org / team / project
  name      text   NOT NULL,
  path      public.ltree NOT NULL
);

CREATE TABLE ch12_r.src_user (
  id    bigint PRIMARY KEY,
  login text   NOT NULL
);

-- 文書はプロジェクトに属する。一覧は created_at の新しい順に 20 件。
CREATE TABLE ch12_r.src_document (
  id         bigint      PRIMARY KEY,
  project_id bigint      NOT NULL REFERENCES ch12_r.src_scope(id),
  title      text        NOT NULL,
  created_at timestamptz NOT NULL
);

-- 所属。role は viewer / editor / admin の 3 つ。
--
-- 🔴 同じ人が、プロジェクトA では編集者・プロジェクトB では閲覧者になれる形にする
--    （要件そのもの）。役割を users の列 1 つで持つ設計ではこれが表せない。
CREATE TABLE ch12_r.src_membership (
  id       bigint PRIMARY KEY,
  user_id  bigint NOT NULL REFERENCES ch12_r.src_user(id),
  scope_id bigint NOT NULL REFERENCES ch12_r.src_scope(id),
  role     text   NOT NULL
);
