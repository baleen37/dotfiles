package posttooluse_test

import (
	"context"
	"strings"
	"testing"

	"github.com/baleen/dotfiles/hooks-go/internal/hook"
	"github.com/baleen/dotfiles/hooks-go/internal/hooks/posttooluse"
)

func TestMessageCleaner_CleanClaudeAttribution(t *testing.T) {
	cleaner := posttooluse.NewMessageCleaner()

	tests := []struct {
		name     string
		message  string
		expected string
		changed  bool
	}{
		{
			name: "removes Claude Code link",
			message: `feat: add feature

Some description

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-authored-by: Claude <noreply@anthropic.com>`,
			expected: `feat: add feature

Some description`,
			changed: true,
		},
		{
			name: "removes only Co-authored-by",
			message: `fix: bug fix

Co-authored-by: Claude <noreply@anthropic.com>`,
			expected: `fix: bug fix`,
			changed:  true,
		},
		{
			name: "no changes if no attribution",
			message: `feat: normal commit

Regular commit message`,
			expected: `feat: normal commit

Regular commit message`,
			changed: false,
		},
		{
			name: "handles multiple newlines",
			message: `feat: test


🤖 Generated with [Claude Code](https://claude.ai/code)



Co-authored-by: Claude <noreply@anthropic.com>`,
			expected: `feat: test`,
			changed:  true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cleaned, changed := cleaner.CleanClaudeAttribution(tt.message)

			// Normalize whitespace for comparison
			cleanedNorm := strings.TrimSpace(cleaned)
			expectedNorm := strings.TrimSpace(tt.expected)

			if cleanedNorm != expectedNorm {
				t.Errorf("CleanClaudeAttribution() cleaned = %q, want %q", cleanedNorm, expectedNorm)
			}

			if changed != tt.changed {
				t.Errorf("CleanClaudeAttribution() changed = %v, want %v", changed, tt.changed)
			}
		})
	}
}

func TestMessageCleaner_PassesNonBashTools(t *testing.T) {
	cleaner := posttooluse.NewMessageCleaner()

	input := &hook.Input{
		ToolName: "Write",
		ToolInput: map[string]interface{}{
			"file_path": "test.txt",
			"content":   "test",
		},
		ToolResponse: map[string]interface{}{
			"success": true,
		},
	}

	resp, err := cleaner.Validate(context.Background(), input)

	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !resp.Continue {
		t.Error("expected continue=true for non-Bash tools")
	}
}

func TestMessageCleaner_PassesNonGitCommands(t *testing.T) {
	cleaner := posttooluse.NewMessageCleaner()

	input := hook.NewBashInputWithResponse("ls -la", true)

	resp, err := cleaner.Validate(context.Background(), input)

	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !resp.Continue {
		t.Error("expected continue=true for non-git commands")
	}
}

func TestMessageCleaner_PassesFailedCommits(t *testing.T) {
	cleaner := posttooluse.NewMessageCleaner()

	input := hook.NewBashInputWithResponse("git commit -m 'test'", false)

	resp, err := cleaner.Validate(context.Background(), input)

	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !resp.Continue {
		t.Error("expected continue=true for failed commits")
	}
}
