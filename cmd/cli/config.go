package main

import (
	"encoding/json"
	"fmt"
	"os"
	"regexp"
	"strings"

	"github.com/spf13/cobra"
	"golang.org/x/text/cases"
	"golang.org/x/text/language"
	"gopkg.in/yaml.v3"

	"ssulmeta-go/internal/cli"
)

var configCmd = &cobra.Command{
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

func init() {
	configCmd.Flags().BoolP("paths", "p", false, "show configuration file search paths")
	configCmd.Flags().StringP("output", "o", "text", "output format (text, json, yaml)")
}

func showConfigPaths(cmd *cobra.Command) error {
	fmt.Fprintf(cmd.OutOrStdout(), "Configuration Paths:\n\n")

	// Show explicit config file if set
	if configFile := os.Getenv("CONFIG_FILE"); configFile != "" {
		fmt.Fprintf(cmd.OutOrStdout(), "Explicit config file: %s\n", configFile)
		if _, err := os.Stat(configFile); err == nil {
			fmt.Fprintf(cmd.OutOrStdout(), "  ✓ File found\n")
		} else {
			fmt.Fprintf(cmd.OutOrStdout(), "  ✗ File not found\n")
		}
		fmt.Fprintf(cmd.OutOrStdout(), "\n")
	}

	// Show environment and search paths
	env := os.Getenv("APP_ENV")
	if env == "" {
		env = "local"
	}
	fmt.Fprintf(cmd.OutOrStdout(), "Environment: %s\n\n", env)

	fmt.Fprintf(cmd.OutOrStdout(), "Search paths (in order):\n")
	paths := cli.GetConfigPaths(env)
	for _, path := range paths {
		if _, err := os.Stat(path); err == nil {
			fmt.Fprintf(cmd.OutOrStdout(), "  ✓ %s\n", path)
		} else {
			fmt.Fprintf(cmd.OutOrStdout(), "  ✗ %s\n", path)
		}
	}

	return nil
}

func showConfig(cmd *cobra.Command, format string) error {
	if cfg == nil {
		return fmt.Errorf("configuration not loaded")
	}

	// Convert config to map for easier manipulation
	configMap := make(map[string]interface{})
	data, err := yaml.Marshal(cfg)
	if err != nil {
		return fmt.Errorf("failed to marshal config: %w", err)
	}

	if err := yaml.Unmarshal(data, &configMap); err != nil {
		return fmt.Errorf("failed to unmarshal config: %w", err)
	}

	// Mask sensitive data
	maskedConfig := maskSensitiveData(configMap)

	switch strings.ToLower(format) {
	case "json":
		encoder := json.NewEncoder(cmd.OutOrStdout())
		encoder.SetIndent("", "  ")
		return encoder.Encode(maskedConfig)
	case "yaml":
		encoder := yaml.NewEncoder(cmd.OutOrStdout())
		defer encoder.Close()
		return encoder.Encode(maskedConfig)
	default:
		return showConfigText(cmd, maskedConfig)
	}
}

func showConfigText(cmd *cobra.Command, config map[string]interface{}) error {
	fmt.Fprintf(cmd.OutOrStdout(), "Current Configuration:\n\n")
	printConfigSection(cmd, config, "")
	return nil
}

func printConfigSection(cmd *cobra.Command, config map[string]interface{}, indent string) {
	for key, value := range config {
		switch v := value.(type) {
		case map[string]interface{}:
			title := cases.Title(language.English).String(strings.ReplaceAll(key, "_", " "))
			fmt.Fprintf(cmd.OutOrStdout(), "%s%s:\n", indent, title)
			printConfigSection(cmd, v, indent+"  ")
		default:
			title := cases.Title(language.English).String(strings.ReplaceAll(key, "_", " "))
			fmt.Fprintf(cmd.OutOrStdout(), "%s%s: %v\n", indent, title, v)
		}
	}
}

// maskSensitiveData replaces sensitive values with ****
func maskSensitiveData(data map[string]interface{}) map[string]interface{} {
	result := make(map[string]interface{})

	for key, value := range data {
		if shouldMaskKey(key) {
			if str, ok := value.(string); ok {
				result[key] = maskValue(str)
			} else {
				result[key] = "****"
			}
		} else if subMap, ok := value.(map[string]interface{}); ok {
			result[key] = maskSensitiveData(subMap)
		} else {
			result[key] = value
		}
	}

	return result
}

func shouldMaskKey(key string) bool {
	sensitiveKeys := []string{
		"password", "secret", "key", "token", "auth", "credential",
		"api_key", "apikey", "dsn",
	}

	lowerKey := strings.ToLower(key)
	for _, sensitive := range sensitiveKeys {
		if strings.Contains(lowerKey, sensitive) {
			return true
		}
	}
	return false
}

func maskValue(value string) string {
	if value == "" {
		return "****"
	}

	// Special handling for DSN strings
	if strings.Contains(value, "://") || strings.Contains(value, "@") {
		return maskDSN(value)
	}

	return "****"
}

func maskDSN(dsn string) string {
	// Pattern: user:password@host:port/db -> ****@host:port/db
	re := regexp.MustCompile(`^([^:]+:[^@]+)@(.+)$`)
	if matches := re.FindStringSubmatch(dsn); len(matches) == 3 {
		return "****@" + matches[2]
	}

	// If no @ symbol, mask the beginning
	if len(dsn) <= 4 {
		return "****"
	}

	// Find last hyphen or underscore and mask before it
	lastSep := strings.LastIndexAny(dsn, "-_")
	if lastSep > 0 {
		return dsn[:lastSep] + "-****"
	}

	return "****"
}
