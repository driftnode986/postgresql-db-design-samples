-- 本書が章にしなかった題材の出発点: 欠番のない連番（請求書番号など）
CREATE SCHEMA ch15_f;

CREATE TABLE ch15_f.invoices (
  no   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  note text NOT NULL
);
