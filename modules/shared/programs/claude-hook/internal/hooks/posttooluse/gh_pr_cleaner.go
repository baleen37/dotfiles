// Package posttooluse implements PostToolUse hooks that execute after tool completion
package posttooluse

import (
	"context"
	"fmt"
	"os/exec"
	"regexp"
	"strings"

	"github.com/baleen/dotfiles/hooks-go/internal/hook"
)

// GhPrCleaner removes Claude Code attribution from PR descriptions after creation
type GhPrCleaner struct{}

// NewGhPrCleaner creates a new gh pr cleaner hook
func NewGhPrCleaner() *GhPrCleaner {
	return &GhPrCleaner{}
}

// Name returns the hook identifier
func (h *GhPrCleaner) Name() string {
	return "gh-pr-cleaner"
}

// Validate processes the PostToolUse event and cleans PR descriptions
func (h *GhPrCleaner) Validate(ctx context.Context, input *hook.Input) (*hook.Response, error) {
	resp := hook.NewResponse()

	// Only process successful Bash gh pr create commands
	if !h.shouldProcess(input) {
		return resp, nil
	}

	// Get current PR body
	currentBody, err := h.getCurrentPRBody(ctx)
	if err != nil || currentBody == "" {
		return resp, nil
	}

	// Clean the body
	cleanedBody, wasChanged := h.CleanClaudeAttribution(currentBody)

	// Only update if something changed
	if wasChanged && cleanedBody != currentBody {
		if err := h.updatePRBody(ctx, cleanedBody); err != nil {
			fmt.Fprintln(stderr(), "⚠️  Failed to clean PR description")
		} else {
			fmt.Fprintln(stderr(), "✓ Removed Claude Code attribution from PR description")
		}
	}

	return resp, nil
}

// CleanClaudeAttribution removes Claude Code attribution patterns from PR description
func (h *GhPrCleaner) CleanClaudeAttribution(body string) (string, bool) {
	claudePatterns := []*regexp.Regexp{
		regexp.MustCompile(`(?m)\n*🤖 Generated with \[Claude Code\]\(https://claude\.ai/code\)\n*`),
		regexp.MustCompile(`(?m)\n*Co-authored-by: Claude <noreply@anthropic\.com>\n*`),
		regexp.MustCompile(`(?m)\n*Co-Authored-By: Claude <noreply@anthropic\.com>\n*`),
		regexp.MustCompile(`(?m)\n*🤖 Generated with \[Claude Code\]\([^)]*\)\n*`), // Handle other Claude Code URLs
	}

	cleaned := body
	changed := false

	// Remove each Claude Code pattern
	for _, pattern := range claudePatterns {
		newBody := pattern.ReplaceAllString(cleaned, "")
		if newBody != cleaned {
			changed = true
			cleaned = newBody
		}
	}

	// Clean up extra whitespace (3+ newlines -> 2 newlines)
	multiNewlinePattern := regexp.MustCompile(`\n{3,}`)
	cleaned = multiNewlinePattern.ReplaceAllString(cleaned, "\n\n")

	// Remove trailing newlines
	cleaned = strings.TrimRight(cleaned, "\n")

	return cleaned, changed
}

// shouldProcess checks if this command should be processed
func (h *GhPrCleaner) shouldProcess(input *hook.Input) bool {
	// Only process Bash tool
	if !hook.IsBashTool(input) {
		return false
	}

	// Get command
	command, ok := hook.GetBashCommand(input)
	if !ok {
		return false
	}

	// Check if this is a gh pr create command
	if !isGhPrCreateCommand(command) {
		return false
	}

	// Check if the command was successful
	if success, ok := input.ToolResponse["success"].(bool); ok && !success {
		return false
	}

	return true
}

// isGhPrCreateCommand checks if command is a gh pr create command
func isGhPrCreateCommand(command string) bool {
	// Remove quoted content to avoid false positives
	cleanCommand := hook.RemoveQuotedContent(command)
	return strings.Contains(cleanCommand, "gh pr create")
}

// getCurrentPRBody gets the current PR body from the current branch
func (h *GhPrCleaner) getCurrentPRBody(ctx context.Context) (string, error) {
	cmd := exec.CommandContext(ctx, "gh", "pr", "view", "--json", "body", "--jq", ".body")
	output, err := cmd.Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(output)), nil
}

// updatePRBody updates the PR body using gh pr edit
func (h *GhPrCleaner) updatePRBody(ctx context.Context, body string) error {
	cmd := exec.CommandContext(ctx, "gh", "pr", "edit", "--body", body)
	return cmd.Run()
}
