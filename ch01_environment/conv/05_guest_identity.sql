-- run-as: book_guest
-- IDENTITY の列は、INSERT の権限だけで入れられる
INSERT INTO t_idn (v) VALUES ('guest');
