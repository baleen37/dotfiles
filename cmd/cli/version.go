package main

import (
	"encoding/json"
	"fmt"
	"runtime"

	"github.com/spf13/cobra"
)

// Build-time variables (set by ldflags)
var (
	version   = "dev"
	commit    = "unknown"
	buildDate = "unknown"
	builtBy   = "unknown"
)

// BuildInfo contains version and build information
type BuildInfo struct {
	Version   string `json:"version"`
	Commit    string `json:"commit"`
	BuildDate string `json:"build_date"`
	BuiltBy   string `json:"built_by"`
	GoVersion string `json:"go_version"`
	Platform  string `json:"platform"`
	Compiler  string `json:"compiler"`
}

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Show version information",
	Long:  "Display version, build information, and runtime details",
	RunE: func(cmd *cobra.Command, args []string) error {
		short, _ := cmd.Flags().GetBool("short")
		jsonOutput, _ := cmd.Flags().GetBool("json")

		if short {
			fmt.Println(version)
			return nil
		}

		info := BuildInfo{
			Version:   version,
			Commit:    commit,
			BuildDate: buildDate,
			BuiltBy:   builtBy,
			GoVersion: runtime.Version(),
			Platform:  runtime.GOOS + "/" + runtime.GOARCH,
			Compiler:  runtime.Compiler,
		}

		if jsonOutput {
			encoder := json.NewEncoder(cmd.OutOrStdout())
			encoder.SetIndent("", "  ")
			return encoder.Encode(info)
		}

		// Default formatted output
		fmt.Fprintf(cmd.OutOrStdout(), "ssulmeta - YouTube Shorts Generator\n\n")
		fmt.Fprintf(cmd.OutOrStdout(), "Version:    %s\n", info.Version)
		fmt.Fprintf(cmd.OutOrStdout(), "Commit:     %s\n", info.Commit)
		fmt.Fprintf(cmd.OutOrStdout(), "Build Date: %s\n", info.BuildDate)
		fmt.Fprintf(cmd.OutOrStdout(), "Built By:   %s\n", info.BuiltBy)
		fmt.Fprintf(cmd.OutOrStdout(), "Go Version: %s\n", info.GoVersion)
		fmt.Fprintf(cmd.OutOrStdout(), "Platform:   %s\n", info.Platform)
		fmt.Fprintf(cmd.OutOrStdout(), "Compiler:   %s\n", info.Compiler)

		return nil
	},
}

func init() {
	versionCmd.Flags().BoolP("short", "s", false, "show only version number")
	versionCmd.Flags().BoolP("json", "j", false, "output in JSON format")
}
