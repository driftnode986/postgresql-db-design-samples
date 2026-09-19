#!/usr/bin/env bash
# 第13章の測定を最初から通しで実行し、results/ に保存する。
#
#   SIZE=S bash ch13_multi_tenant/run_measure.sh
#
# 🔴 SQL とコメントを直したら、必ずこれを流し直す。
#
# 🔴 必ず reset-chapter から始める。案を作り直した直後に測ると、
#    別の案の古い表が残ったまま比較される。
#
# 🔴 実行の順序が大事:
#      元データ → 4 案 → サイズ → 一致の検査 → 読み取り → 横断検索
#      → RLS の実演（所有者・付け忘れ・プール・一意制約）
#      → ここから先はデータを壊す → 移行 → 解約 → 原子性
#
#    - サイズと一致の検査は、データを変える実験より**前**（第10章・第11章の教訓）
#    - 🔴 解約（§20）はテナント 1 と 501 を消すので、それより後の測定では
#      この 2 社の行が 0 になる。読み取りは必ず解約より前に測る
#    - 🔴 一意制約の実演（42・43）は案B の customers をほとんど削除する。
#      サイズと一致の検査より後に置く
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
CH=ch13_multi_tenant
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

append() {  # append <出力ファイル> <ロール> <スキーマ> <SQL>
  local out="$R/$1" role="$2" schema="$3" file="$4"
  { echo; SIZE="$SIZE" bash scripts/run-sql.sh "$role" "$schema" "$file"; } >> "$out" 2>&1
  echo "  $file ->> $out (rc=$?)"
}

# 🔴 *_fails.sql は「失敗するのが正しい」ファイルである。
#    成功したら、制約や上限が効いていないということなので、そこで止める。
append_expect_fail() {  # append_expect_fail <出力> <ロール> <スキーマ> <SQL> <期待する文面>
  local out="$R/$1" role="$2" schema="$3" file="$4" want="$5"
  { echo; SIZE="$SIZE" bash scripts/run-sql.sh "$role" "$schema" "$file"; } >> "$out" 2>&1
  local rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "  ❌ $file は失敗するはずなのに成功した"
    echo "     期待した文面: $want"
    return 1
  fi
  if ! tail -40 "$out" | grep -q "$want"; then
    echo "  ❌ $file は失敗したが、期待した文面が出ていない"
    echo "     期待した文面: $want"
    return 1
  fi
  echo "  $file ->> $out (rc=${rc} 期待どおり失敗)"
}

echo "■ やり直し"
bash scripts/reset-chapter.sh 13 >/dev/null 2>&1

echo "■ 元データ"
save "source_$SIZE.txt" book_owner ch13_r "$CH/r_source/schema_10_table.sql" || exit 1
append "source_$SIZE.txt" book_owner ch13_r "$CH/r_source/schema_20_generate.sql"

echo "■ 案A（tenant_id の列）"
save "schema_ch13_a.txt" book_owner ch13_a "$CH/a_column/schema.sql" || exit 1
append "schema_ch13_a.txt" book_owner ch13_a "$CH/a_column/load.sql"
append "schema_ch13_a.txt" book_owner ch13_a "$CH/a_column/verify_content.sql"

echo "■ 案B（案A + 行レベルセキュリティ）"
save "schema_ch13_b.txt" book_owner ch13_b "$CH/b_rls/schema.sql" || exit 1
append "schema_ch13_b.txt" book_owner ch13_b "$CH/b_rls/load.sql"
append "schema_ch13_b.txt" book_owner ch13_b "$CH/b_rls/30_policy.sql"

echo "■ 案C（テナントごとにスキーマ。1,000 個作る）"
save "schema_ch13_c.txt" book_owner ch13_c "$CH/c_schema/schema.sql" || exit 1
append "schema_ch13_c.txt" book_owner ch13_c "$CH/c_schema/load.sql"

echo "■ 案D（tenant_id の LIST パーティション）"
save "schema_ch13_d.txt" book_owner ch13_d "$CH/d_partition/schema.sql" || exit 1
append "schema_ch13_d.txt" book_owner ch13_d "$CH/d_partition/load.sql"

