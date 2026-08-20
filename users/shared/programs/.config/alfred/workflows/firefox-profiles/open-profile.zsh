#!/bin/zsh
set -euo pipefail

firefox_binary=${FF_FIREFOX_BINARY:-/Applications/Firefox.app/Contents/MacOS/firefox}

[[ -x "$firefox_binary" ]] || {
  print -u2 -- "Firefox binary not found: $firefox_binary"
  exit 1
}

launch_firefox() {
  /usr/bin/nohup "$firefox_binary" "$@" >/dev/null 2>&1 &
}

if (( $# == 0 )); then
  launch_firefox --no-remote --ProfileManager
elif (( $# == 1 )); then
  launch_firefox --no-remote -P "$1"
else
  print -u2 -- "expected zero or one Firefox profile name"
  exit 2
fi
