set -euo pipefail

command -v tmux > /dev/null 2>&1 || exit 0
states="$(tmux list-panes -a -F '#{@agent_status}' 2> /dev/null)" || exit 0

running=0
needs_input=0
ready=0
error=0

while IFS= read -r state; do
  case "$state" in
    running) ((running += 1)) ;;
    needs_input) ((needs_input += 1)) ;;
    ready) ((ready += 1)) ;;
    error) ((error += 1)) ;;
  esac
done <<< "$states"

parts=()
((running > 0)) && parts+=("●$running")
((needs_input > 0)) && parts+=("▲$needs_input")
((ready > 0)) && parts+=("○$ready")
((error > 0)) && parts+=("✕$error")

if ((${#parts[@]} > 0)); then
  printf '%s\n' "${parts[*]}"
fi
