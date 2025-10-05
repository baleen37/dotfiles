#!/usr/bin/env python3
"""
Test suite for git-commit-validator hook

Tests the validation logic that prevents use of --no-verify flag
"""
import json
import sys
import unittest
from io import StringIO
from pathlib import Path
from unittest.mock import patch

# Add the hooks directory to Python path
repo_root = Path(__file__).parent.parent.parent.parent
hooks_dir = repo_root / "modules" / "shared" / "config" / "claude" / "hooks"
sys.path.insert(0, str(hooks_dir))


class TestGitCommitValidator(unittest.TestCase):
    """Test cases for git-commit-validator hook"""

    def test_should_block_no_verify_flag(self):
        """Test that --no-verify flag is blocked"""
        hook_input = {
            "tool_name": "Bash",
            "tool_input": {"command": "git commit --no-verify -m 'test'"},
        }

        with patch("sys.stdin", StringIO(json.dumps(hook_input))):
            with patch("sys.stderr", new_callable=StringIO) as mock_stderr:
                with self.assertRaises(SystemExit) as cm:
                    with open(hooks_dir / "git-commit-validator.py") as f:
                        exec(f.read())

                # Should exit with code 2 (block)
                self.assertEqual(cm.exception.code, 2)

                # Should print warning message
                stderr_output = mock_stderr.getvalue()
                self.assertIn("--no-verify", stderr_output)

    def test_should_allow_normal_git_commit(self):
        """Test that normal git commit commands pass through"""
        hook_input = {
            "tool_name": "Bash",
            "tool_input": {"command": "git commit -m 'normal commit'"},
        }

        with patch("sys.stdin", StringIO(json.dumps(hook_input))):
            with self.assertRaises(SystemExit) as cm:
                with open(hooks_dir / "git-commit-validator.py") as f:
                    exec(f.read())

            # Should exit with code 0 (allow)
            self.assertEqual(cm.exception.code, 0)

    def test_should_ignore_quoted_no_verify(self):
        """Test that --no-verify inside quotes is ignored"""
        hook_input = {
            "tool_name": "Bash",
            "tool_input": {
                "command": 'git commit -m "message about --no-verify flag"'
            },
        }

        with patch("sys.stdin", StringIO(json.dumps(hook_input))):
            with self.assertRaises(SystemExit) as cm:
                with open(hooks_dir / "git-commit-validator.py") as f:
                    exec(f.read())

            # Should exit with code 0 (allow)
            self.assertEqual(cm.exception.code, 0)

    def test_should_pass_non_bash_tools(self):
        """Test that non-Bash tools are not processed"""
        hook_input = {
            "tool_name": "Write",
            "tool_input": {"file_path": "test.py", "content": "print('hello')"},
        }

        with patch("sys.stdin", StringIO(json.dumps(hook_input))):
            with self.assertRaises(SystemExit) as cm:
                with open(hooks_dir / "git-commit-validator.py") as f:
                    exec(f.read())

            # Should exit with code 0 (pass through)
            self.assertEqual(cm.exception.code, 0)

    def test_should_pass_non_git_commands(self):
        """Test that non-git commands are not processed"""
        hook_input = {
            "tool_name": "Bash",
            "tool_input": {"command": "ls -la"},
        }

        with patch("sys.stdin", StringIO(json.dumps(hook_input))):
            with self.assertRaises(SystemExit) as cm:
                with open(hooks_dir / "git-commit-validator.py") as f:
                    exec(f.read())

            # Should exit with code 0 (pass through)
            self.assertEqual(cm.exception.code, 0)

    def test_should_handle_invalid_json(self):
        """Test that invalid JSON input is handled gracefully"""
        with patch("sys.stdin", StringIO("{ invalid json")):
            with patch("sys.stderr", new_callable=StringIO) as mock_stderr:
                with self.assertRaises(SystemExit) as cm:
                    with open(hooks_dir / "git-commit-validator.py") as f:
                        exec(f.read())

                # Should exit with code 1 (error)
                self.assertEqual(cm.exception.code, 1)

                # Should print error message
                stderr_output = mock_stderr.getvalue()
                self.assertIn("Invalid JSON", stderr_output)

    def test_should_block_no_verify_with_multiple_flags(self):
        """Test blocking --no-verify when combined with other flags"""
        hook_input = {
            "tool_name": "Bash",
            "tool_input": {"command": "git commit -a --no-verify -m 'test'"},
        }

        with patch("sys.stdin", StringIO(json.dumps(hook_input))):
            with patch("sys.stderr", new_callable=StringIO):
                with self.assertRaises(SystemExit) as cm:
                    with open(hooks_dir / "git-commit-validator.py") as f:
                        exec(f.read())

                # Should exit with code 2 (block)
                self.assertEqual(cm.exception.code, 2)

    def test_should_handle_git_commit_with_heredoc(self):
        """Test that git commit with heredoc message passes (no --no-verify)"""
        hook_input = {
            "tool_name": "Bash",
            "tool_input": {
                "command": 'git commit -m "$(cat <<EOF\nMultiline message\nEOF\n)"'
            },
        }

        with patch("sys.stdin", StringIO(json.dumps(hook_input))):
            with self.assertRaises(SystemExit) as cm:
                with open(hooks_dir / "git-commit-validator.py") as f:
                    exec(f.read())

            # Should exit with code 0 (allow)
            self.assertEqual(cm.exception.code, 0)


if __name__ == "__main__":
    unittest.main()
