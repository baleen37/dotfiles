#!/usr/bin/env bash
# Exercise the public statusline command with isolated, deterministic inputs.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATUSLINE_SCRIPT="$SCRIPT_DIR/../users/shared/programs/.config/claude/statusline.sh"
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/bin" "$fixture/workspace"
# Keep the smoke test independent of the user's Claude login and Git checkout.
printf '#!/bin/sh\nexit 1\n' > "$fixture/bin/claude"
chmod +x "$fixture/bin/claude"
export PATH="$fixture/bin:$PATH"
: > "$fixture/empty.jsonl"
printf '%s\n' '{"message":{"usage":{"input_tokens":99999}},"isSidechain":false}' > "$fixture/transcript.jsonl"

check() {
  local description=$1 expected_context=$2 input=$3 output plain expected
  input=$(printf '%s\n' "$input" | jq --arg dir "$fixture/workspace" '
    .model.display_name = "Test Model" | .workspace.current_dir = $dir
  ')
  output=$(printf '%s\n' "$input" | bash "$STATUSLINE_SCRIPT")
  plain=$(printf '%s\n' "$output" | sed -E $'s/\033\\[[0-9;]*m//g')
  expected="Test Model │ $fixture/workspace"
  if [ -n "$expected_context" ]; then
    expected="Test Model │ $expected_context │ $fixture/workspace"
  fi
  if [ "$plain" != "$expected" ]; then
    printf 'FAIL: %s\nExpected: %s\nActual: %s\n' "$description" "$expected" "$plain" >&2
    exit 1
  fi
  printf 'PASS: %s\n' "$description"
}

check "total input tokens" "1k" '{"context_window":{"total_input_tokens":1000,"total_output_tokens":100}}'
check "missing transcript" "2k" '{"context_window":{"total_input_tokens":2000},"transcript_path":"/nonexistent/file.jsonl"}'
check "current usage takes priority and excludes output tokens" "1k" '{"context_window":{"total_input_tokens":9000,"current_usage":{"input_tokens":1000,"output_tokens":200,"cache_read_input_tokens":400,"cache_creation_input_tokens":200}}}'
check "transcript alone does not supply context" "" "$(jq -n --arg file "$fixture/transcript.jsonl" '{transcript_path:$file}')"
check "empty transcript uses total input" "3k" "$(jq -n --arg file "$fixture/empty.jsonl" '{context_window:{total_input_tokens:3000},transcript_path:$file}')"
check "percentage alone does not supply context" "" '{"context_window":{"used_percentage":25.5,"context_window_size":200000}}'
check "large percentage alone does not supply context" "" '{"context_window":{"used_percentage":80,"context_window_size":2000000}}'
check "null values hide context" "" '{"context_window":{"current_usage":null,"total_input_tokens":null,"used_percentage":null}}'
check "zero tokens hide context" "" '{"context_window":{"current_usage":{"input_tokens":0,"cache_read_input_tokens":0,"cache_creation_input_tokens":0}}}'
check "zero usage falls back to total input" "50k" '{"context_window":{"total_input_tokens":50000,"current_usage":{"input_tokens":0}}}'

echo "All 10 statusline smoke scenarios passed."
