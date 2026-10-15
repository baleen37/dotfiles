#!/usr/bin/env bash

# Spliced into nix-darwin activation, which runs under `set -e` and
# `set -o pipefail`; keep the same options so a failure aborts the switch exactly
# as it did when this was inline.
set -eo pipefail

applications_dir="${DARWIN_ACTIVATION_APPLICATIONS_DIR:-/Applications}"
mdutil="${DARWIN_ACTIVATION_MDUTIL:-/usr/bin/mdutil}"
mdls="${DARWIN_ACTIVATION_MDLS:-/usr/bin/mdls}"
mdimport="${DARWIN_ACTIVATION_MDIMPORT:-/usr/bin/mdimport}"
systemsetup="${DARWIN_ACTIVATION_SYSTEMSETUP:-/usr/sbin/systemsetup}"

fail() {
  echo "darwin-activation: $*" >&2
  exit 1
}

# mas uses Spotlight metadata to find installed Mac App Store apps. Keep the
# index enabled for the root volume and import the configured apps when their
# Adam ID is not available yet.
spotlight() {
  spotlight_status=$("$mdutil" -s / 2> /dev/null || true)
  if echo "$spotlight_status" | grep -qi "disabled"; then
    echo "Enabling Spotlight indexing for App Store app detection..." >&2
    "$mdutil" -E -i on / >&2 || true
  fi

  app="$applications_dir/KakaoTalk.app"
  adam_id=$("$mdls" -raw -name kMDItemAppStoreAdamID "$app" 2> /dev/null || true)
  if [ -d "$app" ] && { [ -z "$adam_id" ] || [ "$adam_id" = "(null)" ]; }; then
    "$mdimport" "$app" 2> /dev/null || true
  fi
}

# Enables macOS Remote Login so the machine accepts incoming SSH connections.
# nix-darwin has no dedicated option for this, so we toggle it via systemsetup.
# Idempotent: only flips the setting when it is currently off.
remote_login() {
  echo "Enabling Remote Login (SSH)..." >&2

  if "$systemsetup" -getremotelogin 2> /dev/null | grep -q "On"; then
    echo "  ✓  Remote Login already enabled" >&2
  else
    "$systemsetup" -setremotelogin -f on >&2
    echo "  Remote Login enabled" >&2
  fi
}

# Automated storage optimization through removal of unused default macOS applications
# Saves 6-8GB of storage space and reduces system resource consumption
app_cleanup() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "Removing unused macOS default apps..." >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2

  # 제거할 앱 목록
  apps=(
    "GarageBand.app"
    "iMovie.app"
    "TV.app"
    "Podcasts.app"
    "News.app"
    "Stocks.app"
    "Freeform.app"
  )

  removed_count=0
  skipped_count=0

  for app in "${apps[@]}"; do
    app_path="$applications_dir/$app"

    if [ -e "$app_path" ]; then
      echo "  Removing: $app" >&2

      # activation already runs as root, so no sudo needed; SIP still wins
      if rm -rf "$app_path" 2> /dev/null; then
        removed_count=$((removed_count + 1))
      else
        echo "     Failed to remove (SIP protected): $app" >&2
        skipped_count=$((skipped_count + 1))
      fi
    else
      echo "  ✓  Already removed: $app" >&2
    fi
  done

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "Cleanup complete!" >&2
  echo "   - Removed: $removed_count apps" >&2
  echo "   - Skipped: $skipped_count apps (protected)" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
}

case "${1:-}" in
  spotlight)
    spotlight
    ;;
  remote-login)
    remote_login
    ;;
  app-cleanup)
    app_cleanup
    ;;
  *)
    fail "usage: $0 {spotlight|remote-login|app-cleanup}"
    ;;
esac
