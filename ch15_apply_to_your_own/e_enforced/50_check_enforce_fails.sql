-- run-as: book_owner
-- expect-error: cannot alter enforceability of constraint
-- CHECK 制約は、違反の有無にかかわらず ENFORCED に戻せない（作り直すしかない）
DELETE FROM ch15_e.events_ne WHERE amount <= 0;
ALTER TABLE ch15_e.events_ne
  ALTER CONSTRAINT events_ne_amount_ck ENFORCED;
