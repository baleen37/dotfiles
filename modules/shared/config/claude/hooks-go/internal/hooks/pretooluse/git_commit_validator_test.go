package pretooluse_test

import (
	"context"
	"testing"

	"github.com/baleen/dotfiles/hooks-go/internal/hook"
	"github.com/baleen/dotfiles/hooks-go/internal/hooks/pretooluse"
)

func TestGitCommitValidator_BlocksNoVerifyFlag(t *testing.T) {
	validator := pretooluse.NewGitCommitValidator()

	input := &hook.Input{
		ToolName: "Bash",
		ToolInput: map[string]interface{}{
			"command": "git commit --no-verify -m 'test'",
		},
	}

	resp, err := validator.Validate(context.Background(), input)

	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if resp.Decision != "block" {
		t.Errorf("expected decision=block, got %s", resp.Decision)
	}

	if resp.ExitCode() != 2 {
		t.Errorf("expected exit code 2, got %d", resp.ExitCode())
	}

	if resp.Reason == "" {
		t.Error("expected non-empty reason for blocking")
	}
}

func TestGitCommitValidator_AllowsNormalCommit(t *testing.T) {
	validator := pretooluse.NewGitCommitValidator()

	input := &hook.Input{
		ToolName: "Bash",
		ToolInput: map[string]interface{}{
			"command": "git commit -m 'normal commit'",
		},
	}

	resp, err := validator.Validate(context.Background(), input)

	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !resp.Continue {
		t.Error("expected continue=true")
	}

	if resp.ExitCode() != 0 {
		t.Errorf("expected exit code 0, got %d", resp.ExitCode())
	}
}

func TestGitCommitValidator_IgnoresQuotedNoVerify(t *testing.T) {
	validator := pretooluse.NewGitCommitValidator()

	input := &hook.Input{
		ToolName: "Bash",
		ToolInput: map[string]interface{}{
			"command": `git commit -m "message about --no-verify flag"`,
		},
	}

	resp, err := validator.Validate(context.Background(), input)

	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !resp.Continue {
		t.Error("expected continue=true for --no-verify inside quotes")
	}

	if resp.ExitCode() != 0 {
		t.Errorf("expected exit code 0, got %d", resp.ExitCode())
	}
}

func TestGitCommitValidator_PassesNonBashTools(t *testing.T) {
	validator := pretooluse.NewGitCommitValidator()

	input := &hook.Input{
		ToolName: "Write",
		ToolInput: map[string]interface{}{
			"file_path": "test.py",
			"content":   "print('hello')",
		},
	}

	resp, err := validator.Validate(context.Background(), input)

	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !resp.Continue {
		t.Error("expected continue=true for non-Bash tools")
	}

	if resp.ExitCode() != 0 {
		t.Errorf("expected exit code 0, got %d", resp.ExitCode())
	}
}

func TestGitCommitValidator_PassesNonGitCommands(t *testing.T) {
	validator := pretooluse.NewGitCommitValidator()

	input := &hook.Input{
		ToolName: "Bash",
		ToolInput: map[string]interface{}{
			"command": "ls -la",
		},
	}

	resp, err := validator.Validate(context.Background(), input)

	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !resp.Continue {
		t.Error("expected continue=true for non-git commands")
	}

	if resp.ExitCode() != 0 {
		t.Errorf("expected exit code 0, got %d", resp.ExitCode())
	}
}

func TestGitCommitValidator_BlocksNoVerifyWithMultipleFlags(t *testing.T) {
	validator := pretooluse.NewGitCommitValidator()

	input := &hook.Input{
		ToolName: "Bash",
		ToolInput: map[string]interface{}{
			"command": "git commit -a --no-verify -m 'test'",
		},
	}

	resp, err := validator.Validate(context.Background(), input)

	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if resp.Decision != "block" {
		t.Errorf("expected decision=block, got %s", resp.Decision)
	}

	if resp.ExitCode() != 2 {
		t.Errorf("expected exit code 2, got %d", resp.ExitCode())
	}
}

func TestGitCommitValidator_HandlesGitCommitWithHeredoc(t *testing.T) {
	validator := pretooluse.NewGitCommitValidator()

	input := &hook.Input{
		ToolName: "Bash",
		ToolInput: map[string]interface{}{
			"command": `git commit -m "$(cat <<EOF
Multiline message
EOF
)"`,
		},
	}

	resp, err := validator.Validate(context.Background(), input)

	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !resp.Continue {
		t.Error("expected continue=true for git commit with heredoc")
	}

	if resp.ExitCode() != 0 {
		t.Errorf("expected exit code 0, got %d", resp.ExitCode())
	}
}

func TestGitCommitValidator_HandlesSingleQuotedNoVerify(t *testing.T) {
	validator := pretooluse.NewGitCommitValidator()

	input := &hook.Input{
		ToolName: "Bash",
		ToolInput: map[string]interface{}{
			"command": `git commit -m 'message about --no-verify flag'`,
		},
	}

	resp, err := validator.Validate(context.Background(), input)

	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !resp.Continue {
		t.Error("expected continue=true for --no-verify in single quotes")
	}

	if resp.ExitCode() != 0 {
		t.Errorf("expected exit code 0, got %d", resp.ExitCode())
	}
}
