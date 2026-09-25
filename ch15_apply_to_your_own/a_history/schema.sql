-- 衝突1: 第9章の「追記のみの履歴」と、第14章の「退会したら個人情報を消す」を 1 つのサービスに並べる。
-- 履歴には、申請の行を全列そのまま写す（第9章の型）。
CREATE SCHEMA ch15_a;

CREATE TABLE ch15_a.requests (
  id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  applicant_name text,
  reason         text,
  status         text NOT NULL
);

CREATE TABLE ch15_a.request_history (
  history_id     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  request_id     bigint NOT NULL,
  applicant_name text,
  reason         text,
  status         text NOT NULL,
  recorded_at    timestamptz NOT NULL DEFAULT now()
);

-- 履歴の行を書き換えさせない（追記のみの約束）
CREATE FUNCTION ch15_a.forbid_change() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'request_history is append-only';
END;
$$;

CREATE TRIGGER request_history_append_only
  BEFORE UPDATE OR DELETE ON ch15_a.request_history
  FOR EACH ROW EXECUTE FUNCTION ch15_a.forbid_change();
