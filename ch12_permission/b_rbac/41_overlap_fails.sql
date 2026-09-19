-- run-as: book_owner
-- expect-error: 23P01
-- 同じ利用者・同じ対象で、期間が**重なる**招待を入れる。
--
-- 既に 2026-01-01〜2026-02-01 の招待があるので、2026-01-15〜2026-02-15 は重なる。
--
-- 🔴 返るのは主キー違反（23505 unique_violation）**ではなく排他制約違反**である。
--    実機で確かめた SQLSTATE は **23P01 exclusion_violation**（2026-09-19、18.6）。
--    WITHOUT OVERLAPS を付けた主キーは、内部では GiST の排他制約なので、
--    エラーの文面と SQLSTATE が普通の主キー違反と違う。
--    アプリ側で「23505 を捕まえて『すでに登録済み』と出す」実装では取りこぼす。
--
-- 🔴 別ファイルに分けている理由: psql は最初のエラーで止まるので、
--    42_collation_fails.sql と同じファイルに書くと後者が実行されない（確認記録 §4）。
INSERT INTO ch12_b.grants_t (user_id, scope_id, role_id, valid)
SELECT 7, 25, r.id, tstzrange('2026-01-15', '2026-02-15')
  FROM ch12_b.roles r WHERE r.code = 'viewer';
