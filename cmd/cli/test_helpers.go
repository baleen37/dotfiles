package main

import (
	"encoding/json"
	"fmt"
	"runtime"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

// resetCommands resets all commands and global state for testing
func resetCommands() {
	// Reset global variables
	cfg = nil
	verbose = false
	logLevel = ""
	configFile = ""
	environment = ""

	// Reset version variables
	version = "dev"
	commit = "unknown"
	buildDate = "unknown"
	builtBy = "unknown"

	// Reset viper
	viper.Reset()

	// Recreate root command
	rootCmd = &cobra.Command{
		Use:   "ssulmeta",
		Short: "YouTube Shorts automatic generation system",
		Long: `ssulmeta is a CLI tool for automated YouTube Shorts generation.
It creates storytelling-based videos and uploads them automatically.`,
		PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
			// Skip config loading for version command
			if cmd.Name() == "version" {
				return nil
			}
			return nil // Skip actual config loading in tests
		},
	}

	// Re-initialize flags
	rootCmd.PersistentFlags().StringVarP(&configFile, "config", "c", "", "config file path")
	rootCmd.PersistentFlags().StringVarP(&environment, "env", "e", "", "environment (local, dev, test, prod)")
	rootCmd.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "enable verbose output")
	rootCmd.PersistentFlags().StringVar(&logLevel, "log-level", "", "log level (debug, info, warn, error)")

	// Bind flags to viper
	viper.BindPFlag("config", rootCmd.PersistentFlags().Lookup("config"))
	viper.BindPFlag("env", rootCmd.PersistentFlags().Lookup("env"))
	viper.BindPFlag("log-level", rootCmd.PersistentFlags().Lookup("log-level"))

	// Bind environment variables
	viper.SetEnvPrefix("SSULMETA")
	viper.AutomaticEnv()

	// Recreate subcommands
	versionCmd = &cobra.Command{
		Use:   "version",
		Short: "Show version information",
		Long:  "Display version, build information, and runtime details",
		RunE: func(cmd *cobra.Command, args []string) error {
			short, _ := cmd.Flags().GetBool("short")
			jsonOutput, _ := cmd.Flags().GetBool("json")

			if short {
				fmt.Fprint(cmd.OutOrStdout(), version)
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

	versionCmd.Flags().BoolP("short", "s", false, "show only version number")
	versionCmd.Flags().BoolP("json", "j", false, "output in JSON format")

	configCmd = &cobra.Command{
		Use:   "config",
		Short: "Show configuration information",
		Long:  "Display current configuration, search paths, and validation status",
		RunE: func(cmd *cobra.Command, args []string) error {
			showPaths, _ := cmd.Flags().GetBool("paths")
			outputFormat, _ := cmd.Flags().GetString("output")

			if showPaths {
				return showConfigPaths(cmd)
			}

			return showConfig(cmd, outputFormat)
		},
	}

	configCmd.Flags().BoolP("paths", "p", false, "show configuration file search paths")
	configCmd.Flags().StringP("output", "o", "text", "output format (text, json, yaml)")

	// Recreate generate command for testing
	generateCmd = &cobra.Command{
		Use:   "generate",
		Short: "Generate YouTube Shorts stories",
		Long: `Generate YouTube Shorts stories using AI-powered content generation.

This command creates storytelling-based content for specified channels using
configured templates and AI generation services.`,
		RunE: func(cmd *cobra.Command, args []string) error {
			channelName, _ := cmd.Flags().GetString("channel")
			outputDir, _ := cmd.Flags().GetString("output")

			if channelName == "" {
				return fmt.Errorf("channel is required")
			}

			// Validate channel exists
			validChannels := []string{"fairy_tale", "horror", "romance"}
			isValid := false
			for _, valid := range validChannels {
				if channelName == valid {
					isValid = true
					break
				}
			}
			if !isValid {
				return fmt.Errorf("channel configuration not found for '%s'", channelName)
			}

			// Mock implementation for testing
			if cfg != nil && cfg.API.UseMock {
				// Show verbose output if enabled
				if verbose {
					cmd.Print("Loading configuration")
					cmd.Print("Creating story service")
				}

				cmd.Printf("Generating story for channel: %s\n", channelName)

				// Show output directory in output if specified
				if outputDir != "" {
					cmd.Printf("Output directory: %s\n", outputDir)
				}

				cmd.Print("Story generated successfully")
				return nil
			}

			return fmt.Errorf("configuration not loaded")
		},
	}
	generateCmd.Flags().String("channel", "", "Channel name")
	generateCmd.Flags().StringP("output", "o", "", "Output directory")

	// Add subcommands
	rootCmd.AddCommand(versionCmd)
	rootCmd.AddCommand(configCmd)
	rootCmd.AddCommand(generateCmd)
}
