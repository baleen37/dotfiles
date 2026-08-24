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
# @raycast.description Open a Firefox profile by name, or open Profile Manager.

set -euo pipefail

firefox_data_dir=${FF_FIREFOX_DATA_DIR:-${HOME}/Library/Application Support/Firefox}
firefox_binary=${FF_FIREFOX_BINARY:-/Applications/Firefox.app/Contents/MacOS/firefox}
sqlite_binary=${FF_SQLITE3_BINARY:-/usr/bin/sqlite3}
nohup_binary=${FF_NOHUP_BINARY:-/usr/bin/nohup}
profile_name=${1:-}
profiles_ini="$firefox_data_dir/profiles.ini"

[[ -x $firefox_binary ]] || {
  print -u2 -- "Firefox binary not found: $firefox_binary"
  exit 1
}

typeset -A profile_is_relative profile_paths profile_names
section=""
store_id=""

if [[ -r $profiles_ini ]]; then
  while IFS= read -r line || [[ -n $line ]]; do
    line=${line%$'\r'}
    case "$line" in
      \[*\])
        section=${line#\[}
        section=${section%\]}
        ;;
      IsRelative=*)
        [[ $section == Profile[0-9]* ]] && profile_is_relative[$section]=${line#IsRelative=}
        ;;
      Path=*)
        [[ $section == Profile[0-9]* ]] && profile_paths[$section]=${line#Path=}
        ;;
      Name=*)
        [[ $section == Profile[0-9]* ]] && profile_names[$section]=${line#Name=}
        ;;
      StoreID=*)
        [[ $section == Profile[0-9]* && -z $store_id ]] && store_id=${line#StoreID=}
        ;;
    esac
  done < "$profiles_ini"
fi

launch_firefox() {
  "$nohup_binary" "$firefox_binary" "$@" > /dev/null 2>&1 &
}

if [[ -z $profile_name ]]; then
  launch_firefox --no-remote --ProfileManager
  print -- "Opened Firefox Profile Manager"
  exit 0
fi

resolve_path() {
  local path=$1
  if [[ $path == /* ]]; then
    print -r -- "$path"
  else
    print -r -- "$firefox_data_dir/$path"
  fi
}

find_group_profile() {
  local database rows name relative_path path

  [[ -n $store_id ]] || return 1
  database="$firefox_data_dir/Profile Groups/${store_id}.sqlite"
  [[ -r $database && -x $sqlite_binary ]] || return 1

  rows=$(
    "$sqlite_binary" \
      -readonly \
      -noheader \
      -separator $'\t' \
      "$database" \
      'SELECT name, path FROM Profiles ORDER BY name COLLATE NOCASE, id;' \
      2> /dev/null
  ) || return 1

  while IFS=$'\t' read -r name relative_path; do
    [[ $name == "$profile_name" && -n $relative_path ]] || continue
    path=$(resolve_path "$relative_path")
    [[ -d $path ]] || return 1
    print -r -- "$path"
    return 0
  done <<< "$rows"

  return 1
}

find_legacy_profile() {
  local -i index=0
  local profile_section name path is_relative

  while true; do
    profile_section="Profile${index}"
    [[ -n ${profile_paths[$profile_section]-} ]] || break

    name=${profile_names[$profile_section]-}
    path=${profile_paths[$profile_section]-}
    is_relative=${profile_is_relative[$profile_section]-}

    if [[ $name == "$profile_name" && -n $path ]]; then
      [[ $is_relative == 1 ]] && path=$(resolve_path "$path")
      [[ $path == /* && -d $path ]] || return 1
      print -r -- "$path"
      return 0
    fi

    ((index += 1))
  done

  return 1
}

profile_path=$(find_group_profile || find_legacy_profile) || {
  print -u2 -- "Firefox profile not found: $profile_name"
  exit 1
}

launch_firefox --no-remote --profile "$profile_path"
print -- "Opened Firefox profile: $profile_name"
