#!/bin/sh

set -eu

bundle_id='com.microsoft.VSCode'
canonical_app="${VSCODE_CANONICAL_APP:-/Applications/Visual Studio Code.app}"
lsregister="${VSCODE_LSREGISTER:-/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister}"
mdimport="${VSCODE_MDIMPORT:-/usr/bin/mdimport}"
osascript="${VSCODE_OSASCRIPT:-/usr/bin/osascript}"
plutil="${VSCODE_PLUTIL:-/usr/bin/plutil}"

fail() {
  echo "vscode-launchservices: $*" >&2
  exit 1
}

canonical_bundle_id() {
  "$plutil" -extract CFBundleIdentifier raw "$canonical_app/Contents/Info.plist"
}

validate_canonical_app() {
  [ -d "$canonical_app" ] || fail "canonical app is missing: $canonical_app"
  [ -f "$canonical_app/Contents/Info.plist" ] \
    || fail "canonical app has no Info.plist: $canonical_app"

  actual_bundle_id="$(canonical_bundle_id)" \
    || fail "cannot read canonical app bundle ID: $canonical_app"
  [ "$actual_bundle_id" = "$bundle_id" ] \
    || fail "canonical app bundle ID is $actual_bundle_id, expected $bundle_id: $canonical_app"
}

bundle_paths() {
  launchservices_dump="$("$lsregister" -dump 2> /dev/null)" \
    || fail "cannot read LaunchServices database"

  printf '%s\n' "$launchservices_dump" | awk -v expected_id="$bundle_id" '
    /^path:[[:space:]]+/ {
      path = $0
      sub(/^[^:]*:[[:space:]]*/, "", path)
      sub(/[[:space:]]+\(0x[[:xdigit:]]+\)$/, "", path)
      next
    }

    /^identifier:[[:space:]]+/ {
      identifier = $0
      sub(/^[^:]*:[[:space:]]*/, "", identifier)
      if (identifier == expected_id && path != "") print path
      path = ""
    }
  '
}

nix_bundle_paths_from() {
  printf '%s\n' "$1" | awk '/^\/nix\/store\/.*\/Visual Studio Code[.]app$/ { print }'
}

nix_bundle_paths() {
  paths="$(bundle_paths)" || return 1
  nix_bundle_paths_from "$paths"
}

representative_app() {
  "$osascript" -e 'POSIX path of (path to application id "com.microsoft.VSCode")' 2> /dev/null || true
}

audit() {
  validate_canonical_app

  representative="$(representative_app)"
  representative="${representative%/}"
  paths="$(bundle_paths)"
  nix_paths="$(nix_bundle_paths_from "$paths")"

  if printf '%s\n' "$paths" | grep -Fqx "$canonical_app"; then
    canonical_registered=yes
  else
    canonical_registered=no
  fi

  printf 'canonical=%s\n' "$canonical_app"
  printf 'canonical_bundle_id=%s\n' "$bundle_id"
  printf 'canonical_registered=%s\n' "$canonical_registered"
  if [ -n "$representative" ]; then
    printf 'representative=%s\n' "$representative"
  else
    printf 'representative=none\n'
  fi
  if [ -n "$nix_paths" ]; then
    printf '%s\n' "$nix_paths" | sed 's/^/nix_registered=/'
  else
    printf 'nix_registered=none\n'
  fi

  [ "$representative" = "$canonical_app" ] \
    || fail "LaunchServices representative is not the canonical app"
  [ "$canonical_registered" = yes ] \
    || fail "canonical app is not registered with LaunchServices"
  [ -z "$nix_paths" ] \
    || fail "Nix-store VS Code registrations remain"
}

repair() {
  validate_canonical_app

  nix_paths="$(nix_bundle_paths)"
  if [ -n "$nix_paths" ]; then
    printf '%s\n' "$nix_paths" | while IFS= read -r path; do
      echo "vscode-launchservices: unregistering $path" >&2
      "$lsregister" -u "$path"
    done
  fi

  echo "vscode-launchservices: registering $canonical_app" >&2
  "$lsregister" -f "$canonical_app"
  echo "vscode-launchservices: refreshing Spotlight metadata for $canonical_app" >&2
  "$mdimport" -i "$canonical_app"

  audit
}

case "${1:-}" in
  audit)
    audit
    ;;
  repair)
    repair
    ;;
  *)
    fail "usage: $0 {audit|repair}"
    ;;
esac
