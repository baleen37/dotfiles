// Claude Code hooks CLI - High-performance hook execution
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os"

	"github.com/baleen/dotfiles/hooks-go/internal/hook"
	"github.com/baleen/dotfiles/hooks-go/internal/hooks/posttooluse"
	"github.com/baleen/dotfiles/hooks-go/internal/hooks/pretooluse"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintf(os.Stderr, "Usage: %s <hook-name>\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "Available hooks:\n")
		fmt.Fprintf(os.Stderr, "  - git-commit-validator (PreToolUse)\n")
		fmt.Fprintf(os.Stderr, "  - gh-pr-validator (PreToolUse)\n")
		fmt.Fprintf(os.Stderr, "  - message-cleaner (PostToolUse)\n")
		fmt.Fprintf(os.Stderr, "  - gh-pr-cleaner (PostToolUse)\n")
		os.Exit(1)
	}

	hookName := os.Args[1]
	ctx := context.Background()

	// Read input from stdin
	var input hook.Input
	if err := json.NewDecoder(os.Stdin).Decode(&input); err != nil {
		fmt.Fprintf(os.Stderr, "Error: Invalid JSON input: %v\n", err)
		os.Exit(1)
	}

	// Create hook based on name
	var h hook.Hook
	switch hookName {
	case "git-commit-validator":
		h = pretooluse.NewGitCommitValidator()
	case "gh-pr-validator":
		h = pretooluse.NewGhPrValidator()
	case "message-cleaner":
		h = posttooluse.NewMessageCleaner()
	case "gh-pr-cleaner":
		h = posttooluse.NewGhPrCleaner()
	default:
		fmt.Fprintf(os.Stderr, "Error: Unknown hook: %s\n", hookName)
		os.Exit(1)
	}

	// Execute hook
	resp, err := h.Validate(ctx, &input)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	// Output response if there's a decision
	if resp.Decision != "" {
		if err := json.NewEncoder(os.Stdout).Encode(resp); err != nil {
			fmt.Fprintf(os.Stderr, "Error encoding response: %v\n", err)
			os.Exit(1)
		}
	}

	// If blocking, print reason to stderr
	if resp.Decision == "block" && resp.Reason != "" {
		fmt.Fprintf(os.Stderr, "%s\n", resp.Reason)
	}

	// Exit with appropriate code
	os.Exit(resp.ExitCode())
}
