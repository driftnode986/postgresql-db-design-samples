-- 値を型つきで取り出す。-> は jsonb、->> は text、JSON_VALUE は RETURNING で指定した型を返す
SELECT attrs->'watt'   AS as_jsonb,  pg_typeof(attrs->'watt'),
       attrs->>'watt'  AS as_text,   pg_typeof(attrs->>'watt'),
       JSON_VALUE(attrs, '$.watt' RETURNING int) AS as_int,
       pg_typeof(JSON_VALUE(attrs, '$.watt' RETURNING int))
FROM products WHERE kind = 'appliance' ORDER BY id LIMIT 1;

-- 18 では、jsonb の null を数値の型に変換すると NULL になる（17 まではエラー）
SELECT ('{"watt": null}'::jsonb->'watt')::int AS null_to_int;

-- JSON_VALUE は、変換できない値でも既定では NULL を返す。エラーにしたいときは ERROR ON ERROR
SELECT JSON_VALUE('{"watt": "1200W"}'::jsonb, '$.watt' RETURNING int)
       AS silently_null;
