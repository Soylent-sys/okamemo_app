#!/bin/bash
set -e

# Rails用に存在する可能性のあるserver.pidを削除する。
rm -f /okamemo_app/tmp/pids/server.pid
# createとseedは初回デプロイ時にrailsコンテナにexecute-commandで接続して実行する。
bundle exec rails db:migrate

# コンテナのメインプロセス（DockerfileでCMDと設定されているもの）を実行する。
exec "$@"
