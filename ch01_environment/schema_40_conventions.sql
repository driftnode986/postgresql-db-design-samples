-- 連番の 2 つの書き方を並べる。t_ser は古い書き方（serial）、t_idn は本書の規約（IDENTITY）
CREATE TABLE ch01.t_ser (id serial PRIMARY KEY, v text);
CREATE TABLE ch01.t_idn (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, v text);

-- 権限を何も持たない book_guest に、スキーマの利用と INSERT だけを許可する
GRANT USAGE ON SCHEMA ch01 TO book_guest;
GRANT INSERT ON ch01.t_ser, ch01.t_idn TO book_guest;
