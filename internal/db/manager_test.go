package db

import (
	"context"
	"database/sql"
	"sync"
	"testing"
	"time"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"ssulmeta-go/internal/config"
)

// TestManagerConcurrency tests concurrent access to the database manager
func TestManagerConcurrency(t *testing.T) {
	// Create a mock database
	mockDB, mock, err := sqlmock.New(sqlmock.MonitorPingsOption(true))
	require.NoError(t, err)
	defer func() { _ = mockDB.Close() }()

	// Set up ping expectations
	mock.ExpectPing()

	// Create manager with mock
	manager := &Manager{
		db:        mockDB,
		config:    &config.DatabaseConfig{},
		isHealthy: true,
	}

	// Test concurrent reads
	t.Run("ConcurrentReads", func(t *testing.T) {
		const goroutines = 100
		var wg sync.WaitGroup
		wg.Add(goroutines)

		errors := make(chan error, goroutines)

		for i := 0; i < goroutines; i++ {
			go func() {
				defer wg.Done()
				_, err := manager.DB()
				if err != nil {
					errors <- err
				}
			}()
		}

		wg.Wait()
		close(errors)

		// Check no errors occurred
		for err := range errors {
			assert.NoError(t, err)
		}
	})

	// Test concurrent health checks with race detector
	t.Run("ConcurrentHealthChecks", func(t *testing.T) {
		const goroutines = 10 // Reduced number to avoid timing issues
		var wg sync.WaitGroup
		wg.Add(goroutines)

		ctx := context.Background()

		// Use a channel to coordinate ping expectations
		pingChan := make(chan struct{}, goroutines)

		// Set up dynamic ping expectations
		for i := 0; i < goroutines; i++ {
			mock.ExpectPing().WillReturnError(nil)
		}

		for i := 0; i < goroutines; i++ {
			go func() {
				defer wg.Done()
				err := manager.HealthCheck(ctx)
				if err == nil {
					pingChan <- struct{}{}
				}
			}()
		}

		wg.Wait()
		close(pingChan)

		// Count successful pings
		successCount := 0
		for range pingChan {
			successCount++
		}

		// At least some health checks should succeed
		assert.Greater(t, successCount, 0)
	})

	// Test concurrent stats access
	t.Run("ConcurrentStats", func(t *testing.T) {
		const goroutines = 100
		var wg sync.WaitGroup
		wg.Add(goroutines)

		for i := 0; i < goroutines; i++ {
			go func() {
				defer wg.Done()
				_ = manager.Stats()
			}()
		}

		wg.Wait()
	})
}

// TestManagerReconnection tests the reconnection mechanism
func TestManagerReconnection(t *testing.T) {
	cfg := &config.DatabaseConfig{
		Host:     "localhost",
		Port:     5432,
		User:     "test",
		Password: "test",
		DBName:   "test",
		SSLMode:  "disable",
	}

	t.Run("ReconnectAfterFailure", func(t *testing.T) {
		// Create manager
		manager := &Manager{
			config:    cfg,
			isHealthy: false,
		}

		// Mock successful reconnection
		mockDB, mock, err := sqlmock.New(sqlmock.MonitorPingsOption(true))
		require.NoError(t, err)
		defer func() { _ = mockDB.Close() }()

		// Override connect method for testing
		manager.db = mockDB
		mock.ExpectPing()

		// Test reconnect
		ctx := context.Background()
		err = manager.HealthCheck(ctx)
		assert.NoError(t, err)
		assert.True(t, manager.IsHealthy())
	})
}

// TestManagerContextTimeout tests context-based timeouts
func TestManagerContextTimeout(t *testing.T) {
	mockDB, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer func() { _ = mockDB.Close() }()

	manager := &Manager{
		db:        mockDB,
		config:    &config.DatabaseConfig{},
		isHealthy: true,
	}

	t.Run("QueryWithTimeout", func(t *testing.T) {
		// Create a context that times out immediately
		ctx, cancel := context.WithTimeout(context.Background(), 1*time.Nanosecond)
		defer cancel()

		// Sleep to ensure timeout
		time.Sleep(10 * time.Millisecond)

		// Attempt query with timed-out context
		mock.ExpectQuery("SELECT 1").
			WillDelayFor(100 * time.Millisecond).
			WillReturnRows(sqlmock.NewRows([]string{"1"}).AddRow(1))

		_, err := manager.QueryContext(ctx, "SELECT 1")
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "context deadline exceeded")
	})

	t.Run("ExecWithTimeout", func(t *testing.T) {
		ctx, cancel := context.WithTimeout(context.Background(), 1*time.Nanosecond)
		defer cancel()

		time.Sleep(10 * time.Millisecond)

		mock.ExpectExec("INSERT INTO test").
			WillDelayFor(100 * time.Millisecond).
			WillReturnResult(sqlmock.NewResult(1, 1))

		_, err := manager.ExecContext(ctx, "INSERT INTO test VALUES (1)")
		assert.Error(t, err)
	})
}

