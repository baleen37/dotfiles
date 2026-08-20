#!/bin/zsh
set -euo pipefail

profiles_ini="${HOME}/Library/Application Support/Firefox/profiles.ini"
typeset -A profile_is_relative profile_paths profile_names
section=""

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
    esac
  done < "$profiles_ini"
fi

typeset -a profiles=()
integer index=0
while true; do
  profile_section="Profile${index}"
  [[ -n ${profile_is_relative[$profile_section]-} ]] || break

  if [[ -n ${profile_paths[$profile_section]-} && -n ${profile_names[$profile_section]-} ]]; then
    profiles+=("${profile_names[$profile_section]}")
  fi

  (( index += 1 ))
done

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
for profile_name in "${profiles[@]}"; do
  print -rn -- "${separator}{\"title\":\""
  json_escape "$profile_name"
  print -rn -- '","subtitle":"Open Firefox with this profile","arg":"'
  json_escape "$profile_name"
  print -rn -- '"}'
  separator=","
done

if (( ${#profiles[@]} == 0 )); then
  print -rn -- '{"title":"Open Firefox Profile Manager","subtitle":"No registered Firefox profiles found","arg":""}'
fi

print -r -- ']}'
