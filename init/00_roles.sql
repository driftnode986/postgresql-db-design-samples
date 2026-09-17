-- 00_roles.sql: ロールを4つに分ける
--
--   book_admin  初期化だけに使うスーパーユーザー（compose の POSTGRES_USER）。測定には使わない
--   book_owner  スキーマとテーブルの所有者。スーパーユーザーではない
--   book_app    測定を実行する。book_owner が作ったものを読み書きできる。BYPASSRLS なし
--   book_guest  何の権限も持たない。権限の章で、GRANT した分だけが効くことを確かめるために使う
--
-- スーパーユーザーは行レベルセキュリティを迂回する。テーブルの所有者も、テーブルに
-- FORCE ROW LEVEL SECURITY を付けない限り迂回する。測定を book_app で行うのはこのため。
--
-- パスワードはロール名と同じ。ローカルの学習用コンテナ専用の値で、外部に公開する
-- サーバーでは使わない（compose は 127.0.0.1 にだけポートを開く）。

CREATE ROLE book_owner LOGIN PASSWORD 'book_owner'
  NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
CREATE ROLE book_app LOGIN PASSWORD 'book_app'
  NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
CREATE ROLE book_guest LOGIN PASSWORD 'book_guest'
  NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;

-- book_owner が章ごとのスキーマを作れるようにする
GRANT CREATE ON DATABASE book TO book_owner;

-- book_owner が今後作るものを、book_app が使えるようにする。
-- book_guest には何も付けない。スキーマの USAGE も、章の SQL が明示的に GRANT した分だけになる
ALTER DEFAULT PRIVILEGES FOR ROLE book_owner
  GRANT USAGE ON SCHEMAS TO book_app;
ALTER DEFAULT PRIVILEGES FOR ROLE book_owner
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO book_app;
ALTER DEFAULT PRIVILEGES FOR ROLE book_owner
  GRANT USAGE, SELECT ON SEQUENCES TO book_app;
