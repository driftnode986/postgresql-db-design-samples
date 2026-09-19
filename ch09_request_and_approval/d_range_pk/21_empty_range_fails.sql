-- run-as: book_owner
-- expect-error: empty WITHOUT OVERLAPS value found
--
-- 案C から案D へ移すとき、本体と履歴に同じ版が二重にあると何が起きるかを示す。
-- 二重にあると次の版の開始時刻が自分と同じになり、空の範囲ができる。
--
-- 実際に踏んだ（40_returning_old.sql の後片付けが rev の番号で消していたため、
-- 元から履歴にあった版が残って二重になった）。

CREATE SCHEMA IF NOT EXISTS ch09_d;

DROP TABLE IF EXISTS ch09_d.empty_range_demo;

CREATE TABLE ch09_d.empty_range_demo (
  request_id int       NOT NULL,
  valid      tstzrange NOT NULL,
  rev        int       NOT NULL,
  PRIMARY KEY (request_id, valid WITHOUT OVERLAPS)
);

-- 同じ時刻の版が 2 つある（＝本体と履歴に同じ版が入っている状態）。
-- lead で次の版の開始時刻を取ると、2 つ目は自分と同じ時刻になり、範囲が空になる。
INSERT INTO ch09_d.empty_range_demo (request_id, valid, rev)
SELECT request_id,
       tstzrange(valid_from,
                 lead(valid_from) OVER (PARTITION BY request_id ORDER BY rev),
                 '[)'),
       rev
FROM (VALUES
        (1, 1, timestamptz '2026-01-01 00:00+09'),
        (1, 2, timestamptz '2026-01-10 00:00+09'),
        (1, 3, timestamptz '2026-01-10 00:00+09')   -- 版 2 と同じ時刻（二重に入っている）
     ) AS v(request_id, rev, valid_from);
