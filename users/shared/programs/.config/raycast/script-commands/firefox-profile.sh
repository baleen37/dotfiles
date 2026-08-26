#!/bin/zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Firefox Profile
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName Firefox
# @raycast.icon 🦊
# @raycast.argument1 { "type": "text", "placeholder": "Profile name (optional)", "optional": true }

# Documentation:
# @raycast.description Open a Firefox profile by name, or open Firefox.

set -euo pipefail

firefox_binary=${FF_FIREFOX_BINARY:-/Applications/Firefox.app/Contents/MacOS/firefox}
launcher_path=${FF_FIREFOX_LAUNCHER:-${HOME}/.config/raycast/firefox-profile-launcher.zsh}
open_binary=${FF_OPEN_BINARY:-/usr/bin/open}
profile_name=${1:-}

[[ -x $firefox_binary ]] || {
  print -u2 -- "Firefox binary not found: $firefox_binary"
  exit 1
}

if [[ -z $profile_name ]]; then
  [[ -x $open_binary ]] || {
    print -u2 -- "macOS open binary not found: $open_binary"
    exit 1
  }
  "$open_binary" -a Firefox
  print -- "Opened Firefox"
  exit 0
fi

[[ -x $launcher_path ]] || {
  print -u2 -- "Firefox profile launcher not found: $launcher_path"
  exit 1
}

exec /bin/zsh "$launcher_path" "$profile_name"
