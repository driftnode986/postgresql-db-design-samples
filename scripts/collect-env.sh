#!/usr/bin/env bash
# 測定結果の先頭に書く「環境の記録」を出力する。
#
#   bash scripts/collect-env.sh > ch06_reservation/results/env.txt
#
# 測定値は環境で変わる。版・主な設定値・Docker に割り当てた資源・日時を、結果と一緒に残す。
set -uo pipefail
CONTAINER="${PG_CONTAINER:-pgdbdesign}"

echo "# 採取日時: $(date '+%Y-%m-%d %H:%M:%S %z')"
echo "# ホスト: $(uname -sm)"
docker info --format '# Docker: {{.ServerVersion}} / CPU {{.NCPU}} / メモリ {{.MemTotal}} bytes' 2>/dev/null
docker exec -e PGPASSWORD=book_app "$CONTAINER" \
  psql -h 127.0.0.1 -U book_app -d book -X -At -P pager=off -c "
    select '# ' || version();
    select '# ' || name || ' = ' || setting || coalesce(' ' || unit, '')
    from pg_settings
    where name in ('shared_buffers','work_mem','io_method','jit',
                   'max_parallel_workers_per_gather','effective_cache_size',
                   'default_transaction_isolation')
    order by name;"
