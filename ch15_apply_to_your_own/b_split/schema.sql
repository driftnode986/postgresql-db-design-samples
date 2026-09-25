-- 衝突1の解き方: 個人情報を別のテーブルに置き（第14章の案C）、履歴には写さない。
CREATE SCHEMA ch15_b;

CREATE TABLE ch15_b.requests (
  id     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  status text NOT NULL
);

-- 消してよい列だけを持つテーブル。退会したら行ごと消す
CREATE TABLE ch15_b.request_pii (
  request_id     bigint PRIMARY KEY REFERENCES ch15_b.requests (id),
  applicant_name text NOT NULL,
  reason         text NOT NULL
);

-- 履歴には、消さなくてよい列だけを写す
CREATE TABLE ch15_b.request_history (
  history_id  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  request_id  bigint NOT NULL,
  status      text NOT NULL,
  recorded_at timestamptz NOT NULL DEFAULT now()
);

CREATE FUNCTION ch15_b.forbid_change() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'request_history is append-only';
END;
$$;

CREATE TRIGGER request_history_append_only
  BEFORE UPDATE OR DELETE ON ch15_b.request_history
  FOR EACH ROW EXECUTE FUNCTION ch15_b.forbid_change();
