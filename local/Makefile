################################################################################
# Main
################################################################################
.PHONY: up
up: ## コンテナ群を立ち上げる
	@docker compose up
	@make down

.PHONY: down
down: ## コンテナ群を落とし、dumpファイルも削除
	@docker compose down
	@rm -f source.dump

.PHONY: bash
bash: ## mysqlコンテナにbashで入る
	docker compose exec mysql-1111 bash

.PHONY: mysql
mysql: ## mysql-1111コンテナにmysqlで入る
	docker compose exec mysql-1111 mysql -Dhoge

.PHONY: mysql-2222
mysql-2222: ## mysql-2222コンテナにmysqlで入る
	docker compose exec mysql-2222 mysql

.PHONY: mysql-3333
mysql-3333: ## mysql-3333コンテナにmysqlで入る
	docker compose exec mysql-3333 mysql

.PHONY: start-replication-2222
start-replication-2222: source.dump ## mysql-1111 → mysql-2222にリストア、レプリケーション準備
	@$(eval GTID_PURGED := $(shell grep "SET @@GLOBAL.GTID_PURGED" source.dump | sed -n "s/.*SET @@GLOBAL.GTID_PURGED='\([^']*\)'.*/\1/p"))
	@$(eval ALREADY_STARTED_REPL := $(shell docker compose exec mysql-2222 bash -c 'mysql -uroot -e "show replica status\G"' | grep 'Replica_SQL_Running:'))
	@# -n オプションは「通常の自動出力を抑制」し、明示的にp(print)した行だけを出力
	@# s/パターン/置換/p は「パターンにマッチした部分を置換し、-n時はpで出力
	@# \([^']*\): ()で囲まれた部分は「キャプチャグループ」
	@# [^']は、シングルクォート以外の文字を0回以上
	@# \1は、キャプチャグループ部分
	@# /pは、置換が成功した行だけを出力
	@if [ "$(ALREADY_STARTED_REPL)" = "" ]; then docker compose exec mysql-2222 bash -c 'mysql -uroot < source.dump'; fi
	@if [ "$(ALREADY_STARTED_REPL)" = "" ]; then docker compose exec mysql-2222 bash -c "mysql -uroot -e \"set @@GLOBAL.GTID_PURGED='$(GTID_PURGED)';\""; fi
	@if [ "$(ALREADY_STARTED_REPL)" = "" ]; then docker compose exec mysql-2222 bash -c "mysql -uroot -s -N -e \"select @@GLOBAL.GTID_PURGED;\""; fi
	@if [ "$(ALREADY_STARTED_REPL)" = "" ]; then docker compose exec mysql-2222 bash -c "mysql -uroot -e \"change replication source to SOURCE_HOST='mysql-1111',SOURCE_USER='root',SOURCE_AUTO_POSITION=1;\""; fi
	@if [ "$(ALREADY_STARTED_REPL)" = "" ]; then docker compose exec mysql-2222 bash -c 'mysql -uroot -e "START REPLICA;"'; fi
	@if [ "$(ALREADY_STARTED_REPL)" = "" ]; then docker compose exec mysql-2222 bash -c 'mysql -uroot -e "set GLOBAL read_only=ON;"'; sleep 1; fi
	@docker compose exec mysql-2222 bash -c 'mysql -uroot -e "SHOW REPLICA STATUS\G"'

