package db

import (
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"ssulmeta-go/pkg/logger"
)

// Migrate runs all pending migrations
func Migrate() error {
	db := GetDB()
	if db == nil {
		return fmt.Errorf("database not initialized")
	}

	// Create migrations table if not exists
	if err := createMigrationsTable(); err != nil {
		return fmt.Errorf("failed to create migrations table: %w", err)
	}

	// Get all migration files
	migrations, err := getMigrationFiles()
	if err != nil {
		return fmt.Errorf("failed to get migration files: %w", err)
	}

	// Run each migration
	for _, migration := range migrations {
		if err := runMigration(migration); err != nil {
			return fmt.Errorf("failed to run migration %s: %w", migration, err)
		}
	}

	logger.Info("all migrations completed successfully")
	return nil
}

func createMigrationsTable() error {
	query := `
	CREATE TABLE IF NOT EXISTS schema_migrations (
		version VARCHAR(255) PRIMARY KEY,
		applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
	)`

	_, err := db.Exec(query)
	return err
}

func getMigrationFiles() ([]string, error) {
	migrationsDir := "internal/db/migrations"

	entries, err := os.ReadDir(migrationsDir)
	if err != nil {
		return nil, err
	}

	var migrations []string
	for _, entry := range entries {
		if !entry.IsDir() && strings.HasSuffix(entry.Name(), ".sql") {
			migrations = append(migrations, entry.Name())
		}
	}

	sort.Strings(migrations)
	return migrations, nil
}

func runMigration(filename string) error {
	// Check if migration already applied
	var count int
	err := db.QueryRow("SELECT COUNT(*) FROM schema_migrations WHERE version = $1", filename).Scan(&count)
	if err != nil {
		return err
	}

	if count > 0 {
		logger.Debug("migration already applied", "migration", filename)
		return nil
	}

	// Read migration file
	content, err := os.ReadFile(filepath.Join("internal/db/migrations", filename))
	if err != nil {
		return err
	}

	// Execute migration
	tx, err := db.Begin()
	if err != nil {
		return err
	}
	defer func() {
		if rollbackErr := tx.Rollback(); rollbackErr != nil {
			// Log rollback error but don't override the main error
			slog.Warn("Failed to rollback transaction", "error", rollbackErr)
		}
	}()

	if _, err := tx.Exec(string(content)); err != nil {
		return err
	}

	// Record migration
	if _, err := tx.Exec("INSERT INTO schema_migrations (version) VALUES ($1)", filename); err != nil {
		return err
	}

	if err := tx.Commit(); err != nil {
		return err
	}

	logger.Info("migration applied successfully", "migration", filename)
	return nil
}
