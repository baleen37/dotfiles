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
    print("⚠️  --no-verify flag detected.", file=sys.stderr)
    print("Pre-commit hooks are important for code quality.", file=sys.stderr)
    print("Try these alternatives instead:", file=sys.stderr)
    print("1. Fix pre-commit errors and commit normally", file=sys.stderr)
    print("2. Skip specific hooks: SKIP=ruff git commit -m '...'", file=sys.stderr)
    print("3. Run manually in terminal if absolutely necessary", file=sys.stderr)

    # Exit code 2 blocks the command and shows stderr to Claude
    sys.exit(2)

# Allow the command to proceed
sys.exit(0)
