-- expect-error: 22P02
SELECT JSON_VALUE('{"watt": "1200W"}'::jsonb, '$.watt' RETURNING int ERROR ON ERROR);
