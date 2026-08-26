#!/bin/zsh

set -euo pipefail

firefox_data_dir=${FF_FIREFOX_DATA_DIR:-${HOME}/Library/Application Support/Firefox}
firefox_binary=${FF_FIREFOX_BINARY:-/Applications/Firefox.app/Contents/MacOS/firefox}
sqlite_binary=${FF_SQLITE3_BINARY:-/usr/bin/sqlite3}
lsof_binary=${FF_LSOF_BINARY:-/usr/sbin/lsof}
ps_binary=${FF_PS_BINARY:-/bin/ps}
activate_binary=${FF_FIREFOX_ACTIVATE_BINARY:-${HOME}/.config/raycast/firefox-profile-activate}
nohup_binary=${FF_NOHUP_BINARY:-/usr/bin/nohup}
profile_selector=${1:?profile name or path is required}
profile_name=$profile_selector
profile_name_lower=${profile_name:l}
profiles_ini="$firefox_data_dir/profiles.ini"

typeset -A profile_is_relative profile_paths profile_names
section=""
store_id=""

if [[ $profile_selector != /* || ! -d $profile_selector ]] && [[ -r $profiles_ini ]]; then
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

resolve_path() {
  local path=$1
  if [[ $path == /* ]]; then
    print -r -- "$path"
  else
    print -r -- "$firefox_data_dir/$path"
  fi
}

group_database() {
  [[ -n $store_id ]] || return 1
  print -r -- "$firefox_data_dir/Profile Groups/${store_id}.sqlite"
}

group_rows() {
  local database
  database=$(group_database) || return 1
  [[ -r $database && -x $sqlite_binary ]] || return 1

  "$sqlite_binary" \
    -readonly \
    -noheader \
    -separator $'\t' \
    "$database" \
    'SELECT name, path FROM Profiles ORDER BY name COLLATE NOCASE, id;' \
    2> /dev/null
}

list_group_profiles() {
  local rows name relative_path path
  rows=$(group_rows) || return 1

  while IFS=$'\t' read -r name relative_path; do
    [[ -n $name && -n $relative_path ]] || continue
    path=$(resolve_path "$relative_path")
    [[ -d $path ]] || continue
    print -r -- "$name"
  done <<< "$rows"
}

list_group_profile_rows() {
  local rows name relative_path path
  rows=$(group_rows) || return 1

  while IFS=$'\t' read -r name relative_path; do
    [[ -n $name && -n $relative_path ]] || continue
    path=$(resolve_path "$relative_path")
    [[ -d $path ]] || continue
    print -r -- "$name"$'\t'"$path"
  done <<< "$rows"
}

list_legacy_profiles() {
  local -i index=0
  local profile_section name path is_relative

  while true; do
    profile_section="Profile${index}"
    [[ -n ${profile_paths[$profile_section]-} ]] || break

    name=${profile_names[$profile_section]-}
    path=${profile_paths[$profile_section]-}
    is_relative=${profile_is_relative[$profile_section]-}

    if [[ -n $name && -n $path ]]; then
      [[ $is_relative == 1 ]] && path=$(resolve_path "$path")
      [[ $path == /* && -d $path ]] && print -r -- "$name"
    fi

    ((index += 1))
  done
}

list_legacy_profile_rows() {
  local -i index=0
  local profile_section name path is_relative

  while true; do
    profile_section="Profile${index}"
    [[ -n ${profile_paths[$profile_section]-} ]] || break

    name=${profile_names[$profile_section]-}
    path=${profile_paths[$profile_section]-}
    is_relative=${profile_is_relative[$profile_section]-}

    if [[ -n $name && -n $path ]]; then
      [[ $is_relative == 1 ]] && path=$(resolve_path "$path")
      [[ $path == /* && -d $path ]] && print -r -- "$name"$'\t'"$path"
    fi

    ((index += 1))
  done
}

list_profiles() {
  local grouped
  grouped=$(list_group_profiles 2> /dev/null) || grouped=""
  if [[ -n $grouped ]]; then
    print -r -- "$grouped"
  else
    list_legacy_profiles
  fi
}

list_profile_rows() {
  local grouped
  grouped=$(list_group_profile_rows 2> /dev/null) || grouped=""
  if [[ -n $grouped ]]; then
    print -r -- "$grouped"
  else
    list_legacy_profile_rows
  fi
}

find_group_profile() {
  local rows name relative_path path
  rows=$(group_rows) || return 1

  while IFS=$'\t' read -r name relative_path; do
    [[ ${name:l} == "$profile_name_lower" && -n $relative_path ]] || continue
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

    if [[ ${name:l} == "$profile_name_lower" && -n $path ]]; then
      [[ $is_relative == 1 ]] && path=$(resolve_path "$path")
      [[ $path == /* && -d $path ]] || return 1
      print -r -- "$path"
      return 0
    fi

    ((index += 1))
  done

  return 1
}

profile_pid_from_ps() {
  local profile_path=$1
  [[ -x $ps_binary ]] || return 1

  "$ps_binary" -axo pid=,command= 2> /dev/null |
    awk -v profile_path="$profile_path" '
      index($0, profile_path) && tolower($0) ~ /\/firefox([[:space:]]|$)/ {
        print $1
        exit
      }
    '
}

profile_pid_from_lsof() {
  local profile_path=$1
  [[ -x $lsof_binary && -r $profile_path/.parentlock ]] || return 1

  "$lsof_binary" -t -- "$profile_path/.parentlock" 2> /dev/null | awk 'NF { print; exit }'
}

activate_profile_process() {
  local profile_pid=$1

  [[ -x $activate_binary ]] || {
    print -u2 -- "Firefox activation helper not found: $activate_binary"
    return 1
  }

  "$activate_binary" "$profile_pid"
}

if [[ $profile_selector == --list ]]; then
  list_profiles
  exit 0
fi

if [[ $profile_selector == --list-paths ]]; then
  list_profile_rows
  exit 0
fi

[[ -x $firefox_binary ]] || {
  print -u2 -- "Firefox binary not found: $firefox_binary"
  exit 1
}

launch_firefox() {
  [[ -x $nohup_binary ]] || {
    print -u2 -- "nohup binary not found: $nohup_binary"
    return 1
  }

  "$nohup_binary" "$firefox_binary" "$@" > /dev/null 2>&1 &
}

if [[ $profile_selector == /* && -d $profile_selector ]]; then
  profile_path=$profile_selector
  profile_name=${profile_path:t}
else
  profile_name=$profile_selector
  profile_path=$(find_group_profile || find_legacy_profile) || {
    print -u2 -- "Firefox profile not found: $profile_name"
    exit 1
  }
fi

profile_pid=$(profile_pid_from_ps "$profile_path") || profile_pid=""
if [[ -z $profile_pid ]]; then
  profile_pid=$(profile_pid_from_lsof "$profile_path") || profile_pid=""
fi

if [[ -n $profile_pid ]]; then
  activate_profile_process "$profile_pid"
  print -- "Focused Firefox profile: $profile_name"
  exit 0
fi

launch_firefox --profile "$profile_path"
print -- "Opened Firefox profile: $profile_name"
