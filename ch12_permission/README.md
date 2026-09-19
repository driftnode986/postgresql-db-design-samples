# 第12章 権限　閲覧できる文書だけを一覧に出す

案ごとにスキーマを分けます。

- `ch12_r` … 元データ（3 案はここから同じ中身を写します）
- `ch12_a` … 案A 都度たどる（`a_traverse/`）
- `ch12_b` … 案B 役割と権限を表に持つ（`b_rbac/`）
- `ch12_c` … 案C 判定を実体化する（`c_materialized/`）
- `ch12_d` … 階層の深さの実験（`d_depth/`）
- `ch12_g` … `GRANT` の実演（`g_grant/`）

この章の SQL は、この章のスキーマと `public`（拡張）以外を参照しません
（`scripts/check-schema-isolation.sh` が検査します）。

## まとめて実行する

```bash
SIZE=S bash ch12_permission/run_measure.sh
```

元データの生成から測定まで通しで実行し、`results/` に保存します。
案C の初期構築（30 秒以上）とズレの検査（1 回 45 秒以上）があるので、全体で 10 分ほどかかります。

## 1 つずつ実行する

```bash
# 1. 元データ（所有者のロール）
bash scripts/run-sql.sh book_owner ch12_r ch12_permission/r_source/schema_10_table.sql
SIZE=S bash scripts/run-sql.sh book_owner ch12_r ch12_permission/r_source/schema_20_generate.sql

# 2. 案A のテーブルとデータ
bash scripts/run-sql.sh book_owner ch12_a ch12_permission/a_traverse/schema.sql
bash scripts/run-sql.sh book_owner ch12_a ch12_permission/a_traverse/load.sql

# 3. 測る（測定用のロール）
bash scripts/run-sql.sh book_app ch12_a ch12_permission/a_traverse/21_read_set.sql

# 4. やり直すときは、この章のスキーマだけを消す
bash scripts/reset-chapter.sh 12
```

採取した出力は `results/` に保存し、先頭に `bash scripts/collect-env.sh` の出力
（版・設定・日時）を付けます。

## 注意する点

- **測定は `book_app`** で行います。スーパーユーザー（`book_admin`）とテーブルの所有者は
  行レベルセキュリティを迂回するので、ポリシーが効いていないのに効いているように見えます
- **権限不足の実演は `book_guest`** で行います。`book_app` には既定の権限が自動で付くので、
  `g_grant/` のシーケンスの権限不足は再現しません
- 🔴 **行レベルセキュリティのポリシーを付けたら、測定が終わったら必ず外します**
  （`a_traverse/39_rls_disable.sql`）。残すと、次に測る案が
  「ポリシーが絞ったあとの行」にしか触らず、比較が壊れます
- 🔴 **失敗するのが正しいファイル**は名前が `*_fails.sql` です
  （`g_grant/10_serial_insert_fails.sql`、`b_rbac/41_overlap_fails.sql`、
  `b_rbac/42_collation_fails.sql`）。エラーにならなければ、そちらが異常です
