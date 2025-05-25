################################################################################
# Main
################################################################################
.PHONY: bash
bash: ## mysqlコンテナにbashで入る
	@docker compose run --rm mysql bash

.PHONY: snapshot
snapshot: ## source側のスナップショットをとる
	@docker compose run --rm mysql bash -c "mysql --connect-timeout=3 -h$${SOURCE_DB_WRITER} -u$${SOURCE_DB_USER} -p$${SOURCE_DB_PASSWORD} -e \"call mysql.rds_set_configuration('binlog retention hours', 2160);\""
	@aws-vault exec main -- aws rds create-db-cluster-snapshot --db-cluster-identifier ${SOURCE_CLUSTER_NAME} --db-cluster-snapshot-identifier hogehoge

.PHONY: restore-from-snapshot
restore-from-snapshot: ## スナップショットから復元
	@aws-vault exec main -- aws rds restore-db-cluster-from-snapshot --db-cluster-identifier fuga --snapshot-identifier hogehoge --engine aurora-mysql

.PHONY: mysql-source
mysql-source: ## source側にmysqlで入る
	@docker compose run --rm mysql bash -c 'mysql --connect-timeout=3 -h$${SOURCE_DB_WRITER} -u$${SOURCE_DB_USER} -p$${SOURCE_DB_PASSWORD}'
.PHONY: mysql-source-by-repl-user
mysql-replica-by-repl-user: ## source側にreplica用ユーザーでmysqlで入る
	@docker compose run --rm mysql bash -c 'mysql --connect-timeout=3 -h$${SOURCE_DB_WRITER} -u$${SOURCE_DB_REPLICA_USER} -p$${SOURCE_DB_REPLICA_PASSWORD}'

.PHONY: mysql-replica
mysql-replica: ## replica側にmysqlで入る
	@docker compose run --rm mysql bash -c 'mysql --connect-timeout=3 -h$${REPLICA_DB_HOST} -u$${SOURCE_DB_USER} -p$${SOURCE_DB_PASSWORD}'

.PHONY: mysql-green
mysql-green: ## green側にmysqlで入る
	@docker compose run --rm mysql bash -c 'mysql --connect-timeout=3 -h$${GREEN_DB_HOST} -u$${SOURCE_DB_USER} -p$${SOURCE_DB_PASSWORD}'


.PHONY: sample
sample: ## source側にmysqlで入る
	@docker compose run --rm mysql bash -c 'mysql -h$${SOURCE_DB_WRITER} -u$${SOURCE_DB_USER} -p$${SOURCE_DB_PASSWORD} < sample.sql'

.PHONY: insert
insert: ## source側に行をINSERT
	@docker compose run --rm mysql bash -c 'mysql -h$${SOURCE_DB_WRITER} -u$${SOURCE_DB_USER} -p$${SOURCE_DB_PASSWORD} -e "insert into hoge.hoge values ();"'

.PHONY: create-repl-user
create-repl-user: ## replica側にreplica-userを作成
	@docker compose run --rm mysql bash -c "mysql --connect-timeout=3 -h$${SOURCE_DB_WRITER} -u$${SOURCE_DB_USER} -p$${SOURCE_DB_PASSWORD} -e \"CREATE USER IF NOT EXISTS '$${SOURCE_DB_REPLICA_USER}'@'%' IDENTIFIED BY '$${SOURCE_DB_REPLICA_PASSWORD}';\""
	@docker compose run --rm mysql bash -c "mysql --connect-timeout=3 -h$${SOURCE_DB_WRITER} -u$${SOURCE_DB_USER} -p$${SOURCE_DB_PASSWORD} -e \"GRANT REPLICATION CLIENT, REPLICATION SLAVE ON *.* TO '$${SOURCE_DB_REPLICA_USER}'@'%';\""
	@docker compose run --rm mysql bash -c "mysql --connect-timeout=3 -h$${SOURCE_DB_WRITER} -u$${SOURCE_DB_USER} -p$${SOURCE_DB_PASSWORD} -e \"select user,host,ssl_type from mysql.user where user='$${SOURCE_DB_REPLICA_USER}';\""
	@docker compose run --rm mysql bash -c "mysql --connect-timeout=3 -h$${SOURCE_DB_WRITER} -u$${SOURCE_DB_USER} -p$${SOURCE_DB_PASSWORD} -e \"show grants for '$${SOURCE_DB_REPLICA_USER}'@'%'\""

.PHONY: start-replica
start-replica: ## replica側でレプリケーションスタート
	@$(eval ALREADY_STARTED_REPL := $(shell docker compose run --rm mysql bash -c "mysql --connect-timeout=3 -h$${REPLICA_DB_HOST} -u$${SOURCE_DB_USER} -p$${SOURCE_DB_PASSWORD} -e \"show replica status\G\" | grep 'Replica_IO_Running: '"))
	@echo "$(ALREADY_STARTED_REPL)"
	@if [ "$(ALREADY_STARTED_REPL)" = "" ]; then docker compose run --rm mysql bash -c "mysql --connect-timeout=3 -h$${REPLICA_DB_HOST} -u$${SOURCE_DB_USER} -p$${SOURCE_DB_PASSWORD} -e \"CALL mysql.rds_set_external_source_with_auto_position('$${SOURCE_DB_WRITER}', 3306, '$${SOURCE_DB_REPLICA_USER}', '$${SOURCE_DB_REPLICA_PASSWORD}', 0);\""; fi
	@if [ "$(ALREADY_STARTED_REPL)" = "" ]; then docker compose run --rm mysql bash -c "mysql --connect-timeout=3 -h$${REPLICA_DB_HOST} -u$${SOURCE_DB_USER} -p$${SOURCE_DB_PASSWORD} -e \"CALL mysql.rds_start_replication;\""; fi

.PHONY: stop-replica
stop-replica: ## replica側でレプリケーションストップ
	@docker compose run --rm mysql bash -c "mysql --connect-timeout=3 -h$${REPLICA_DB_HOST} -u$${SOURCE_DB_USER} -p$${SOURCE_DB_PASSWORD} -e \"CALL mysql.rds_reset_external_source;\""

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
