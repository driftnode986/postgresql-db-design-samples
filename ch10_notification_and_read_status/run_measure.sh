#!/usr/bin/env bash
# 第10章の測定を最初から通しで実行し、results/ に保存する。
#
#   SIZE=S bash ch10_notification_and_read_status/run_measure.sh
#
# 🔴 SQL とコメントを直したら、必ずこれを流し直す。
#    本文の数値は docs/chapter-src/values_ch10.py がここの出力から求めるので、
#    ログが古いまま本文を組み立てると、実測と本文が食い違う。
#
# 🔴 必ず reset-chapter から始める。案を作り直した直後に測ると、
#    別の案の古いテーブルが残ったまま比較され、検査が食い違う（第9章で 163 件の差が出た）。
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
CH=ch10_notification_and_read_status
R="$CH/results"
SIZE="${SIZE:-S}"
mkdir -p "$R"

save() {  # save <出力ファイル> <ロール> <スキーマ> <SQL> [追加の引数...]
  local out="$R/$1" role="$2" schema="$3" file="$4"; shift 4
  { bash scripts/collect-env.sh; echo "# SIZE=$SIZE"; echo
    SIZE="$SIZE" bash scripts/run-sql.sh "$role" "$schema" "$file" "$@"; } > "$out" 2>&1
  local rc=$?
  echo "  $file -> $out (rc=$rc)"
  return $rc
}

echo "■ やり直し"
bash scripts/reset-chapter.sh 10 >/dev/null 2>&1

echo "■ 元データ"
save "source_$SIZE.txt" book_owner ch10_r "$CH/r_source/schema_10_table.sql" || exit 1
{ bash scripts/collect-env.sh; echo "# SIZE=$SIZE"; echo
  SIZE="$SIZE" bash scripts/run-sql.sh book_owner ch10_r "$CH/r_source/schema_20_generate.sql"; } \
  >> "$R/source_$SIZE.txt" 2>&1 || exit 1

echo "■ 3 案のテーブルとデータ"
for s in a_row_per_recipient:ch10_a b_broadcast_one_row:ch10_b c_read_cursor:ch10_c; do
  d="${s%%:*}"; sc="${s##*:}"
  save "schema_${sc}.txt" book_owner "$sc" "$CH/$d/schema.sql" || exit 1
  save "load_${sc}_$SIZE.txt" book_owner "$sc" "$CH/$d/load.sql" || exit 1
done

echo "■ 未読件数と未読 20 件（案ごとに 3 回ずつ）"
{ bash scripts/collect-env.sh; echo "# SIZE=$SIZE"; echo; } > "$R/unread_$SIZE.txt"
for sc in ch10_a ch10_b ch10_c; do
  echo "## 10_unread_count.sql on $sc" >> "$R/unread_$SIZE.txt"
  SIZE="$SIZE" bash scripts/run-sql.sh book_app "$sc" \
    "$CH/queries/10_unread_count.sql" >> "$R/unread_$SIZE.txt" 2>&1
done
echo "  10_unread_count.sql -> $R/unread_$SIZE.txt"

echo "■ 索引のサイズ（同じ問い合わせを支える形にそろえて比べる）"
save "index_size_$SIZE.txt" book_owner ch10_a "$CH/a_row_per_recipient/50_index_size.sql" || exit 1

echo "■ 告知 1 件の配信（案A 対 案B）"
save "send_a_$SIZE.txt" book_owner ch10_a "$CH/a_row_per_recipient/30_send_broadcast.sql" || exit 1
save "send_b_$SIZE.txt" book_owner ch10_b "$CH/b_broadcast_one_row/30_send_broadcast.sql" || exit 1

echo "■ すべて既読にする（案A 対 案C）"
save "markread_a_$SIZE.txt" book_owner ch10_a "$CH/a_row_per_recipient/40_mark_all_read.sql" || exit 1
save "markread_c_$SIZE.txt" book_owner ch10_c "$CH/c_read_cursor/40_mark_all_read.sql" || exit 1

# 🔴 サイズは、実験用の表を作る前に測る。
#    削除の実験（del_plain・del_part_*）と対象の持ち方の実験（tgt_*）は
#    同じスキーマに表を作るので、あとで測ると案A が 64 MB ではなく 156 MB になる。
#    50_sizes.sql は案が使う表だけを数えるようにしてあるが、
#    測る順番も「実験の前」にしておく（検査は測定の直後に流す、と同じ理由）。
echo "■ サイズ（実験用の表を作る前に測る）"
save "sizes_$SIZE.txt" book_app ch10_a "$CH/queries/50_sizes.sql" || exit 1

echo "■ 通知の対象の持ち方 3 通り"
save "targets_$SIZE.txt" book_owner ch10_b "$CH/b_broadcast_one_row/50_target_shapes.sql" || exit 1

echo "■ 変更の手数（あとからパーティションを入れる）"
save "change_$SIZE.txt" book_owner ch10_a "$CH/change/10_add_partitioning.sql" || exit 1

echo "■ 90 日より古い通知を消す（DELETE 対 DETACH）"
save "delete_$SIZE.txt" book_owner ch10_a "$CH/a_row_per_recipient/60_delete_old.sql" || exit 1
save "detach_$SIZE.txt" book_owner ch10_a "$CH/a_row_per_recipient/61_detach_old.sql" || exit 1

echo "■ 検査（すべて先頭列が 0 で正常）"
save "verify_$SIZE.txt" book_owner ch10_a "$CH/queries/90_verify.sql"

echo "完了。SIZE=$SIZE の結果は $R/ にある。"
