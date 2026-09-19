-- run-as: book_owner
--
-- 変更シナリオ: あとからパーティションを入れる。
--
-- 出発点は、単独の主キー `(id)` を持つ通知の表と、それを参照する表である。
-- ここで起きることを、すべて 1 つのシナリオの中で実測する。
--
-- 🔴 本文の「あとで変えるのが大変な点」は、この出力を引用する。
--    記憶から書いたエラー文を本文に貼らない（第9章で制約名が実際と違う捏造を 2 件書いた）。

\set ON_ERROR_STOP off
\timing on
SET search_path TO ch10_a, public;

DROP TABLE IF EXISTS ch10_a.mig_note;
DROP TABLE IF EXISTS ch10_a.mig_new CASCADE;
DROP TABLE IF EXISTS ch10_a.mig_src;

\echo '=== 出発点: 単独の主キーを持つ通知の表と、それを参照する表 ==='
CREATE TABLE ch10_a.mig_src (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id    bigint      NOT NULL,
  kind       text        NOT NULL,
  body       text        NOT NULL,
  read_at    timestamptz,
  created_at timestamptz NOT NULL
);

INSERT INTO ch10_a.mig_src (user_id, kind, body, read_at, created_at)
SELECT user_id, kind, body, read_at, created_at
  FROM ch10_a.notifications ORDER BY id;

-- 通知を参照する表（「この通知にメモを付けた」のような関連）
CREATE TABLE ch10_a.mig_note (
  id       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  notif_id bigint NOT NULL REFERENCES ch10_a.mig_src(id),
  memo     text   NOT NULL
);
INSERT INTO ch10_a.mig_note (notif_id, memo)
SELECT id, 'メモ' FROM ch10_a.mig_src ORDER BY id LIMIT 1000;

ANALYZE ch10_a.mig_src;
ANALYZE ch10_a.mig_note;

\echo '=== (1) パーティション表の主キーには、パーティションキーの列が要る ==='
-- 🔴 エラーになるのが正しい（expect-error: 0A000）
CREATE TABLE ch10_a.mig_bad (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  created_at timestamptz NOT NULL
) PARTITION BY RANGE (created_at);

\echo '=== (2) 既存の表をパーティション表に変換する構文は無い ==='
-- 🔴 エラーになるのが正しい（expect-error: 42601）
ALTER TABLE ch10_a.mig_src PARTITION BY RANGE (created_at);

\echo '=== (3) 主キーを張り替えるには CASCADE が要り、参照側の外部キーが消える ==='
-- 🔴 NOTICE は出るが、エラーにはならない。消えたことに気づかない
SELECT count(*) AS fk_before FROM pg_constraint
 WHERE conrelid = 'ch10_a.mig_note'::regclass AND contype = 'f';

ALTER TABLE ch10_a.mig_src DROP CONSTRAINT mig_src_pkey CASCADE;

SELECT count(*) AS fk_after FROM pg_constraint
 WHERE conrelid = 'ch10_a.mig_note'::regclass AND contype = 'f';

\echo '=== (4) 新しいパーティション表を作ってデータを入れ替える ==='
CREATE TABLE ch10_a.mig_new (
  id         bigint GENERATED ALWAYS AS IDENTITY,
  user_id    bigint      NOT NULL,
  kind       text        NOT NULL,
  body       text        NOT NULL,
  read_at    timestamptz,
  created_at timestamptz NOT NULL,
  PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

DO $$
DECLARE m date := date_trunc('month', now())::date - interval '6 months';
BEGIN
  WHILE m <= date_trunc('month', now())::date LOOP
    EXECUTE format(
      'CREATE TABLE ch10_a.mig_new_%s PARTITION OF ch10_a.mig_new '
      'FOR VALUES FROM (%L) TO (%L)',
      to_char(m, 'YYYY_MM'), m, m + interval '1 month');
    m := m + interval '1 month';
  END LOOP;
END $$;

-- 🔴 IDENTITY の列に既存の id を入れるには OVERRIDING SYSTEM VALUE が要る
INSERT INTO ch10_a.mig_new (id, user_id, kind, body, read_at, created_at)
OVERRIDING SYSTEM VALUE
SELECT id, user_id, kind, body, read_at, created_at
  FROM ch10_a.mig_src ORDER BY id;

\echo '=== (5) 🔴 移行のあと、採番が止まったままになる ==='
-- 構文も制約も正しいので、データを入れるまで誰も気づかない
SELECT (SELECT last_value FROM ch10_a.mig_new_id_seq) AS seq_after_migration,
       (SELECT max(id) FROM ch10_a.mig_new)           AS max_id;

\echo '--- 🔴 直さずに入れても、すぐにはエラーにならない（ここが厄介） ---'
-- 主キーは (id, created_at) なので、既存の id=1 が別のパーティション（過去の月）に
-- あるかぎり、今月のパーティションに id=1 を入れても衝突しない。
-- **重複した id が、別の月に静かに作られる。**
INSERT INTO ch10_a.mig_new (user_id, kind, body, created_at)
VALUES (1, 'order_shipped', '移行後の最初の通知', now())
RETURNING id;

\echo '--- その結果、同じ id が 2 件できている ---'
SELECT id, count(*) AS rows_with_same_id
  FROM ch10_a.mig_new GROUP BY id HAVING count(*) > 1 ORDER BY id LIMIT 5;

\echo '--- 通知の id で 1 件引いたつもりが 2 件返る ---'
SELECT count(*) AS rows_for_id_1 FROM ch10_a.mig_new WHERE id = 1;

\echo '--- シーケンスを実データに合わせる ---'
SELECT setval(pg_get_serial_sequence('ch10_a.mig_new','id'),
              (SELECT max(id) FROM ch10_a.mig_new));

\echo '--- 合わせたあとは、続きの番号が振られる ---'
INSERT INTO ch10_a.mig_new (user_id, kind, body, created_at)
VALUES (1, 'order_shipped', '移行後の 2 件目の通知', now())
RETURNING id;

\echo '=== 後片付け ==='
DROP TABLE ch10_a.mig_note;
DROP TABLE ch10_a.mig_new CASCADE;
DROP TABLE ch10_a.mig_src;
