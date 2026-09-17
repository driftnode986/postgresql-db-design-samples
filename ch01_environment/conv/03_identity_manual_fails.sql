-- expect-error: 428C9
-- GENERATED ALWAYS の列は、値を手で指定した時点で拒否される
INSERT INTO t_idn (id, v) VALUES (1, 'manual');
