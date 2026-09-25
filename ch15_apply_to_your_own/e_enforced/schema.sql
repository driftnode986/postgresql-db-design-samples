-- 制約の第 3 の置き方: 宣言だけして、データベースは検査しない（NOT ENFORCED、18 から）
CREATE SCHEMA ch15_e;

CREATE TABLE ch15_e.accounts (
  id bigint PRIMARY KEY
);

-- 同じ形の表を 3 つ。外部キーの置き方だけが違う
CREATE TABLE ch15_e.events_none (
  account_id bigint NOT NULL,
  amount     integer NOT NULL
);

CREATE TABLE ch15_e.events_fk (
  account_id bigint NOT NULL REFERENCES ch15_e.accounts (id),
  amount     integer NOT NULL
);

CREATE TABLE ch15_e.events_ne (
  account_id bigint NOT NULL,
  amount     integer NOT NULL,
  CONSTRAINT events_ne_account_fk FOREIGN KEY (account_id)
    REFERENCES ch15_e.accounts (id) NOT ENFORCED,
  CONSTRAINT events_ne_amount_ck CHECK (amount > 0) NOT ENFORCED
);
