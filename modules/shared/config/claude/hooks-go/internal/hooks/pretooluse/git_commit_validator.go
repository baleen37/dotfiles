// Package pretooluse implements PreToolUse hooks that execute before tool calls
package pretooluse

import (
	"context"
	"regexp"

	"github.com/baleen/dotfiles/hooks-go/internal/hook"
)

// GitCommitValidator prevents use of --no-verify flag in git commit commands
type GitCommitValidator struct{}

// NewGitCommitValidator creates a new git commit validator hook
func NewGitCommitValidator() *GitCommitValidator {
	return &GitCommitValidator{}
}

// Name returns the hook identifier
func (h *GitCommitValidator) Name() string {
	return "git-commit-validator"
}

// Validate checks if git commit command contains --no-verify flag
func (h *GitCommitValidator) Validate(ctx context.Context, input *hook.Input) (*hook.Response, error) {
	resp := hook.NewResponse()

	// Only process Bash tool
	if input.ToolName != "Bash" {
		return resp, nil
	}

	// Get command from tool input
	commandInterface, ok := input.ToolInput["command"]
	if !ok {
		return resp, nil
	}

	command, ok := commandInterface.(string)
	if !ok {
		return resp, nil
	}

	// Check if this is a git commit command
	gitCommitPattern := regexp.MustCompile(`^\s*git\s+commit\b`)
	if !gitCommitPattern.MatchString(command) {
		return resp, nil
	}

	// Remove quoted content to avoid false positives
	cleanCommand := removeQuotedContent(command)

	// Check for --no-verify flag
	noVerifyPattern := regexp.MustCompile(`--no-verify\b`)
	if noVerifyPattern.MatchString(cleanCommand) {
		resp.Block("⚠️  --no-verify flag detected.\n" +
			"Pre-commit hooks are important for code quality.\n" +
			"Try these alternatives instead:\n" +
			"1. Fix pre-commit errors and commit normally\n" +
			"2. Skip specific hooks: SKIP=ruff git commit -m '...'\n" +
			"3. Run manually in terminal if absolutely necessary")
		return resp, nil
	}

	return resp, nil
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
