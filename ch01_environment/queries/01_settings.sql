-- 測定値と一緒に残す設定値
SELECT version();
SELECT name, setting, unit
FROM pg_settings
WHERE name IN ('shared_buffers', 'work_mem', 'io_method', 'io_workers', 'jit',
               'max_parallel_workers_per_gather', 'data_checksums')
ORDER BY name;