.PHONY: start-replication-3333
start-replication-3333: source.dump ## mysql-1111 → mysql-3333にリストア、mysql-2222からレプリケーション準備
	@$(eval GTID_PURGED := $(shell grep "SET @@GLOBAL.GTID_PURGED" source.dump | sed -n "s/.*SET @@GLOBAL.GTID_PURGED='\([^']*\)'.*/\1/p"))
	@$(eval ALREADY_STARTED_REPL := $(shell docker compose exec mysql-3333 bash -c 'mysql -uroot -e "show replica status\G"' | grep 'Replica_SQL_Running:'))
	@# -n オプションは「通常の自動出力を抑制」し、明示的にp(print)した行だけを出力
	@# s/パターン/置換/p は「パターンにマッチした部分を置換し、-n時はpで出力
	@# \([^']*\): ()で囲まれた部分は「キャプチャグループ」
	@# [^']は、シングルクォート以外の文字を0回以上
	@# \1は、キャプチャグループ部分
	@# /pは、置換が成功した行だけを出力
	@if [ "$(ALREADY_STARTED_REPL)" = "" ]; then docker compose exec mysql-3333 bash -c 'mysql -uroot < source.dump'; fi
	@if [ "$(ALREADY_STARTED_REPL)" = "" ]; then docker compose exec mysql-3333 bash -c "mysql -uroot -e \"set @@GLOBAL.GTID_PURGED='$(GTID_PURGED)';\""; fi
	@if [ "$(ALREADY_STARTED_REPL)" = "" ]; then docker compose exec mysql-3333 bash -c "mysql -uroot -s -N -e \"select @@GLOBAL.GTID_PURGED;\""; fi
	@if [ "$(ALREADY_STARTED_REPL)" = "" ]; then docker compose exec mysql-3333 bash -c "mysql -uroot -e \"change replication source to SOURCE_HOST='mysql-2222',SOURCE_USER='root',SOURCE_AUTO_POSITION=1;\""; fi
	@if [ "$(ALREADY_STARTED_REPL)" = "" ]; then docker compose exec mysql-3333 bash -c 'mysql -uroot -e "START REPLICA;"'; fi
	@if [ "$(ALREADY_STARTED_REPL)" = "" ]; then docker compose exec mysql-3333 bash -c 'mysql -uroot -e "set GLOBAL read_only=ON;"'; sleep 1; fi
	@docker compose exec mysql-3333 bash -c 'mysql -uroot -e "SHOW REPLICA STATUS\G"'

source.dump:
	@echo 'source.dumpがないため、mysql-1111をdumpします'
	@docker compose exec mysql-1111 mysqldump -uroot --single-transaction --default-character-set=utf8mb4 --set-gtid-purged=COMMENTED --routines --triggers --events --hex-blob --all-databases > source.dump
	@echo 'dump完了(source.dump)'

.PHONY: insert
insert: ## mysql-1111に行をINSERT
	@docker compose exec mysql-1111 mysql -uroot -e 'insert into hoge.hoge values ();'

.PHONY: cycle-sql
cycle-sql: ## 定期的に同じSQLをmysql-1111に打つ
	@docker run --rm -it ubuntu:24.10 bash -c "watch -n1 'echo \$$(date)'"

################################################################################
# cycledog
################################################################################
#.PHONY: cycledog
#cycledog: ## cycledog(SQLの結果を定期的にdatadogに送る)
#	docker run -it --rm --mount type=bind,source=${PWD}/cyqldog/test-fixtures/,target=/app/config/ -e DB_HOST -e DD_HOST -e DD_API_KEY ghcr.io/crowdworks/cyqldog:latest -C config/cyqldog.yml

################################################################################
# Utility-Command help
################################################################################
.DEFAULT_GOAL := help

SHELLCHECK_VERSION := v0.10.0
.PHONY: lint.sh
lint.sh: ## lint shell
	$(eval SH_FILES := $(shell ls -1 scripts/*.sh | xargs basename))
	@docker run --rm -it -u "${USER_ID}:${GROUP_ID}" --mount type=bind,source=${PWD}/scripts/,target=/scripts/ -w /scripts koalaman/shellcheck:${SHELLCHECK_VERSION} ${SH_FILES}

################################################################################
# マクロ
################################################################################
# Makefileの中身を抽出してhelpとして1行で出す
# $(1): Makefile名
# 使い方例: $(call help,{included-makefile})
define help
  grep -E '^[\.a-zA-Z0-9_-]+:.*?## .*$$' $(1) \
  | grep --invert-match "## non-help" \
  | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
endef

################################################################################
# タスク
################################################################################
.PHONY: help
help: ## Make タスク一覧
	@echo '######################################################################'
	@echo '# Makeタスク一覧'
	@echo '# $$ make XXX'
	@echo '# or'
	@echo '# $$ make XXX --dry-run'
	@echo '######################################################################'
	@echo $(MAKEFILE_LIST) \
	| tr ' ' '\n' \
	| xargs -I {included-makefile} $(call help,{included-makefile})
