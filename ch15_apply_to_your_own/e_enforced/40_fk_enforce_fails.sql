-- run-as: book_owner
-- expect-error: 23503
-- 外部キーは ENFORCED に戻せる。そのとき既存の全行を検査するので、違反が残っていれば失敗する
ALTER TABLE ch15_e.events_ne
  ALTER CONSTRAINT events_ne_account_fk ENFORCED;
