#!/bin/bash
set -e

# Rails用に存在する可能性のあるserver.pidを削除する。
rm -f /okamemo_app/tmp/pids/server.pid

# コンテナのメインプロセス（DockerfileでCMDと設定されているもの）を実行する。
exec "$@"
