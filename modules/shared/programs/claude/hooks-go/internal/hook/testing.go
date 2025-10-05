// Testing utilities for hook implementations
package hook

// NewBashInput creates a test Input for a Bash command
func NewBashInput(command string) *Input {
	return &Input{
		ToolName: "Bash",
		ToolInput: map[string]interface{}{
			"command": command,
		},
	}
}

// NewBashInputWithResponse creates a test Input with tool response
func NewBashInputWithResponse(command string, success bool) *Input {
	return &Input{
		ToolName: "Bash",
		ToolInput: map[string]interface{}{
			"command": command,
		},
		ToolResponse: map[string]interface{}{
			"success": success,
		},
	}
}

// NewToolInput creates a test Input for any tool
func NewToolInput(toolName string, input map[string]interface{}) *Input {
	return &Input{
		ToolName:  toolName,
		ToolInput: input,
	}
}
