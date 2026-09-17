-- run-as: book_guest
-- expect-error: permission denied for sequence
-- INSERT の権限だけでは足りない。serial の裏にあるシーケンスの権限が別に要る
INSERT INTO t_ser (v) VALUES ('guest');
