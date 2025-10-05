// Shared validation utilities for hook implementations
package hook

import "regexp"

// IsBashTool checks if the input is from the Bash tool
func IsBashTool(input *Input) bool {
	return input.ToolName == "Bash"
}

// IsGitCommitCommand checks if the command is a git commit command
func IsGitCommitCommand(command string) bool {
	gitCommitPattern := regexp.MustCompile(`^\s*git\s+commit\b`)
	return gitCommitPattern.MatchString(command)
}

// GetBashCommand extracts the command string from Bash tool input
func GetBashCommand(input *Input) (string, bool) {
	commandInterface, ok := input.ToolInput["command"]
	if !ok {
		return "", false
	}

	command, ok := commandInterface.(string)
	return command, ok
}
