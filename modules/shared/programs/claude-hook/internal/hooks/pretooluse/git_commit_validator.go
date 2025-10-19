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

// Validate checks if git commit command contains --no-verify flag or SKIP environment variable
func (h *GitCommitValidator) Validate(ctx context.Context, input *hook.Input) (*hook.Response, error) {
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

	// Remove environment variables to check if this is a git commit command
	commandWithoutEnv := hook.RemoveEnvVars(command)
	if !hook.IsGitCommitCommand(commandWithoutEnv) {
		return resp, nil
	}

	// Remove quoted content to avoid false positives in flag detection
	cleanCommand := hook.RemoveQuotedContent(command)

	// Check for --no-verify flag
	noVerifyPattern := regexp.MustCompile(`--no-verify\b`)
	if noVerifyPattern.MatchString(cleanCommand) {
		resp.Block("⚠️  --no-verify flag detected.\n" +
			"Pre-commit hooks are important for code quality.\n" +
			"Try these alternatives instead:\n" +
			"1. Fix pre-commit errors and commit normally\n" +
			"2. Run 'make format' to auto-fix formatting issues\n" +
			"3. Run manually in terminal if absolutely necessary")
		return resp, nil
	}

	// Check for SKIP environment variable
	skipPattern := regexp.MustCompile(`\bSKIP\s*=`)
	if skipPattern.MatchString(cleanCommand) {
		resp.Block("⚠️  SKIP environment variable detected.\n" +
			"Skipping pre-commit hooks bypasses code quality checks.\n" +
			"Try these alternatives instead:\n" +
			"1. Fix pre-commit errors and commit normally\n" +
			"2. Run 'make format' to auto-fix formatting issues\n" +
			"3. Run 'make lint-autofix' to auto-fix linting issues\n" +
			"4. Run manually in terminal if absolutely necessary")
		return resp, nil
	}

	return resp, nil
}
