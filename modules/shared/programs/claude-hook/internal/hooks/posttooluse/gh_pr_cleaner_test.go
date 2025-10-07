package posttooluse

import (
	"context"
	"testing"

	"github.com/baleen/dotfiles/hooks-go/internal/hook"
)

func TestGhPrCleaner_Name(t *testing.T) {
	h := NewGhPrCleaner()
	if got := h.Name(); got != "gh-pr-cleaner" {
		t.Errorf("Name() = %v, want gh-pr-cleaner", got)
	}
}

func TestGhPrCleaner_CleanClaudeAttribution(t *testing.T) {
	tests := []struct {
		name        string
		input       string
		want        string
		wantChanged bool
	}{
		{
			name: "removes claude code link",
			input: `## Summary

This is a test PR

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>`,
			want: `## Summary

This is a test PR`,
			wantChanged: true,
		},
		{
			name: "removes co-authored-by lowercase",
			input: `## Summary

This is a test PR

Co-authored-by: Claude <noreply@anthropic.com>`,
			want: `## Summary

This is a test PR`,
			wantChanged: true,
		},
		{
			name: "handles multiple newlines",
			input: `## Summary

This is a test PR


🤖 Generated with [Claude Code](https://claude.ai/code)



Co-Authored-By: Claude <noreply@anthropic.com>`,
			want: `## Summary

This is a test PR`,
			wantChanged: true,
		},
		{
			name: "no changes when no attribution",
			input: `## Summary

This is a clean PR`,
			want: `## Summary

This is a clean PR`,
			wantChanged: false,
		},
		{
			name: "removes custom claude code URLs",
			input: `## Summary

Test

🤖 Generated with [Claude Code](https://custom.url/claude)`,
			want: `## Summary

Test`,
			wantChanged: true,
		},
	}

	h := NewGhPrCleaner()
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, changed := h.CleanClaudeAttribution(tt.input)
			if got != tt.want {
				t.Errorf("CleanClaudeAttribution() got = %v, want %v", got, tt.want)
			}
			if changed != tt.wantChanged {
				t.Errorf("CleanClaudeAttribution() changed = %v, want %v", changed, tt.wantChanged)
			}
		})
	}
}

func TestGhPrCleaner_shouldProcess(t *testing.T) {
	tests := []struct {
		name  string
		input *hook.Input
		want  bool
	}{
		{
			name: "processes successful gh pr create",
			input: &hook.Input{
				ToolName: "Bash",
				ToolInput: map[string]interface{}{
					"command": "gh pr create --title 'Test' --body 'Body'",
				},
				ToolResponse: map[string]interface{}{
					"success": true,
				},
			},
			want: true,
		},
		{
			name: "skips failed commands",
			input: &hook.Input{
				ToolName: "Bash",
				ToolInput: map[string]interface{}{
					"command": "gh pr create --title 'Test'",
				},
				ToolResponse: map[string]interface{}{
					"success": false,
				},
			},
			want: false,
		},
		{
			name: "skips non-bash tools",
			input: &hook.Input{
				ToolName: "Read",
				ToolInput: map[string]interface{}{
					"file_path": "test.txt",
				},
				ToolResponse: map[string]interface{}{
					"success": true,
				},
			},
			want: false,
		},
		{
			name: "skips non-gh-pr commands",
			input: &hook.Input{
				ToolName: "Bash",
				ToolInput: map[string]interface{}{
					"command": "git commit -m 'test'",
				},
				ToolResponse: map[string]interface{}{
					"success": true,
				},
			},
			want: false,
		},
	}

	h := NewGhPrCleaner()
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := h.shouldProcess(tt.input); got != tt.want {
				t.Errorf("shouldProcess() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestGhPrCleaner_Validate_NonBashTool(t *testing.T) {
	h := NewGhPrCleaner()
	input := &hook.Input{
		ToolName:  "Read",
		ToolInput: map[string]interface{}{},
	}

	resp, err := h.Validate(context.Background(), input)
	if err != nil {
		t.Fatalf("Validate() error = %v", err)
	}

	if resp.Continue != true {
		t.Errorf("Validate() Continue = %v, want true", resp.Continue)
	}
}

func Test_isGhPrCreateCommand(t *testing.T) {
	tests := []struct {
		name    string
		command string
		want    bool
	}{
		{
			name:    "detects gh pr create",
			command: "gh pr create --title 'Test'",
			want:    true,
		},
		{
			name:    "detects gh pr create with heredoc",
			command: `gh pr create --body "$(cat <<'EOF'\nBody\nEOF\n)"`,
			want:    true,
		},
		{
			name:    "ignores gh pr create in quoted string",
			command: `echo "gh pr create is a command"`,
			want:    false,
		},
		{
			name:    "ignores other gh commands",
			command: "gh pr view",
			want:    false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := isGhPrCreateCommand(tt.command); got != tt.want {
				t.Errorf("isGhPrCreateCommand() = %v, want %v", got, tt.want)
			}
		})
	}
}
