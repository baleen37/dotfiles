package main

import (
	"flag"
	"fmt"
	"log"
	"os"

	"ssulmeta-go/internal/config"
	"ssulmeta-go/internal/db"
	"ssulmeta-go/pkg/logger"
)

var (
	version = "0.1.0"
	build   = "dev"
)

func main() {
	// Command line flags
	var (
		showVersion = flag.Bool("version", false, "Show version information")
		showHelp    = flag.Bool("help", false, "Show help")
		envFlag     = flag.String("env", "", "Override APP_ENV")
	)

	flag.Parse()

	if *showVersion {
		fmt.Printf("YouTube Shorts Generator v%s (build: %s)\n", version, build)
		os.Exit(0)
	}

	if *showHelp {
		printHelp()
		os.Exit(0)
	}

	// Override environment if specified
	if *envFlag != "" {
		if err := os.Setenv("APP_ENV", *envFlag); err != nil {
			log.Fatalf("Failed to set environment: %v", err)
		}
	}

	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Initialize logger
	if err := logger.Init(&cfg.Logging); err != nil {
		log.Fatalf("Failed to initialize logger: %v", err)
	}

	logger.Info("starting YouTube Shorts Generator",
		"version", version,
		"env", cfg.App.Env,
		"debug", cfg.App.Debug,
	)

	// Initialize database
	if err := db.Init(&cfg.Database); err != nil {
		logger.Error("failed to initialize database", "error", err)
		os.Exit(1)
	}
	defer func() {
		if err := db.Close(); err != nil {
			log.Printf("Failed to close database: %v", err)
		}
	}()

	// Run migrations
	if err := db.Migrate(); err != nil {
		logger.Error("failed to run migrations", "error", err)
		os.Exit(1)
	}

	logger.Info("initialization completed successfully")

	// TODO: Implement command handling
	fmt.Println("YouTube Shorts Generator is ready!")
	fmt.Println("Use -help to see available commands")
}

func printHelp() {
	fmt.Println("YouTube Shorts Generator")
	fmt.Println()
	fmt.Println("Usage:")
	fmt.Println("  youtube-shorts-generator [flags] [command]")
	fmt.Println()
	fmt.Println("Flags:")
	fmt.Println("  -help      Show this help message")
	fmt.Println("  -version   Show version information")
	fmt.Println("  -env       Override APP_ENV (test, local, dev, prod)")
	fmt.Println()
	fmt.Println("Commands:")
	fmt.Println("  generate   Generate a new video")
	fmt.Println("  list       List generated videos")
	fmt.Println("  upload     Upload a video to YouTube")
	fmt.Println("  config     Show current configuration")
}
