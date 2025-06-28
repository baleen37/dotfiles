package main

import (
	"bytes"
	"encoding/json"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestVersionCommand(t *testing.T) {
	tests := []struct {
		name           string
		args           []string
		setupFunc      func()
		expectedOutput []string
		notExpected    []string
		checkJSON      bool
	}{
		{
			name: "default version output",
			args: []string{"version"},
			expectedOutput: []string{
				"ssulmeta",
				"YouTube Shorts Generator",
				"Version:",
				"Commit:",
				"Build Date:",
				"Go Version:",
				"Platform:",
			},
		},
		{
			name: "short version output",
			args: []string{"version", "--short"},
			setupFunc: func() {
				version = "1.2.3"
			},
			expectedOutput: []string{"1.2.3"},
			notExpected: []string{
				"Commit:",
				"Build Date:",
				"Go Version:",
			},
		},
		{
			name:      "json version output",
			args:      []string{"version", "--json"},
			checkJSON: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Reset
			resetCommands()

			// Run setup if provided
			if tt.setupFunc != nil {
				tt.setupFunc()
			}

			// Capture output
			output := &bytes.Buffer{}
			rootCmd.SetOut(output)
			rootCmd.SetErr(output)

			// Set arguments
			rootCmd.SetArgs(tt.args)

			// Execute
			err := rootCmd.Execute()
			require.NoError(t, err)

			outputStr := output.String()

			// Check expected output
			for _, expected := range tt.expectedOutput {
				assert.Contains(t, outputStr, expected)
			}

			// Check not expected
			for _, notExpected := range tt.notExpected {
				assert.NotContains(t, outputStr, notExpected)
			}

			// Check JSON output
			if tt.checkJSON {
				var info BuildInfo
				err := json.Unmarshal(output.Bytes(), &info)
				require.NoError(t, err)
				assert.NotEmpty(t, info.GoVersion)
				assert.NotEmpty(t, info.Platform)
				assert.NotEmpty(t, info.Compiler)
			}
		})
	}
}

func TestVersionCommandBuildInfo(t *testing.T) {
	tests := []struct {
		name     string
		setup    func()
		expected BuildInfo
	}{
		{
			name: "uses build-time variables",
			setup: func() {
				version = "1.0.0"
				commit = "abc123"
				buildDate = "2024-01-01"
				builtBy = "ci"
			},
			expected: BuildInfo{
				Version:   "1.0.0",
				Commit:    "abc123",
				BuildDate: "2024-01-01",
				BuiltBy:   "ci",
			},
		},
		{
			name: "defaults when not set",
			setup: func() {
				version = "dev"
				commit = "unknown"
				buildDate = "unknown"
				builtBy = "unknown"
			},
			expected: BuildInfo{
				Version:   "dev",
				Commit:    "unknown",
				BuildDate: "unknown",
				BuiltBy:   "unknown",
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Reset
			resetCommands()

			// Setup
			tt.setup()

			// Capture output
			output := &bytes.Buffer{}
			rootCmd.SetOut(output)
			rootCmd.SetErr(output)

			// Execute with JSON output
			rootCmd.SetArgs([]string{"version", "--json"})
			err := rootCmd.Execute()
			require.NoError(t, err)

			// Parse JSON
			var info BuildInfo
			err = json.Unmarshal(output.Bytes(), &info)
			require.NoError(t, err)

			// Check expected values
			assert.Equal(t, tt.expected.Version, info.Version)
			assert.Equal(t, tt.expected.Commit, info.Commit)
			assert.Equal(t, tt.expected.BuildDate, info.BuildDate)
			assert.Equal(t, tt.expected.BuiltBy, info.BuiltBy)

			// Runtime info should always be populated
			assert.NotEmpty(t, info.GoVersion)
			assert.NotEmpty(t, info.Platform)
			assert.NotEmpty(t, info.Compiler)
		})
	}
}

func TestVersionFlags(t *testing.T) {
	t.Run("json and short flags are mutually exclusive in practice", func(t *testing.T) {
		resetCommands()

		// When both are set, short takes precedence
		output := &bytes.Buffer{}
		rootCmd.SetOut(output)
		rootCmd.SetErr(output)

		version = "1.0.0"
		rootCmd.SetArgs([]string{"version", "--short", "--json"})
		err := rootCmd.Execute()
		require.NoError(t, err)

		// Output should be short version only
		outputStr := strings.TrimSpace(output.String())
		assert.Equal(t, "1.0.0", outputStr)
	})
}

// Reset version variables to defaults for testing
func resetVersionVars() {
	version = "dev"
	commit = "unknown"
	buildDate = "unknown"
	builtBy = "unknown"
}
