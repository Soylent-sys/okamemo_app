#!/bin/bash
set -e

# Rails用に存在する可能性のあるserver.pidを削除する。
rm -f /okamemo_app/tmp/pids/server.pid
# WARNING:createとseedはfargateの初回起動時のみ実行
# bundle exec rails db:create
bundle exec rails db:migrate
# bundle exec rails db:seed

# コンテナのメインプロセス（DockerfileでCMDと設定されているもの）を実行する。
exec "$@"
