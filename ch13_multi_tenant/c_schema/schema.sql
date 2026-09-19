-- 案C: 会社ごとにスキーマを分ける。
--
-- スキーマは ch13_c_t0001 のように、テナント番号で名前を作る。
-- 表の形は全社で同じだが、実体は別の表である。
--
-- 🔴 スキーマの数だけ CREATE SCHEMA と CREATE TABLE を実行する。
--    これを 1 つのトランザクションで行うと、テナント数が多いときに
--    ロックの上限に当たる（10_create_many.sql で確かめる）。
--
-- ここでは 1,000 テナントぶんを作る。案A・案B と同じ中身を写すのは load.sql。
CREATE SCHEMA ch13_c;

-- 作ったスキーマを記録しておく表。案C の運用では、
-- 「どのテナントがどのスキーマか」を持つ表が必ず要る。
CREATE TABLE ch13_c.tenants (
  id          int  PRIMARY KEY,
  name        text NOT NULL,
  status      text NOT NULL DEFAULT 'active'
              CHECK (status IN ('active', 'terminated')),
  schema_name text NOT NULL UNIQUE
);
