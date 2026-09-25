# 第14章 退会とデータ削除 個人情報を消し、売上とコメントは残す

案ごとにスキーマを分けます。

- `ch14_a`（`a_soft/`）: 印を立てる（論理削除）
- `ch14_b`（`b_purge/`）: 行を消し、控えを取る（物理削除）
- `ch14_c`（`c_split/`）: 個人情報を別のテーブルに分ける
- `ch14_r`（`r_source/`）: 3 案に写す元データ
- `ch14_x`（`x_firstidea/`）: 採取した案の検算（3 つとも失敗するのが正しい）
- `ch14_z`（`change/` の一部）: インデックスのサイズ・VACUUM・ロック・外部キーの実験用

この章の SQL は、この章のスキーマと `lib` 以外を参照しません（`scripts/check-schema-isolation.sh` が検査します）。

## 通しで測る

```bash
SIZE=S bash ch14_account_deletion/run_measure.sh    # 本文の数値はこの量
SIZE=XS bash ch14_account_deletion/run_measure.sh   # 動作確認用（数値は本文に使わない）
```

`run_measure.sh` は最初に `scripts/reset-chapter.sh 14` を実行して、章のスキーマを消してから測ります。出力は `results/` に保存され、先頭に `scripts/collect-env.sh` の出力（版・設定・日時）が付きます。

## 1 つだけ流す

```bash
bash scripts/run-sql.sh book_owner ch14_a ch14_account_deletion/a_soft/schema.sql
```

`change/70_split_pii_a_to_c.sql` は `BEGIN` … `ROLLBACK` で囲んであり、案A のテーブルを変更しません。
