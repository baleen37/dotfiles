#!/usr/bin/env python3
"""
Git commit validator hook for Claude Code
Prevents use of --no-verify flag by intercepting git commit commands
"""
import json
import sys
import re

try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError as e:
    print(f"Error: Invalid JSON input: {e}", file=sys.stderr)
    sys.exit(1)

tool_name = input_data.get("tool_name", "")
tool_input = input_data.get("tool_input", {})
command = tool_input.get("command", "")

# Only process Bash tool with git commit commands
if tool_name != "Bash":
    sys.exit(0)

# Check if this is a git commit command
if not re.search(r"\bgit\s+commit\b", command):
    sys.exit(0)

# Check for --no-verify flag
if re.search(r"--no-verify", command):
    print("⚠️  --no-verify 플래그 사용이 감지되었습니다.", file=sys.stderr)
    print("pre-commit hooks는 코드 품질을 보장하기 위해 중요합니다.", file=sys.stderr)
    print("대신 다음을 시도해보세요:", file=sys.stderr)
    print("1. pre-commit 오류를 수정하여 정상적으로 커밋", file=sys.stderr)
    print("2. 특정 hook만 건너뛰기: SKIP=ruff git commit -m '...'", file=sys.stderr)
    print("3. 정말 필요한 경우 수동으로 터미널에서 실행", file=sys.stderr)
    
    # Exit code 2 blocks the command and shows stderr to Claude
    sys.exit(2)

# Allow the command to proceed
sys.exit(0)