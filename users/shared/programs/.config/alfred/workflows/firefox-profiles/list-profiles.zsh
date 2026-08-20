#!/bin/zsh
set -euo pipefail

firefox_data_dir=${FF_FIREFOX_DATA_DIR:-${HOME}/Library/Application Support/Firefox}
profiles_ini="$firefox_data_dir/profiles.ini"
sqlite_binary=${FF_SQLITE3_BINARY:-/usr/bin/sqlite3}

# New Firefox profiles live in a read-only profile-group database; legacy installs
# continue to use profiles.ini below.
typeset -A profile_is_relative profile_paths profile_names
typeset -a selected_names=() selected_paths=()
section=""
store_id=""

is_profile_section() {
  [[ "$1" =~ ^Profile[0-9]+$ ]]
}

if [[ -r "$profiles_ini" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    line=${line%$'\r'}
    case "$line" in
      \[*\])
        section=${line#\[}
        section=${section%\]}
        ;;
      IsRelative=*)
        if is_profile_section "$section"; then
          profile_is_relative[$section]=${line#IsRelative=}
        fi
        ;;
      Path=*)
        if is_profile_section "$section"; then
          profile_paths[$section]=${line#Path=}
        fi
        ;;
      Name=*)
        if is_profile_section "$section"; then
          profile_names[$section]=${line#Name=}
        fi
        ;;
      StoreID=*)
        if is_profile_section "$section" && [[ -z "$store_id" ]]; then
          store_id=${line#StoreID=}
        fi
        ;;
    esac
  done < "$profiles_ini"
fi

add_profile() {
  local name=$1
  local path=$2

  [[ -n "$name" && -d "$path" ]] || return
  selected_names+=("$name")
  selected_paths+=("$path")
}

load_selectable_profiles() {
  local store_id=$1
  local database="$firefox_data_dir/Profile Groups/${store_id}.sqlite"
  local rows name relative_path path

  [[ -r "$database" && -x "$sqlite_binary" ]] || return 1

  rows=$(
    "$sqlite_binary" \
      -readonly \
      -noheader \
      -separator $'\t' \
      "$database" \
      'SELECT name, path FROM Profiles ORDER BY name COLLATE NOCASE, id;' \
      2>/dev/null
  ) || return 1

  [[ -n "$rows" ]] || return 1

  while IFS=$'\t' read -r name relative_path; do
    [[ -n "$name" && -n "$relative_path" ]] || continue

    if [[ "$relative_path" == /* ]]; then
      path=$relative_path
    else
      path="$firefox_data_dir/$relative_path"
    fi

    add_profile "$name" "$path"
  done <<< "$rows"

  (( ${#selected_names[@]} > 0 ))
}

load_legacy_profiles() {
  local -i index=0
  local profile_section is_relative name path

  while true; do
    profile_section="Profile${index}"
    [[ -n ${profile_is_relative[$profile_section]-} ]] || break

    name=${profile_names[$profile_section]-}
    path=${profile_paths[$profile_section]-}
    is_relative=${profile_is_relative[$profile_section]-}

    if [[ -n "$name" && -n "$path" ]]; then
      if [[ "$is_relative" == 1 ]]; then
        path="$firefox_data_dir/$path"
      elif [[ "$path" != /* ]]; then
        path=""
      fi

      add_profile "$name" "$path"
    fi

    (( index += 1 ))
  done
}

if [[ -n "$store_id" ]]; then
  load_selectable_profiles "$store_id" || load_legacy_profiles
else
  load_legacy_profiles
fi

json_escape() {
  local value=$1
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$'\n'/\\n}
  value=${value//$'\r'/\\r}
  value=${value//$'\t'/\\t}
  print -rn -- "$value"
}

print -rn -- '{"items":['
separator=""
integer index=0
for (( index = 1; index <= ${#selected_names[@]}; index++ )); do
  profile_name=${selected_names[index]}
  profile_path=${selected_paths[index]}
  print -rn -- "${separator}{\"title\":\""
  json_escape "$profile_name"
  print -rn -- '","subtitle":"Open Firefox with this profile","arg":"'
  json_escape "$profile_path"
  print -rn -- '"}'
  separator=","
done

if (( ${#selected_names[@]} == 0 )); then
  print -rn -- '{"title":"Open Firefox Profile Manager","subtitle":"No registered Firefox profiles found","arg":""}'
fi

print -r -- ']}'
