#!/usr/bin/env bash
set -euo pipefail
set +x

if ! command -v python3 > /dev/null; then
  for argument in "$@"; do
    case "$argument" in
      --check | --help | -h)
        echo 'python3 is required to inspect the declaration; no changes were made.' >&2
        exit 1
        ;;
    esac
  done
  privileged=()
  if [ "$EUID" -ne 0 ]; then
    privileged=(sudo)
  fi
  "${privileged[@]}" apt-get update
  "${privileged[@]}" apt-get install -y python3 ca-certificates
fi
exec python3 "$(dirname "${BASH_SOURCE[0]}")/apply.py" "$@"
