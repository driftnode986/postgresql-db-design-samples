-- expect-error: 23505
-- 次に値を省いて入れると、シーケンスが 1 を出して主キーが衝突する
INSERT INTO t_ser (v) VALUES ('auto');
