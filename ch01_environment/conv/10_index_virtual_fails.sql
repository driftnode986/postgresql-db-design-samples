-- run-as: book_owner
-- expect-error: indexes on virtual generated columns are not supported
CREATE INDEX ON ch01.t_gen (amount_default);
