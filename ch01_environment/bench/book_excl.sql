\set room random_zipfian(1, 5000, 1.1)
\set slot random(0, 719)
SELECT book_excl(:room,
  tstzrange('2026-10-01 00:00+09'::timestamptz + :slot * interval '1 hour',
            '2026-10-01 00:00+09'::timestamptz + (:slot + 1) * interval '1 hour'));
