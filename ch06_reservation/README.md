# 第6章 予約 同じ部屋の同じ時間に2件入れない

案ごとにスキーマを分けます（案A は `ch06_a`、案B は `ch06_b`）。
この章の SQL は、この章のスキーマと `lib` 以外を参照しません（`scripts/check-schema-isolation.sh` が検査します）。

ファイルは、書籍の該当する章と同時に追加します。追加後は、次の順で実行します。

```bash
# 1. テーブルを作る（所有者のロール）
bash scripts/run-sql.sh book_owner ch06_a ch06_reservation/<案のディレクトリ>/schema.sql
# 2. データを入れる（SIZE=S は数分以内に終わる量）
SIZE=S bash scripts/run-sql.sh book_owner ch06_a ch06_reservation/load/<ファイル>.sql
# 3. 測る（測定用のロール）
bash scripts/run-sql.sh book_app ch06_a ch06_reservation/queries/<ファイル>.sql
# 4. やり直すときは、この章のスキーマだけを消す
bash scripts/reset-chapter.sh 06
```

採取した出力は `results/` に保存し、先頭に `bash scripts/collect-env.sh` の出力（版・設定・日時）を付けます。
