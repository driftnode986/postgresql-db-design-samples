# 使い方: make up / make env / make reset CH=06 / make check / make down
.PHONY: up down destroy env reset check psql

up:            ## コンテナを起動し、接続できるまで待つ
	docker compose up -d --wait

down:          ## コンテナを止める（データは残る）
	docker compose down

destroy:       ## コンテナとデータを消す（最初からやり直す）
	docker compose down -v

env:           ## 版と主な設定値を表示する（測定結果の先頭に残す）
	bash scripts/collect-env.sh

reset:         ## 1 つの章のスキーマだけを消す。例: make reset CH=06
	@test -n "$(CH)" || (echo "CH=章番号 を指定する（例: make reset CH=06）"; exit 2)
	bash scripts/reset-chapter.sh $(CH)

check:         ## 章の隔離が破られていないかを検査する
	bash scripts/check-schema-isolation.sh --self-test
	bash scripts/check-schema-isolation.sh

psql:          ## 測定用のロール（book_app）で接続する
	docker exec -it -e PGPASSWORD=book_app pgdbdesign psql -h 127.0.0.1 -U book_app -d book
