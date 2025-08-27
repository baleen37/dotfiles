#!/usr/bin/python3
"""
Claude Code commit message cleaner
Removes Claude Code attribution from git commit messages after successful commits
"""
import json
import sys
import subprocess
import re
from typing import Dict, Any, Optional


def should_process_command(tool_name: str, command: str, tool_response: Dict[str, Any]) -> bool:
    """Check if the command should be processed by this hook."""
    if tool_name != "Bash":
        return False

    if not re.match(r"\s*git\s+commit\b", command):
        return False

    if not tool_response.get("success", True):
        return False

    return True


def get_current_commit_message() -> Optional[str]:
    """Get the current commit message from git."""
    try:
        result = subprocess.run(
            ["git", "log", "-1", "--pretty=format:%B"],
            capture_output=True,
            text=True,
            timeout=10
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except (subprocess.TimeoutExpired, subprocess.CalledProcessError, FileNotFoundError):
        pass
    return None


def clean_claude_attribution(message: str) -> tuple[str, bool]:
    """Remove Claude Code attribution from commit message.

    Returns:
        tuple: (cleaned_message, was_changed)
    """
    claude_patterns = [
        r'\n*🤖 Generated with \[Claude Code\]\(https://claude\.ai/code\)\n*',
        r'\n*Co-authored-by: Claude <noreply@anthropic\.com>\n*',
        r'\n*🤖 Generated with \[Claude Code\]\([^)]*\)\n*'  # Handle other Claude Code URLs
    ]

    cleaned_message = message
    changed = False

    # Remove each Claude Code pattern
    for pattern in claude_patterns:
        new_message = re.sub(pattern, '', cleaned_message, flags=re.MULTILINE)
        if new_message != cleaned_message:
            changed = True
            cleaned_message = new_message

    # Clean up extra whitespace
    cleaned_message = re.sub(r'\n{3,}', '\n\n', cleaned_message)
    cleaned_message = cleaned_message.rstrip('\n')

    return cleaned_message, changed


def amend_commit_message(message: str) -> bool:
    """Amend the current commit with a new message.

    Returns:
        bool: True if successful, False otherwise
    """
    try:
        result = subprocess.run(
            ["git", "commit", "--amend", "-m", message],
            capture_output=True,
            text=True,
            timeout=10
        )
        return result.returncode == 0
    except (subprocess.TimeoutExpired, subprocess.CalledProcessError, FileNotFoundError):
        return False


def main():
    """Main entry point for the Claude Code message cleaner hook."""
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON input: {e}", file=sys.stderr)
        sys.exit(1)

    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})
    tool_response = input_data.get("tool_response", {})
    command = tool_input.get("command", "")

    # Check if we should process this command
    if not should_process_command(tool_name, command, tool_response):
        sys.exit(0)

    # Get the current commit message
    current_message = get_current_commit_message()
    if current_message is None:
        sys.exit(0)

    # Clean the message
    cleaned_message, was_changed = clean_claude_attribution(current_message)

    # Only amend if the message actually changed
    if was_changed and cleaned_message != current_message:
        if amend_commit_message(cleaned_message):
            print("✓ Removed Claude Code attribution from commit message", file=sys.stderr)
        else:
            print("⚠️  Failed to clean commit message", file=sys.stderr)

    sys.exit(0)

if __name__ == "__main__":
    main()
