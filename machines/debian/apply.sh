#!/usr/bin/env bash
set -euo pipefail
set +x

case "$*" in
  bootstrap | switch | 'switch --build') ;;
  *)
    echo 'Usage: apply.sh bootstrap | switch [--build]' >&2
    exit 2
    ;;
esac
if ! command -v python3 > /dev/null; then
  if [ "$1" != bootstrap ]; then
    echo 'python3 is missing: run ./bootstrap.sh; no changes were made.' >&2
    exit 1
  fi
  sudo -- apt-get update
  sudo -- apt-get install -y python3 ca-certificates
fi
exec python3 "$(dirname "${BASH_SOURCE[0]}")/apply.py" "$@"
