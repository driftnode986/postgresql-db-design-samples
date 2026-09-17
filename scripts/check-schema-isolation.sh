#!/usr/bin/env bash
# 章の隔離が破られていないかを検査する。
#
#   bash scripts/check-schema-isolation.sh          全章
#   bash scripts/check-schema-isolation.sh 06       第6章だけ
#   bash scripts/check-schema-isolation.sh --self-test   検査器そのものの検査
#
# 規約:
#   - chNN_*/ の下の SQL とスクリプトが参照してよいスキーマは、自分の章が所有するものと、
#     lib（データ生成の関数）と public（拡張の関数）だけ
#   - 章が所有するスキーマの形は ^chNN(_[a-z](_[a-z0-9]+)?)?$
#     （ch06、ch06_a、テナント別の ch13_c_t001 など。scripts/reset-chapter.sh と同じ形）
#   - テーブルを作ってよいのは自分の章のスキーマだけ。public と lib にテーブルを作らない
#   - 案のディレクトリ a_xxx/ の中で、他の案のスキーマ（chNN_b）を作らない
#
# 理由: 全章共通のテーブルや、他の章のスキーマに書き込む SQL があると、ある章の実験が
#       別の章の測定値を変えてしまう。章ごとに reset できることが再現性の前提になる。
#
# 終了コード: 0 = 違反なし / 1 = 違反あり
set -uo pipefail
ROOT="${ISOLATION_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ARG="${1:-}"

if [ "$ARG" = "--self-test" ]; then
  # わざと違反を作り、検査が落ちることを確かめる。落ちなければ検査器が壊れている
  T="$(mktemp -d)"
  trap 'rm -rf "$T"' EXIT
  mkdir -p "$T/ch05_order_and_inventory/a_lock" "$T/ch06_reservation/a_app_check"
  echo "CREATE TABLE ch05_a.stocks (id bigint);" > "$T/ch05_order_and_inventory/a_lock/schema.sql"
  echo "CREATE TABLE ch06_a.reservations (id bigint);" > "$T/ch06_reservation/a_app_check/schema.sql"
  ISOLATION_ROOT="$T" bash "${BASH_SOURCE[0]}" >/dev/null 2>&1
  [ $? -eq 0 ] || { echo "self-test NG: 違反の無い入力で失敗した"; exit 1; }
  echo "INSERT INTO ch05_a.stocks VALUES (1);" > "$T/ch06_reservation/a_app_check/load.sql"
  ISOLATION_ROOT="$T" bash "${BASH_SOURCE[0]}" >/dev/null 2>&1
  [ $? -eq 1 ] || { echo "self-test NG: 他の章のスキーマへの書き込みを見逃した"; exit 1; }
  echo "SELECT 1;" > "$T/ch06_reservation/a_app_check/load.sql"
  echo "CREATE TABLE public.tmp_all (id bigint);" > "$T/ch06_reservation/a_app_check/extra.sql"
  ISOLATION_ROOT="$T" bash "${BASH_SOURCE[0]}" >/dev/null 2>&1
  [ $? -eq 1 ] || { echo "self-test NG: public へのテーブルの作成を見逃した"; exit 1; }
  rm "$T/ch06_reservation/a_app_check/extra.sql"
  mkdir -p "$T/ch13_multi_tenant/c_schema_per_tenant"
  echo "CREATE SCHEMA ch13_c_t001; CREATE TABLE ch13_c_t001.items (id bigint);" > "$T/ch13_multi_tenant/c_schema_per_tenant/schema.sql"
  ISOLATION_ROOT="$T" bash "${BASH_SOURCE[0]}" >/dev/null 2>&1
  [ $? -eq 0 ] || { echo "self-test NG: テナント別スキーマ ch13_c_t001 を違反にした"; exit 1; }
  echo "SELECT * FROM ch12_a_t001.items;" > "$T/ch13_multi_tenant/c_schema_per_tenant/q.sql"
  ISOLATION_ROOT="$T" bash "${BASH_SOURCE[0]}" >/dev/null 2>&1
  [ $? -eq 1 ] || { echo "self-test NG: 他の章のテナント別スキーマへの参照を見逃した"; exit 1; }
  echo "self-test OK: 違反なしとテナント別スキーマは通し、他章への参照と public への作成は落とした"
  exit 0
fi

python3 - "$ROOT" "$ARG" <<'PY'
import glob, os, re, sys

root, arg = sys.argv[1], sys.argv[2]
dirs = sorted(glob.glob(os.path.join(root, 'ch[0-9][0-9]_*')))
if arg:
    dirs = [d for d in dirs if os.path.basename(d).startswith(f'ch{int(arg):02d}_')]
if not dirs:
    print('NG: 対象の章ディレクトリが無い')
    sys.exit(1)

# スキーマ名らしい語（ch06、ch06_a、ch13_c_t001）。章ディレクトリ名 ch06_reservation は 2 文字以上が続くので拾わない
SCHEMA = re.compile(r'\bch(\d\d)(?:_[a-z](?:_[a-z0-9]+)?)?\b')
bad, nfiles = [], 0
for d in dirs:
    me = os.path.basename(d)[2:4]
    for base, _, fs in os.walk(d):
        if os.path.basename(base) == 'results':
            continue
        for fn in fs:
            if not fn.endswith(('.sql', '.sh')) and fn != 'Makefile':
                continue
            path = os.path.join(base, fn)
            rel = os.path.relpath(path, root)
            nfiles += 1
            plan = re.search(r'(?:^|/)([a-z])_[a-z0-9_]+/', os.path.relpath(path, d) + '/')
            for i, line in enumerate(open(path, encoding='utf-8'), 1):
                code = re.sub(r'--.*$', '', line) if fn.endswith('.sql') else line
                for m in SCHEMA.finditer(code):
                    if m.group(1) != me:
                        bad.append(f'{rel}:{i} 他の章のスキーマ {m.group(0)} を参照している')
                if re.search(r'\bCREATE\s+(?:UNLOGGED\s+|TEMP\w*\s+)?TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?'
                             r'(public|lib)\.', code, re.I):
                    bad.append(f'{rel}:{i} public / lib にテーブルを作っている')
                m = re.search(r'\bCREATE\s+SCHEMA\s+(?:IF\s+NOT\s+EXISTS\s+)?(ch\d\d_([a-z])(?:_[a-z0-9]+)?)\b', code, re.I)
                if m and plan and m.group(2) != plan.group(1):
                    bad.append(f'{rel}:{i} 案 {plan.group(1)} のディレクトリで {m.group(1)} を作っている')

for b in bad:
    print(f'  NG {b}')
if nfiles == 0:
    print('注意: 検査の対象になる SQL とスクリプトが 0 件（まだ章のファイルが無い）')
print(f'検査したファイル {nfiles} 件 / 違反 {len(bad)} 件')
sys.exit(1 if bad else 0)
PY
