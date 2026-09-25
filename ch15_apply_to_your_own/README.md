# 第15章 自分の題材に当てはめる　案を立て、測り、選び、説明する

この章は案どうしの比較をしません。章をまたいで衝突する組み合わせと、PostgreSQL 18 で手数が減った変更の実行例を、例ごとにスキーマを分けて置いています。

- `ch15_a`（`a_history/`）: 追記だけの履歴に個人情報を写すと、退会しても消せない
- `ch15_b`（`b_split/`）: 個人情報を別のテーブルに置き、履歴には写さない
- `ch15_c`（`c_period/`）: 期間つき外部キーの参照先を縮める・`RESTRICT` を付ける（どちらも失敗するのが正しい）
- `ch15_d`（`d_notnull/`）: `NOT NULL` を `NOT VALID` で足し、残りを埋めてから検査する
- `ch15_e`（`e_enforced/`）: `NOT ENFORCED` の外部キーと `CHECK`、100 万行の一括挿入の時間
- `ch15_f`（`f_serial/`）: 取り消した INSERT の番号が欠番になる

## 通しで実行する

```bash
bash ch15_apply_to_your_own/run_measure.sh
```

最初に `scripts/reset-chapter.sh 15` を実行して、章のスキーマを消してから流します。出力は `results/` に保存され、先頭に `scripts/collect-env.sh` の出力が付きます。データ量は固定で、`SIZE` は使いません。
