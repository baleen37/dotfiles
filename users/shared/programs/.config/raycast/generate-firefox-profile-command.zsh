#!/bin/zsh

set -euo pipefail

output_path=${1:?output path is required}
launcher_path=${FF_FIREFOX_LAUNCHER:-${HOME}/.config/raycast/firefox-profile-launcher.zsh}
zsh_binary=${FF_ZSH_BINARY:-/bin/zsh}
output_directory=${output_path:h}
temporary_path="${output_path}.tmp.$$"

mkdir -p "$output_directory"

typeset -a profile_names profile_paths
typeset -A seen_profiles
profile_names=()
profile_paths=()

if [[ -r $launcher_path ]]; then
  while IFS=$'\t' read -r profile_name profile_path; do
    [[ -n $profile_name && -n $profile_path && -z ${seen_profiles[$profile_name]-} ]] || continue
    seen_profiles[$profile_name]=1
    profile_names+=("$profile_name")
    profile_paths+=("$profile_path")
  done < <("$zsh_binary" "$launcher_path" --list-paths)
fi

json_quote() {
  local value=$1
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$'\n'/\\n}
  value=${value//$'\r'/\\r}
  value=${value//$'\t'/\\t}
  print -rn -- "\"$value\""
}

{
  print '#!/bin/zsh'
  print ''
  print '# Required parameters:'
  print '# @raycast.schemaVersion 1'
  print '# @raycast.title Firefox Profiles'
  print '# @raycast.mode silent'
  print ''
  print '# Optional parameters:'
  print '# @raycast.packageName Firefox'
  print '# @raycast.icon 🦊'

  dropdown_argument='{ "type": "dropdown", "placeholder": "Profile", "data": ['
  first_entry=1
  for ((index = 1; index <= ${#profile_names[@]}; index += 1)); do
    profile_name=${profile_names[$index]}
    profile_path=${profile_paths[$index]}
    quoted_name=$(json_quote "$profile_name")
    quoted_path=$(json_quote "$profile_path")
    (( first_entry )) || dropdown_argument+=', '
    dropdown_argument+="{ \"title\": $quoted_name, \"value\": $quoted_path }"
    first_entry=0
  done

  dropdown_argument+=' ] }'
  print -r -- "# @raycast.argument1 $dropdown_argument"
  print ''
  print '# Documentation:'
  print '# @raycast.description Focus an existing Firefox profile.'
  print ''
  print 'set -euo pipefail'
  # shellcheck disable=SC2016
  print 'launcher="${HOME}/.config/raycast/firefox-profile-launcher.zsh"'
  # shellcheck disable=SC2016
  print 'exec /bin/zsh "$launcher" "$1"'
} > "$temporary_path"

chmod +x "$temporary_path"
mv -f "$temporary_path" "$output_path"
