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

	// Extract PR body
	body := extractPrBody(command)
	if body == "" {
		return resp, nil
	}

	// Check for Claude attribution
	if hasClaudeAttribution(body) {
		resp.Block("⚠️  Claude Code attribution detected in PR description.\n" +
			"Please remove the following before creating PR:\n" +
			"1. 🤖 Generated with [Claude Code](...)\n" +
			"2. Co-Authored-By: Claude <noreply@anthropic.com>\n\n" +
			"Tip: Use /create-pr command which auto-removes these patterns.")
		return resp, nil
	}

	return resp, nil
}

// IsGhPrCreateCommand checks if command is a gh pr create command
func IsGhPrCreateCommand(command string) bool {
	// Remove quoted content to avoid false positives
	cleanCommand := removeQuotedContent(command)
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
		regexp.MustCompile(`🤖 Generated with \[Claude Code\]`),
		regexp.MustCompile(`Co-authored-by: Claude <noreply@anthropic\.com>`),
		regexp.MustCompile(`Co-Authored-By: Claude <noreply@anthropic\.com>`),
	}

	for _, pattern := range claudePatterns {
		if pattern.MatchString(text) {
			return true
		}
	}

	return false
}

// removeQuotedContent removes content within quotes to avoid false positives
func removeQuotedContent(s string) string {
	// Remove double-quoted strings
	doubleQuotePattern := regexp.MustCompile(`"[^"]*"`)
	s = doubleQuotePattern.ReplaceAllString(s, "")

	// Remove single-quoted strings
	singleQuotePattern := regexp.MustCompile(`'[^']*'`)
	s = singleQuotePattern.ReplaceAllString(s, "")

	return s
}
