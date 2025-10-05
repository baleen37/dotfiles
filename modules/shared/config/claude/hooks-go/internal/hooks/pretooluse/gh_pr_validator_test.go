package pretooluse

import (
	"testing"
)

func TestIsGhPrCreateCommand(t *testing.T) {
	tests := []struct {
		name     string
		command  string
		expected bool
	}{
		{
			name:     "gh pr create with flags",
			command:  `gh pr create --title "test" --body "content"`,
			expected: true,
		},
		{
			name:     "gh pr create in heredoc",
			command:  `gh pr create --body "$(cat <<'EOF'\ntest\nEOF\n)"`,
			expected: true,
		},
		{
			name:     "gh pr edit should not match",
			command:  `gh pr edit 123 --body "new"`,
			expected: false,
		},
		{
			name:     "git commit should not match",
			command:  `git commit -m "test"`,
			expected: false,
		},
		{
			name:     "gh pr create in quoted string should not match",
			command:  `echo "gh pr create --title test"`,
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := IsGhPrCreateCommand(tt.command)
			if result != tt.expected {
				t.Errorf("IsGhPrCreateCommand(%q) = %v, want %v", tt.command, result, tt.expected)
			}
		})
	}
}

func TestExtractPrBody(t *testing.T) {
	tests := []struct {
		name     string
		command  string
		expected string
	}{
		{
			name:     "double quotes",
			command:  `gh pr create --title "test" --body "my content"`,
			expected: "my content",
		},
		{
			name:     "single quotes",
			command:  `gh pr create --title 'test' --body 'my content'`,
			expected: "my content",
		},
		{
			name:     "heredoc pattern",
			command:  `gh pr create --body "$(cat <<'EOF'\nline1\nline2\nEOF\n)"`,
			expected: "$(cat <<'EOF'\\nline1\\nline2\\nEOF\\n)",
		},
		{
			name:     "no body flag",
			command:  `gh pr create --title "test"`,
			expected: "",
		},
		{
			name:     "body with escaped newlines",
			command:  `gh pr create --body "line1\nline2\nline3"`,
			expected: "line1\\nline2\\nline3",
		},
		{
			name:     "body with Claude attribution",
			command:  `gh pr create --body "feat: add feature\n\n🤖 Generated with [Claude Code](https://claude.ai/code)"`,
			expected: "feat: add feature\\n\\n🤖 Generated with [Claude Code](https://claude.ai/code)",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := extractPrBody(tt.command)
			if result != tt.expected {
				t.Errorf("extractPrBody(%q) = %q, want %q", tt.command, result, tt.expected)
			}
		})
	}
}

func TestHasClaudeAttribution(t *testing.T) {
	tests := []struct {
		name     string
		text     string
		expected bool
	}{
		{
			name:     "has Claude Code link with escaped newlines",
			text:     "feat: add feature\\n\\n🤖 Generated with [Claude Code](https://claude.ai/code)",
			expected: true,
		},
		{
			name:     "has Co-authored-by lowercase with escaped newlines",
			text:     "feat: add feature\\n\\nCo-authored-by: Claude <noreply@anthropic.com>",
			expected: true,
		},
		{
			name:     "has Co-Authored-By uppercase with escaped newlines",
			text:     "feat: add feature\\n\\nCo-Authored-By: Claude <noreply@anthropic.com>",
			expected: true,
		},
		{
			name:     "has both patterns with escaped newlines",
			text:     "feat: add feature\\n\\n🤖 Generated with [Claude Code](https://claude.ai/code)\\n\\nCo-Authored-By: Claude <noreply@anthropic.com>",
			expected: true,
		},
		{
			name:     "clean text with escaped newlines",
			text:     "feat: add feature\\n\\nThis is a clean PR description.",
			expected: false,
		},
		{
			name:     "empty text",
			text:     "",
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := hasClaudeAttribution(tt.text)
			if result != tt.expected {
				t.Errorf("hasClaudeAttribution(%q) = %v, want %v", tt.text, result, tt.expected)
			}
		})
	}
}
