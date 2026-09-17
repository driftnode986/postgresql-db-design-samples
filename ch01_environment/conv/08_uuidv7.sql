-- UUIDv7 の値からは、作られた時刻が読める。UUIDv4 からは読めない
SELECT uuid_extract_version(u) AS version,
       uuid_extract_timestamp(u) AS created_at
FROM (SELECT uuidv7() AS u) AS s;
SELECT uuid_extract_timestamp(uuidv4()) AS created_at;
