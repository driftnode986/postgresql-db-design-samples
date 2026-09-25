TRUNCATE ch15_f.invoices RESTART IDENTITY;

INSERT INTO ch15_f.invoices (note) VALUES ('1 件目');

-- 2 件目は、途中で取り消した
BEGIN;
INSERT INTO ch15_f.invoices (note) VALUES ('取り消した 2 件目');
ROLLBACK;

INSERT INTO ch15_f.invoices (note) VALUES ('3 件目');
