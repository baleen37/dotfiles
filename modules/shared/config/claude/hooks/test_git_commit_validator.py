#!/usr/bin/env python3
"""
Test cases for git-commit-validator.py hook
Tests various scenarios to ensure proper detection of --no-verify flag
"""
import json
import subprocess
import sys
import tempfile
import os

def run_hook_test(tool_name, command, description=""):
    """Run the hook with given input and return exit code and stderr"""
    input_data = {
        "tool_name": tool_name,
        "tool_input": {
            "command": command,
            "description": description
        }
    }

    try:
        result = subprocess.run(
            [sys.executable, "git-commit-validator.py"],
            input=json.dumps(input_data),
            text=True,
            capture_output=True,
            cwd=os.path.dirname(__file__)
        )
        return result.returncode, result.stderr.strip()
    except Exception as e:
        return -1, str(e)

def test_cases():
    """Run all test cases"""
    tests = [
        # Should PASS (exit code 0)
        {
            "name": "Non-git command",
            "tool": "Bash",
            "command": "ls -la",
            "expected_exit": 0,
            "should_block": False
        },
        {
            "name": "Non-Bash tool",
            "tool": "Write",
            "command": "git commit --no-verify -m 'test'",
            "expected_exit": 0,
            "should_block": False
        },
        {
            "name": "Normal git commit",
            "tool": "Bash",
            "command": "git commit -m 'normal commit'",
            "expected_exit": 0,
            "should_block": False
        },
        {
            "name": "Git status command",
            "tool": "Bash",
            "command": "git status",
            "expected_exit": 0,
            "should_block": False
        },
        {
            "name": "Git commit with --no-verify in quoted message (should pass)",
            "tool": "Bash",
            "command": 'git commit -m "fix: remove --no-verify usage"',
            "expected_exit": 0,
            "should_block": False
        },
        {
            "name": "gh pr create with --no-verify in body (should pass)",
            "tool": "Bash",
            "command": 'gh pr create --title "Fix" --body "Remove --no-verify from docs"',
            "expected_exit": 0,
            "should_block": False
        },
        {
            "name": "gh pr with git commit --no-verify in body (should pass)",
            "tool": "Bash",
            "command": 'gh pr create --body "- [x] git commit --no-verify 차단 확인"',
            "expected_exit": 0,
            "should_block": False
        },
        {
            "name": "Complex heredoc with --no-verify (should pass)",
            "tool": "Bash",
            "command": """gh pr create --body "$(cat <<'EOF'
## Summary
Remove --no-verify usage from documentation
EOF
)" """,
            "expected_exit": 0,
            "should_block": False
        },

        # Should BLOCK (exit code 2)
        {
            "name": "Git commit with --no-verify flag",
            "tool": "Bash",
            "command": "git commit --no-verify -m 'test'",
            "expected_exit": 2,
            "should_block": True
        },
        {
            "name": "Git commit with --no-verify at end",
            "tool": "Bash",
            "command": "git commit -m 'test' --no-verify",
            "expected_exit": 2,
            "should_block": True
        },
        {
            "name": "Git commit with multiple flags including --no-verify",
            "tool": "Bash",
            "command": "git commit --author='Test' --no-verify -m 'test'",
            "expected_exit": 2,
            "should_block": True
        }
    ]

    passed = 0
    failed = 0

    print("🧪 Running git-commit-validator hook tests...\n")

    for test in tests:
        exit_code, stderr = run_hook_test(test["tool"], test["command"])

        success = exit_code == test["expected_exit"]

        if success:
            print(f"✅ {test['name']}")
            passed += 1
        else:
            print(f"❌ {test['name']}")
            print(f"   Expected exit code: {test['expected_exit']}, got: {exit_code}")
            if stderr:
                print(f"   Stderr: {stderr}")
            failed += 1

        # Additional validation for blocked commands
        if test["should_block"] and exit_code == 2:
            if "--no-verify flag detected" not in stderr:
                print(f"⚠️  Warning: Block message not found in stderr for {test['name']}")

    print(f"\n📊 Test Results: {passed} passed, {failed} failed")
    return failed == 0

def main():
    """Main test runner"""
    if not os.path.exists("git-commit-validator.py"):
        print("❌ git-commit-validator.py not found in current directory")
        sys.exit(1)

    success = test_cases()

    if success:
        print("\n🎉 All tests passed!")
        sys.exit(0)
    else:
        print("\n💥 Some tests failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()
