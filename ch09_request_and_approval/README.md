# 第9章 申請と承認 状態の変化と修正前の値を残す

案ごとにスキーマを分けます（案A は `ch09_a`、案B は `ch09_b`、案C は `ch09_c`、案D は `ch09_d`）。
元データは `ch09_r`、採取した案の検算は `ch09_x` です。
この章の SQL は、この章のスキーマと `lib` 以外を参照しません（`scripts/check-schema-isolation.sh` が検査します）。

この章は 2 段で比べます。

- **状態の持ち方**: 案A（状態の列 + 遷移履歴）/ 案B（遷移の追記のみ）
- **内容の履歴の持ち方**: 案C（本体に現在の内容、履歴に更新前の行）/ 案D（範囲型 + `WITHOUT OVERLAPS`）

採取した案の検算（期間を 2 列で持つと重なりとすき間が入ること）は `x_first_idea/` にあります。

## 実行

```bash
# 測定を最初から通しで実行する（results/ に保存される）
SIZE=S bash ch09_request_and_approval/run_measure.sh

# 個別に流すとき
bash scripts/run-sql.sh book_owner ch09_a ch09_request_and_approval/a_status_column/schema.sql
bash scripts/run-sql.sh book_app   ch09_a ch09_request_and_approval/queries/10_inbox.sql

# やり直すときは、この章のスキーマだけを消す
bash scripts/reset-chapter.sh 09
```

採取した出力は `results/` に保存し、先頭に `bash scripts/collect-env.sh` の出力（版・設定・日時）を付けます。