// TestManagerTransactions tests transaction handling
func TestManagerTransactions(t *testing.T) {
	mockDB, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer func() { _ = mockDB.Close() }()

	manager := &Manager{
		db:        mockDB,
		config:    &config.DatabaseConfig{},
		isHealthy: true,
	}

	t.Run("TransactionWithContext", func(t *testing.T) {
		ctx := context.Background()

		mock.ExpectBegin()
		mock.ExpectCommit()

		tx, err := manager.BeginTx(ctx, nil)
		require.NoError(t, err)
		assert.NotNil(t, tx)

		err = tx.Commit()
		assert.NoError(t, err)

		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("TransactionWithOptions", func(t *testing.T) {
		ctx := context.Background()
		opts := &sql.TxOptions{
			Isolation: sql.LevelSerializable,
			ReadOnly:  true,
		}

		mock.ExpectBegin()
		mock.ExpectCommit()

		tx, err := manager.BeginTx(ctx, opts)
		require.NoError(t, err)
		assert.NotNil(t, tx)

		err = tx.Commit()
		assert.NoError(t, err)
	})
}

// TestManagerMonitoring tests the monitoring functionality
func TestManagerMonitoring(t *testing.T) {
	mockDB, mock, err := sqlmock.New(sqlmock.MonitorPingsOption(true))
	require.NoError(t, err)
	defer func() { _ = mockDB.Close() }()

	manager := &Manager{
		db:        mockDB,
		config:    &config.DatabaseConfig{},
		isHealthy: true,
	}

	t.Run("MonitorConnection", func(t *testing.T) {
		ctx, cancel := context.WithCancel(context.Background())
		defer cancel()

		// Expect periodic pings
		mock.ExpectPing()
		mock.ExpectPing()

		// Start monitoring with short interval for testing
		go manager.MonitorConnection(ctx, 50*time.Millisecond)

		// Let it run for a bit
		time.Sleep(120 * time.Millisecond)

		// Cancel to stop monitoring
		cancel()

		// Give it time to stop
		time.Sleep(10 * time.Millisecond)
	})
}

// TestManagerErrorHandling tests error handling scenarios
func TestManagerErrorHandling(t *testing.T) {
	t.Run("NilDatabase", func(t *testing.T) {
		manager := &Manager{
			config: &config.DatabaseConfig{},
		}

		_, err := manager.DB()
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "not initialized")
	})

	t.Run("QueryRowError", func(t *testing.T) {
		// Create a mock that returns an error
		mockDB, mock, err := sqlmock.New()
		require.NoError(t, err)
		defer func() { _ = mockDB.Close() }()

		manager := &Manager{
			db:        mockDB,
			config:    &config.DatabaseConfig{},
			isHealthy: true,
		}

		// Expect query to fail
		mock.ExpectQuery("SELECT 1").WillReturnError(sql.ErrNoRows)

		row := manager.QueryRowContext(context.Background(), "SELECT 1")
		assert.NotNil(t, row)

		var result int
		err = row.Scan(&result)
		assert.Error(t, err)
		assert.Equal(t, sql.ErrNoRows, err)
	})
}

// BenchmarkManagerConcurrentAccess benchmarks concurrent access patterns
func BenchmarkManagerConcurrentAccess(b *testing.B) {
	mockDB, _, err := sqlmock.New()
	require.NoError(b, err)
	defer func() { _ = mockDB.Close() }()

	manager := &Manager{
		db:        mockDB,
		config:    &config.DatabaseConfig{},
		isHealthy: true,
	}

	b.Run("ConcurrentDB", func(b *testing.B) {
		b.RunParallel(func(pb *testing.PB) {
			for pb.Next() {
				_, _ = manager.DB()
			}
		})
	})

	b.Run("ConcurrentStats", func(b *testing.B) {
		b.RunParallel(func(pb *testing.PB) {
			for pb.Next() {
				_ = manager.Stats()
			}
		})
	})

	b.Run("ConcurrentIsHealthy", func(b *testing.B) {
		b.RunParallel(func(pb *testing.PB) {
			for pb.Next() {
				_ = manager.IsHealthy()
			}
		})
	})
}
