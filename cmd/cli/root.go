package main

import (
	"fmt"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"

	"ssulmeta-go/internal/cli"
	"ssulmeta-go/internal/config"
)

var (
	cfg      *config.Config
	verbose  bool
	logLevel string
)

var rootCmd = &cobra.Command{
	Use:   "ssulmeta",
	Short: "YouTube Shorts automatic generation system",
	Long: `ssulmeta is a CLI tool for automated YouTube Shorts generation.
It creates storytelling-based videos and uploads them automatically.`,
	PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
		// Skip config loading for version command
		if cmd.Name() == "version" {
			return nil
		}

		// Initialize console logger early
		cli.InitConsoleLogger(verbose)

		// Load configuration
		configFile := viper.GetString("config")
		environment := viper.GetString("env")

		loader := cli.NewConfigLoader(configFile, environment)
		config, err := loader.Load()
		if err != nil {
			return fmt.Errorf("failed to load configuration: %w", err)
		}

		cfg = config

		// Setup logger
		err = cli.SetupLogger(&cfg.Logging, verbose, logLevel)
		if err != nil {
			return fmt.Errorf("failed to setup logger: %w", err)
		}

		return nil
	},
}

func init() {
	// Global flags
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

	// Add subcommands
	rootCmd.AddCommand(versionCmd)
	rootCmd.AddCommand(configCmd)
}

var (
	configFile  string
	environment string
)

// GetConfig returns the loaded configuration
func GetConfig() *config.Config {
	return cfg
}

// GetLogger returns a contextualized logger for a command
func GetLogger(cmd *cobra.Command) *cli.ProgressLogger {
	cmdName := cmd.Name()
	if cmd.Parent() != nil && cmd.Parent().Name() != "ssulmeta" {
		cmdName = cmd.Parent().Name() + ":" + cmdName
	}
	return cli.NewProgressLogger(verbose, cmdName)
}

func Execute() error {
	return rootCmd.Execute()
}
