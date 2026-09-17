# 第2章 商品カタログ 種類ごとに項目が違う商品をどう持つか

家電・衣料・書籍を扱う EC サイトの商品カタログを、3 つの案と参考の 1 案で作り、同じ商品を入れて比べます。

- `r_source/` 元データ（スキーマ `ch02_r`）。ここで 1 回だけ作り、各案が id の順に写します
- `a_columns/` 案A: 属性ごとに列を足す（`ch02_a`）
- `b_jsonb/` 案B: 属性を `jsonb` の列に入れる（`ch02_b`）。`gen/` は生成列・CHECK・`JSON_VALUE` の確認
- `c_child_tables/` 案C: 種類ごとの子テーブルに分ける（`ch02_c`）
- `d_eav/` 参考の案D: 「商品・属性・値」の 3 つ組で持つ（`ch02_d`）。S だけで測ります
- `queries/` どの案にも使える問い合わせ（保存サイズ）

どの案でも、商品のテーブルの名前は `products` です。
この章の SQL は、この章のスキーマ以外を参照しません（`scripts/check-schema-isolation.sh` が検査します）。

## 実行の順序

```bash
# 0. やり直すときは、この章のスキーマだけを消す
bash scripts/reset-chapter.sh 02

# 1. 元データを作る（SIZE=S は 10 万商品、SIZE=M は 100 万商品）
bash scripts/run-sql.sh book_owner ch02_r ch02_product_catalog/r_source/schema_10_table.sql
SIZE=S bash scripts/run-sql.sh book_owner ch02_r ch02_product_catalog/r_source/schema_20_generate.sql

# 2. 案ごとにテーブルを作り、元データを写す（案A の例。b_jsonb は ch02_b、c_child_tables は ch02_c）
bash scripts/run-sql.sh book_owner ch02_a ch02_product_catalog/a_columns/schema.sql
bash scripts/run-sql.sh book_owner ch02_a ch02_product_catalog/a_columns/load.sql

# 3. 測る（測定用のロール）
bash scripts/run-sql.sh book_app ch02_a ch02_product_catalog/a_columns/queries/10_popular.sql
bash scripts/run-sql.sh book_app ch02_a ch02_product_catalog/queries/90_sizes.sql
```

先頭のコメントに `-- run-as: book_owner` とあるファイルは、`book_owner` で実行します
（統計やインデックスを足して、`ROLLBACK` で元に戻すファイルです）。

`change/` のファイルはテーブルを書き換えます。実行したあとで測定を続けるときは、その案の `load.sql` を実行し直してください。

`results/` の全部を取り直すには `bash ch02_product_catalog/run_measure.sh`（M）を実行します。
採取した出力の先頭には、`bash scripts/collect-env.sh` の出力（版・設定・日時）が付きます。