echo "■ サイズ（データを変える実験の前に測る）"
save "sizes_$SIZE.txt" book_app ch13_a "$CH/compare/50_sizes.sql"

echo "■ 一致の検査（4 案が同じ中身であること）"
save "verify_$SIZE.txt" book_owner ch13_a "$CH/compare/90_verify.sql"

# 🔴 解約より前に測る。解約は会社 1 社ぶんの行を消すので、
#    あとで測ると抜き出す量が変わる。
echo "■ 区画に分けた表への外部キー（18 の NOT VALID）"
save "notvalid_$SIZE.txt" book_owner ch13_d "$CH/d_partition/30_not_valid_fk.sql"

echo "■ 会社 1 社だけを抜き出せるか（pg_dump）"
{ bash scripts/collect-env.sh; echo "# SIZE=$SIZE"; echo
  bash "$CH/compare/60_dump.sh"; } > "$R/dump_$SIZE.txt" 2>&1
dump_rc=$?
echo "  60_dump.sh -> $R/dump_$SIZE.txt (rc=$dump_rc)"
# 🔴 書き出しが空でも成功で終わるので、スクリプト側の検査の結果を見る
[ "$dump_rc" -eq 0 ] || { echo "  ❌ pg_dump の測定が失敗した"; exit 1; }

echo "■ 読み取り: 案A と案B の一覧（各 3 回）"
save "read_a_$SIZE.txt" book_app ch13_a "$CH/a_column/20_read_list.sql"
save "read_b_$SIZE.txt" book_app ch13_b "$CH/b_rls/20_read_list.sql"

echo "■ 横断検索（skip scan と専用の索引）"
save "cross_$SIZE.txt" book_app ch13_a "$CH/a_column/25_cross_tenant.sql"
append "cross_$SIZE.txt" book_owner ch13_a "$CH/a_column/26_cross_tenant_index.sql"

echo "■ 条件の付け忘れ（案A は漏れる・案B は漏れない）"
save "leak_$SIZE.txt" book_app ch13_a "$CH/a_column/40_forgotten_where.sql"
append "leak_$SIZE.txt" book_app ch13_b "$CH/b_rls/40_forgotten_where.sql"

echo "■ 所有者にポリシーが効かないこと"
save "owner_$SIZE.txt" book_owner ch13_b "$CH/b_rls/31_owner_bypass.sql"

echo "■ 接続プールでの漏洩（is_local の違い）"
save "pool_$SIZE.txt" book_app ch13_b "$CH/b_rls/41_pool_leak.sql"

echo "■ ここから先はデータを壊す"

echo "■ 全テナントへの列追加（案B 1 回 対 案C 1,000 回）"
save "migrate_$SIZE.txt" book_owner ch13_b "$CH/change/10_add_column.sql"

echo "■ 解約（案B DELETE・案C DROP SCHEMA・案D DETACH）"
save "terminate_$SIZE.txt" book_owner ch13_b "$CH/change/20_terminate.sql"

# 🔴 一意制約の実演は、案B の行をほとんど削る。
#    解約の測定（巨大テナントの DELETE）より後に置く。
echo "■ 一意制約からの情報漏れ（案B の行を削る）"
save "covert_$SIZE.txt" book_owner ch13_b "$CH/b_rls/42_unique_setup.sql" || exit 1
# 🔴 43 は**失敗するのが正しい**。成功したら制約が効いていない
append_expect_fail "covert_$SIZE.txt" book_app ch13_b \
  "$CH/b_rls/43_covert_channel_fails.sql" "duplicate key value violates unique constraint"

echo "■ 🔴 原子性: 1 トランザクションでのスキーマ量産は上限に当たる"
save "atomicity_$SIZE.txt" book_owner ch13_c "$CH/c_schema/schema.sql" >/dev/null 2>&1
append_expect_fail "atomicity_$SIZE.txt" book_owner ch13_c \
  "$CH/c_schema/50_migration_atomicity_fails.sql" "out of shared memory"

echo "■ 完了"
