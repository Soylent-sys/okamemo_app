#!/bin/bash
set -e

# Rails用に存在する可能性のあるserver.pidを削除する。
rm -f /okamemo_app/tmp/pids/server.pid
# DB構築前はdb:setupが実行され、DB構築後はdb:migrateのみ実行する
bundle exec rails db:prepare

# コンテナのメインプロセス（DockerfileでCMDと設定されているもの）を実行する。
exec "$@"
