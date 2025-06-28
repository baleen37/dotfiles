package db

import (
	"context"
	"database/sql"
	"fmt"
	"sync"
	"time"

	"ssulmeta-go/internal/config"
	"ssulmeta-go/pkg/logger"

	_ "github.com/lib/pq"
)

// Manager handles database connections with thread safety and monitoring
type Manager struct {
	db     *sql.DB
	mu     sync.RWMutex
	config *config.DatabaseConfig

	// Monitoring metrics
	lastHealthCheck time.Time
	isHealthy       bool
	reconnectCount  int
}

// NewManager creates a new database manager
func NewManager(cfg *config.DatabaseConfig) (*Manager, error) {
	manager := &Manager{
		config:    cfg,
		isHealthy: false,
	}

	if err := manager.connect(); err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	return manager, nil
}

// connect establishes a database connection
func (m *Manager) connect() error {
	m.mu.Lock()
	defer m.mu.Unlock()

	dsn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		m.config.Host,
		m.config.Port,
		m.config.User,
		m.config.Password,
		m.config.DBName,
		m.config.SSLMode,
	)

	db, err := sql.Open("postgres", dsn)
	if err != nil {
		return fmt.Errorf("failed to open database: %w", err)
	}

	// Configure connection pool
	if m.config.MaxConnections > 0 {
		db.SetMaxOpenConns(m.config.MaxConnections)
	}
	if m.config.MaxIdleConnections > 0 {
		db.SetMaxIdleConns(m.config.MaxIdleConnections)
	}
	db.SetConnMaxLifetime(time.Hour)

	// Test connection
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := db.PingContext(ctx); err != nil {
		if closeErr := db.Close(); closeErr != nil {
			logger.Error("failed to close database after ping failure", "error", closeErr)
		}
		return fmt.Errorf("failed to ping database: %w", err)
	}

	// Close old connection if exists
	if m.db != nil {
		if err := m.db.Close(); err != nil {
			logger.Warn("failed to close old database connection", "error", err)
		}
	}

	m.db = db
	m.isHealthy = true
	m.lastHealthCheck = time.Now()

	logger.Info("database connection established",
		"host", m.config.Host,
		"database", m.config.DBName,
		"reconnectCount", m.reconnectCount,
	)

	return nil
}

// DB returns the database connection with health check
func (m *Manager) DB() (*sql.DB, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	if m.db == nil {
		return nil, fmt.Errorf("database connection not initialized")
	}

	return m.db, nil
}

// QueryContext executes a query with context
func (m *Manager) QueryContext(ctx context.Context, query string, args ...interface{}) (*sql.Rows, error) {
	db, err := m.DB()
	if err != nil {
		return nil, err
	}

	logger.Debug("executing query", "query", query, "args", args)
	return db.QueryContext(ctx, query, args...)
}

// QueryRowContext executes a query that returns at most one row
func (m *Manager) QueryRowContext(ctx context.Context, query string, args ...interface{}) *sql.Row {
	db, err := m.DB()
	if err != nil {
		// Return a row that will error when Scan is called
		return &sql.Row{}
	}

	logger.Debug("executing query row", "query", query, "args", args)
	return db.QueryRowContext(ctx, query, args...)
}

// ExecContext executes a query without returning any rows
func (m *Manager) ExecContext(ctx context.Context, query string, args ...interface{}) (sql.Result, error) {
	db, err := m.DB()
	if err != nil {
		return nil, err
	}

	logger.Debug("executing statement", "query", query, "args", args)
	return db.ExecContext(ctx, query, args...)
}

// BeginTx starts a transaction with context
func (m *Manager) BeginTx(ctx context.Context, opts *sql.TxOptions) (*sql.Tx, error) {
	db, err := m.DB()
	if err != nil {
		return nil, err
	}

	logger.Debug("beginning transaction")
	return db.BeginTx(ctx, opts)
}

// HealthCheck performs a health check on the database connection
func (m *Manager) HealthCheck(ctx context.Context) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	if m.db == nil {
		m.isHealthy = false
		return fmt.Errorf("database connection is nil")
	}

	if err := m.db.PingContext(ctx); err != nil {
		m.isHealthy = false
		logger.Error("database health check failed", "error", err)
		return fmt.Errorf("health check failed: %w", err)
	}

	m.isHealthy = true
	m.lastHealthCheck = time.Now()
	return nil
}

// IsHealthy returns the current health status
func (m *Manager) IsHealthy() bool {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.isHealthy
}

// Reconnect attempts to reconnect to the database
func (m *Manager) Reconnect() error {
	logger.Info("attempting to reconnect to database")
	m.reconnectCount++
	return m.connect()
}

// Stats returns connection pool statistics
func (m *Manager) Stats() sql.DBStats {
	m.mu.RLock()
	defer m.mu.RUnlock()

	if m.db == nil {
		return sql.DBStats{}
	}

	return m.db.Stats()
}

// Close closes the database connection
func (m *Manager) Close() error {
	m.mu.Lock()
	defer m.mu.Unlock()

	if m.db != nil {
		logger.Info("closing database connection")
		err := m.db.Close()
		m.db = nil
		m.isHealthy = false
		return err
	}

	return nil
}

// MonitorConnection starts a goroutine to monitor connection health
func (m *Manager) MonitorConnection(ctx context.Context, interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			logger.Info("stopping database connection monitor")
			return
		case <-ticker.C:
			if err := m.HealthCheck(ctx); err != nil {
				logger.Error("health check failed", "error", err)
				// Attempt to reconnect
				if reconnectErr := m.Reconnect(); reconnectErr != nil {
					logger.Error("reconnection failed", "error", reconnectErr)
				}
			} else {
				// Log connection pool stats periodically
				stats := m.Stats()
				logger.Debug("database connection pool stats",
					"openConnections", stats.OpenConnections,
					"inUse", stats.InUse,
					"idle", stats.Idle,
					"waitCount", stats.WaitCount,
					"waitDuration", stats.WaitDuration,
					"maxIdleClosed", stats.MaxIdleClosed,
					"maxLifetimeClosed", stats.MaxLifetimeClosed,
				)
			}
		}
	}
}
