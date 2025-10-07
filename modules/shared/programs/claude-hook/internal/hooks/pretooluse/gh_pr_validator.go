// Package pretooluse implements PreToolUse hooks that execute before tool calls
package pretooluse

import (
	"context"
	"regexp"
	"strings"

	"github.com/baleen/dotfiles/hooks-go/internal/hook"
)

// GhPrValidator prevents PR creation with Claude Code attribution
type GhPrValidator struct{}

// NewGhPrValidator creates a new gh pr validator hook
func NewGhPrValidator() *GhPrValidator {
	return &GhPrValidator{}
}

// Name returns the hook identifier
func (h *GhPrValidator) Name() string {
	return "gh-pr-validator"
}

// Validate checks if gh pr create command contains Claude attribution in body
func (h *GhPrValidator) Validate(ctx context.Context, input *hook.Input) (*hook.Response, error) {
	resp := hook.NewResponse()

	// Only process Bash tool
	if !hook.IsBashTool(input) {
		return resp, nil
	}

	// Get command from tool input
	command, ok := hook.GetBashCommand(input)
	if !ok {
		return resp, nil
	}

	// Check if this is a gh pr create command
	if !IsGhPrCreateCommand(command) {
		return resp, nil
	}

	// Allow PR creation - PostToolUse hook will clean attribution automatically
	return resp, nil
}

// IsGhPrCreateCommand checks if command is a gh pr create command
func IsGhPrCreateCommand(command string) bool {
	// Remove quoted content to avoid false positives
	cleanCommand := hook.RemoveQuotedContent(command)
	return strings.Contains(cleanCommand, "gh pr create")
}

// extractPrBody extracts the --body parameter from gh pr create command
func extractPrBody(command string) string {
	// Pattern 1: --body "content" or --body 'content'
	doubleQuotePattern := regexp.MustCompile(`--body\s+"([^"]*)"`)
	if matches := doubleQuotePattern.FindStringSubmatch(command); len(matches) > 1 {
		return matches[1]
	}

	singleQuotePattern := regexp.MustCompile(`--body\s+'([^']*)'`)
	if matches := singleQuotePattern.FindStringSubmatch(command); len(matches) > 1 {
		return matches[1]
	}

	// Pattern 2: heredoc - --body "$(cat <<'EOF' ... EOF)"
	heredocPattern := regexp.MustCompile(`--body\s+"?\$\(cat\s+<<'?EOF'?\s*(.*?)\s*EOF`)
	if matches := heredocPattern.FindStringSubmatch(command); len(matches) > 1 {
		return strings.TrimSpace(matches[1])
	}

	return ""
}

// hasClaudeAttribution checks if text contains Claude Code attribution patterns
func hasClaudeAttribution(text string) bool {
	claudePatterns := []*regexp.Regexp{
		regexp.MustCompile(`🤖 Generated with \[Claude Code\](\([^\)]+\))?`),
		regexp.MustCompile(`(?i)co-authored-by: Claude <noreply@anthropic\.com>`),
	}

	for _, pattern := range claudePatterns {
		if pattern.MatchString(text) {
			return true
		}
	}

	return false
}
