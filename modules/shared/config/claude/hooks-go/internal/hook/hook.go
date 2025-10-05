// Package hook provides core interfaces and types for Claude Code hooks
package hook

import (
	"context"
)

// Hook interface that all hooks must implement
type Hook interface {
	// Name returns the hook identifier
	Name() string

	// Validate processes the input and returns a response
	Validate(ctx context.Context, input *Input) (*Response, error)
}

// Input represents the JSON payload from Claude Code via stdin
type Input struct {
	SessionID      string                 `json:"session_id"`
	TranscriptPath string                 `json:"transcript_path"`
	CWD            string                 `json:"cwd"`
	HookEventName  string                 `json:"hook_event_name"`
	ToolName       string                 `json:"tool_name,omitempty"`
	ToolInput      map[string]interface{} `json:"tool_input,omitempty"`
	ToolResponse   map[string]interface{} `json:"tool_response,omitempty"` // For PostToolUse hooks
}

// Response represents the hook output
type Response struct {
	Decision       string `json:"decision,omitempty"`        // "approve" | "block"
	Reason         string `json:"reason,omitempty"`          // Explanation for the decision
	Continue       bool   `json:"continue"`                  // Whether Claude should continue
	SuppressOutput bool   `json:"suppressOutput,omitempty"`  // Hide stdout from transcript
}

// ExitCode determines the exit code based on decision
// Exit code 0: Allow/continue
// Exit code 2: Block/error (shows stderr to Claude)
func (r *Response) ExitCode() int {
	if r.Decision == "block" {
		return 2
	}
	return 0
}

// NewResponse creates a default response that allows continuation
func NewResponse() *Response {
	return &Response{
		Continue: true,
	}
}

// Block sets the response to block with a reason
func (r *Response) Block(reason string) {
	r.Decision = "block"
	r.Reason = reason
	r.Continue = false
}

// Approve sets the response to approve with an optional reason
func (r *Response) Approve(reason string) {
	r.Decision = "approve"
	if reason != "" {
		r.Reason = reason
	}
	r.Continue = true
}
