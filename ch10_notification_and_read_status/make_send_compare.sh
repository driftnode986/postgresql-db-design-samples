#!/usr/bin/env bash
# 告知 1 件の配信コストを、案A と案B のログから 1 つの表にまとめる。
#
#   SIZE=S bash ch10_notification_and_read_status/make_send_compare.sh
#
# 🔴 手で書き写さない。send_a_*.txt と send_b_*.txt から抜き出す。
#    書き写すと、測定を取り直したときに黙って古くなる（第9章で 4 回踏んだ）。
#
# run_measure.sh が send_a / send_b を作った後に実行する。
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
R="ch10_notification_and_read_status/results"
SIZE="${SIZE:-S}"
A="$R/send_a_$SIZE.txt"
B="$R/send_b_$SIZE.txt"
OUT="$R/send_compare_$SIZE.txt"

for f in "$A" "$B"; do
  [ -f "$f" ] || { echo "NG: $f が無い。先に run_measure.sh を流す" >&2; exit 1; }
done

# 「wal_records | wal_size」の表の 1 行目を取る
wal_row() { grep -A 2 'wal_records |' "$1" | grep -E '^ +[0-9]+ \|' | head -1; }
# INSERT の行数と、その直後の Time
ins_rows() { grep -E '^INSERT 0 [0-9]+' "$1" | head -1; }
ins_time() { grep -A 1 -E '^INSERT 0 [0-9]+' "$1" | grep -E '^Time:' | head -1; }

a_wal="$(wal_row "$A")"; b_wal="$(wal_row "$B")"
[ -n "$a_wal" ] && [ -n "$b_wal" ] || {
  echo "NG: WAL の行を取り出せなかった（ログの形が変わった可能性）" >&2; exit 1; }

{
  echo "# 告知 1 件の配信コスト（案A 対 案B）"
  echo "# $A と $B から make_send_compare.sh が抜き出したもの。手で書き換えない"
  echo
  echo "案A 受信者ごとに 1 行（wal_records | wal_size）:"
  echo "$a_wal"
  echo "案B 告知は 1 行（wal_records | wal_size）:"
  echo "$b_wal"
  echo
  echo "投入した行数と時間:"
  echo "案A $(ins_rows "$A")  $(ins_time "$A")"
  echo "案B $(ins_rows "$B")  $(ins_time "$B")"
  echo
  # 🔴 図が引くための表。図の生成は「行ラベル | 値」の形を読むので、
  #    末尾に数値だけが来る行を用意する（sync-chart-values.py の row_last）。
  echo " 案                        | rows"
  echo "---------------------------+-------"
  printf ' %-25s | %s\n' "案A 受信者ごとに 1 行" "$(ins_rows "$A" | awk '{print $3}')"
  printf ' %-25s | %s\n' "案B 告知は 1 行" "$(ins_rows "$B" | awk '{print $3}')"
} > "$OUT"

echo "  -> $OUT"
cat "$OUT"
