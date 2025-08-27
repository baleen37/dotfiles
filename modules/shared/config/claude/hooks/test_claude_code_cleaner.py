#!/usr/bin/env python3
"""
Test suite for Claude Code commit message cleaner
"""
import json
import subprocess
import tempfile
import os
import sys
from pathlib import Path
import unittest
from unittest.mock import patch, MagicMock
from io import StringIO

# Add the hooks directory to Python path
hooks_dir = Path(__file__).parent
sys.path.insert(0, str(hooks_dir))

class TestClaudeCodeCleaner(unittest.TestCase):

    def setUp(self):
        """Set up test fixtures"""
        self.test_commit_with_claude = """fix: SEARCH-11288, 상품 색인에서 title-attribute의 CAT 토큰 삭제 이슈 수정 (#2358)

- isWordRemovable 함수에 remainCategory 파라미터 복원
- removeAndMergeAttributeWords 함수에 remainCategory 파라미터 추가
- refined_name에서는 CAT 토큰 유지 (remainCategory=true)
- 검색키워드, 광고소재명에서는 CAT 토큰 삭제 (remainCategory=false)
- PR #1593으로 인한 의도치 않은 CAT 토큰 유지 문제 해결

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-authored-by: Claude <noreply@anthropic.com>"""

        self.expected_clean_commit = """fix: SEARCH-11288, 상품 색인에서 title-attribute의 CAT 토큰 삭제 이슈 수정 (#2358)

- isWordRemovable 함수에 remainCategory 파라미터 복원
- removeAndMergeAttributeWords 함수에 remainCategory 파라미터 추가
- refined_name에서는 CAT 토큰 유지 (remainCategory=true)
- 검색키워드, 광고소재명에서는 CAT 토큰 삭제 (remainCategory=false)
- PR #1593으로 인한 의도치 않은 CAT 토큰 유지 문제 해결"""

    def test_should_clean_claude_code_attribution_from_commit_message(self):
        """Test that Claude Code attribution is removed from commit messages"""
        # RED: This test should fail initially

        # Mock input data for PostToolUse hook
        hook_input = {
            "tool_name": "Bash",
            "tool_input": {"command": "git commit -m 'test commit'"},
            "tool_response": {"success": True}
        }

        with patch('subprocess.run') as mock_run:
            # Mock git log to return commit with Claude attribution
            mock_run.side_effect = [
                # First call: git log to get current message
                MagicMock(returncode=0, stdout=self.test_commit_with_claude),
                # Second call: git commit --amend to clean message
                MagicMock(returncode=0, stdout='')
            ]

            # Import and run the cleaner
            import claude_code_message_cleaner

            # Capture stderr to check success message
            captured_stderr = StringIO()

            with patch('sys.stdin', StringIO(json.dumps(hook_input))):
                with patch('sys.stderr', captured_stderr):
                    try:
                        claude_code_message_cleaner.main()
                    except SystemExit:
                        pass  # Expected exit

            # Verify git commit --amend was called with cleaned message
            amend_calls = [call for call in mock_run.call_args_list
                          if len(call[0]) > 0 and call[0][0] == ["git", "commit", "--amend", "-m", self.expected_clean_commit]]
            self.assertEqual(len(amend_calls), 1, "git commit --amend should be called with cleaned message")

            # Verify success message was printed
            stderr_output = captured_stderr.getvalue()
            self.assertIn("Removed Claude Code attribution", stderr_output)

    def test_should_not_process_non_git_commit_commands(self):
        """Test that non-git commands are ignored"""
        hook_input = {
            "tool_name": "Bash",
            "tool_input": {"command": "ls -la"},
            "tool_response": {"success": True}
        }

        with patch('subprocess.run') as mock_run:
            import claude_code_message_cleaner

            with patch('sys.stdin', StringIO(json.dumps(hook_input))):
                try:
                    claude_code_message_cleaner.main()
                except SystemExit:
                    pass

            # Verify no git commands were called
            mock_run.assert_not_called()

    def test_should_not_process_failed_git_commits(self):
        """Test that failed git commits are not processed"""
        hook_input = {
            "tool_name": "Bash",
            "tool_input": {"command": "git commit -m 'test'"},
            "tool_response": {"success": False}
        }

        with patch('subprocess.run') as mock_run:
            import claude_code_message_cleaner

            with patch('sys.stdin', StringIO(json.dumps(hook_input))):
                try:
                    claude_code_message_cleaner.main()
                except SystemExit:
                    pass

            # Verify no git commands were called
            mock_run.assert_not_called()

    def test_should_handle_commit_without_claude_attribution(self):
        """Test that commits without Claude attribution are left unchanged"""
        clean_commit = "fix: simple bug fix\n\nThis is a regular commit message."

        hook_input = {
            "tool_name": "Bash",
            "tool_input": {"command": "git commit -m 'test commit'"},
            "tool_response": {"success": True}
        }

        with patch('subprocess.run') as mock_run:
            mock_run.return_value = MagicMock(returncode=0, stdout=clean_commit)

            import claude_code_message_cleaner

            with patch('sys.stdin', StringIO(json.dumps(hook_input))):
                try:
                    claude_code_message_cleaner.main()
                except SystemExit:
                    pass

            # Should only call git log, not git commit --amend
            self.assertEqual(len(mock_run.call_args_list), 1)
            self.assertEqual(mock_run.call_args_list[0][0][0], ["git", "log", "-1", "--pretty=format:%B"])


if __name__ == '__main__':
    unittest.main()
