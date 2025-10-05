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

// MessageCleaner removes Claude Code attribution from git commit messages
type MessageCleaner struct{}

// NewMessageCleaner creates a new message cleaner hook
func NewMessageCleaner() *MessageCleaner {
	return &MessageCleaner{}
}

// Name returns the hook identifier
func (h *MessageCleaner) Name() string {
	return "message-cleaner"
}

// Validate processes the PostToolUse event and cleans commit messages
func (h *MessageCleaner) Validate(ctx context.Context, input *hook.Input) (*hook.Response, error) {
	resp := hook.NewResponse()

	// Only process successful Bash git commit commands
	if !h.shouldProcess(input) {
		return resp, nil
	}

	// Get current commit message
	currentMessage, err := h.getCurrentCommitMessage(ctx)
	if err != nil || currentMessage == "" {
		return resp, nil
	}

	// Clean the message
	cleanedMessage, wasChanged := h.CleanClaudeAttribution(currentMessage)

	// Only amend if something changed
	if wasChanged && cleanedMessage != currentMessage {
		if err := h.amendCommitMessage(ctx, cleanedMessage); err != nil {
			fmt.Fprintln(stderr(), "⚠️  Failed to clean commit message")
		} else {
			fmt.Fprintln(stderr(), "✓ Removed Claude Code attribution from commit message")
		}
	}

	return resp, nil
}

// CleanClaudeAttribution removes Claude Code attribution patterns from a commit message
func (h *MessageCleaner) CleanClaudeAttribution(message string) (string, bool) {
	claudePatterns := []*regexp.Regexp{
		regexp.MustCompile(`(?m)\n*🤖 Generated with \[Claude Code\]\(https://claude\.ai/code\)\n*`),
		regexp.MustCompile(`(?m)\n*Co-authored-by: Claude <noreply@anthropic\.com>\n*`),
		regexp.MustCompile(`(?m)\n*🤖 Generated with \[Claude Code\]\([^)]*\)\n*`), // Handle other Claude Code URLs
	}

	cleaned := message
	changed := false

	// Remove each Claude Code pattern
	for _, pattern := range claudePatterns {
		newMessage := pattern.ReplaceAllString(cleaned, "")
		if newMessage != cleaned {
			changed = true
			cleaned = newMessage
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
func (h *MessageCleaner) shouldProcess(input *hook.Input) bool {
	// Only process Bash tool
	if input.ToolName != "Bash" {
		return false
	}

	// Get command
	commandInterface, ok := input.ToolInput["command"]
	if !ok {
		return false
	}

	command, ok := commandInterface.(string)
	if !ok {
		return false
	}

	// Check if this is a git commit command
	gitCommitPattern := regexp.MustCompile(`^\s*git\s+commit\b`)
	if !gitCommitPattern.MatchString(command) {
		return false
	}

	// Check if the command was successful
	if success, ok := input.ToolResponse["success"].(bool); ok && !success {
		return false
	}

	return true
}

// getCurrentCommitMessage gets the current commit message from git
func (h *MessageCleaner) getCurrentCommitMessage(ctx context.Context) (string, error) {
	cmd := exec.CommandContext(ctx, "git", "log", "-1", "--pretty=format:%B")
	output, err := cmd.Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(output)), nil
}

// amendCommitMessage amends the current commit with a new message
func (h *MessageCleaner) amendCommitMessage(ctx context.Context, message string) error {
	cmd := exec.CommandContext(ctx, "git", "commit", "--amend", "-m", message)
	return cmd.Run()
}

// stderr returns os.Stderr (extracted for testability)
var stderr = func() interface{ Write([]byte) (int, error) } {
	return stdErr
}

type writer struct{}

func (w writer) Write(p []byte) (int, error) {
	// In tests, this can be mocked
	return len(p), nil
}

var stdErr = writer{}
