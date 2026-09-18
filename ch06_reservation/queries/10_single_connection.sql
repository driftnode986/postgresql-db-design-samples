-- 1 接続で試すかぎり、検算の対象の案は要件どおりに動く。
--
-- ここが章の要点になる。単体テストでも、手元での確認でも、この案は合格する。
-- 差が出るのは同時に申し込んだときだけで、それは 1 接続では再現できない。
--
-- 使っていない部屋（900）の、元データに無い日（3 月）で試す。
SELECT ch06_f.reserve(900, 1,
         timestamptz '2026-03-01 10:00+09', timestamptz '2026-03-01 11:00+09') AS first_try;

-- 重なる申し込みは断られる（10:30-11:30 は 10:00-11:00 と重なる）
SELECT ch06_f.reserve(900, 2,
         timestamptz '2026-03-01 10:30+09', timestamptz '2026-03-01 11:30+09') AS overlapping_try;

-- 連続する申し込みは通る（11:00-12:00 は 10:00-11:00 と重ならない）。
-- 半開区間の要件がこの 1 行で確かめられる
SELECT ch06_f.reserve(900, 3,
         timestamptz '2026-03-01 11:00+09', timestamptz '2026-03-01 12:00+09') AS adjacent_try;

-- 後片付け（この確認で入れた行を残さない）
DELETE FROM ch06_f.reservations WHERE room_id = 900 AND start_at >= timestamptz '2026-03-01 00:00+09';
