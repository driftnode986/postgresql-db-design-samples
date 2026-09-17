# 第1章 環境をつくり、測り方を決める

スキーマは `ch01` の 1 つだけです（案の比較をしない章のため）。第2章以降は、案ごとに `ch06_a`、`ch06_b` のようにスキーマを分けます。
この章の SQL は、この章のスキーマ以外を参照しません（`scripts/check-schema-isolation.sh` が検査します）。

## 実行の順序

```bash
# 1. テーブルと関数を作る（所有者のロール）
for f in ch01_environment/schema_*.sql; do bash scripts/run-sql.sh book_owner ch01 "$f"; done

# 2. データを入れる（SIZE=S は 10 万行。M は 100 万行、L は 500 万行）
SIZE=S bash scripts/run-sql.sh book_owner ch01 ch01_environment/load_order_items.sql
SIZE=S bash scripts/run-sql.sh book_owner ch01 ch01_environment/load_pk_size.sql

# 3. 全章共通の規約の確認（ファイル名の番号順。先頭のコメントの run-as がロール）
bash scripts/run-sql.sh book_app ch01 ch01_environment/conv/01_serial_manual.sql

# 4. 測定の結果を results/ に取り直す（order_items と主キーの比較を M で入れ直して測る。数分かかる）
bash ch01_environment/run_measure.sh

# 5. やり直すときは、この章のスキーマだけを消す
bash scripts/reset-chapter.sh 01
```

`conv/` のファイルは 1 回だけ実行する前提です（`01_serial_manual.sql` を 2 回実行すると主キーが衝突します）。やり直すときは 5 から始めます。

## ファイル

- `schema_10_reservation.sql` … 予約の 2 つの方式（確認してから登録 / 排他制約）
- `schema_20_rls.sql`、`rls_count_app.sql`、`rls_count_owner.sql` … ロールによって見える行が変わる例
- `schema_30_orders.sql`、`load_order_items.sql` … データ量と 4 つの指標の説明に使うテーブル
- `schema_40_conventions.sql`、`conv/` … 全章共通の規約の確認
- `schema_50_pk_size.sql`、`load_pk_size.sql` … 主キーの型による総サイズの比較
- `queries/` … 設定値、内容のハッシュ、偏り、実行計画、サイズ
- `bench/` … pgbench のスクリプト。`run_bench.sh` が 5 回ずつ測ります
- `change/` … あとからの変更の手数の測り方
- `extras/` … SQL の流し方と ERROR の位置、拡張の置き場所、インデックスを付けたままの投入の確認
- `results/` … 採取した出力。先頭に `bash scripts/collect-env.sh` の出力（版・設定・日時）を付けています
