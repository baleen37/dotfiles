# Test Suite Configuration
# Day 16: Green Phase - Centralized test configuration management

{ pkgs, src ? ../., ... }:

{
  # Global test configuration
  testConfig = {
    # Performance targets
    performance = {
      maxExecutionTimeMs = 5000;     # 5 seconds max per test suite
      maxMemoryUsageKB = 50000;      # 50MB max memory usage
      targetSpeedupPercent = 50;     # 50% execution time reduction target
      targetMemoryReductionPercent = 30; # 30% memory reduction target
    };

    # Test environment settings
    environment = {
      enableParallelExecution = true;
      maxConcurrentTests = 4;
      enableMemoryOptimization = true;
      enablePerformanceProfiling = true;
      timeoutSeconds = 30;
    };

    # Test categories and priorities
    categories = {
      unit = {
        priority = "high";
        timeout = 10;
        memoryLimit = 10000; # 10MB
      };
      integration = {
        priority = "high";
        timeout = 20;
        memoryLimit = 20000; # 20MB
      };
      e2e = {
        priority = "medium";
        timeout = 60;
        memoryLimit = 30000; # 30MB
      };
      performance = {
        priority = "low";
        timeout = 120;
        memoryLimit = 40000; # 40MB
      };
    };

    # Optimization settings
    optimization = {
      enableModularStructure = true;
      enableSharedUtilities = true;
      enableTestIsolation = true;
      enableEarlyExit = true;
      enableMemoryCleanup = true;
    };
  };

  # Test suite registry
  testSuites = {
    # Modular test suites
    modular = {
      unit = {
        path = "modules/unit/modular-unit-runner.nix";
        description = "Optimized unit tests with modular structure";
        estimatedTimeMs = 1000;
      };
      integration = {
        path = "modules/integration/modular-integration-runner.nix";
        description = "Optimized integration tests with isolation";
        estimatedTimeMs = 2000;
      };
      e2e = {
        path = "modules/e2e/modular-e2e-runner.nix";
        description = "Optimized end-to-end tests";
        estimatedTimeMs = 3000;
      };
    };

    # Legacy test suites (for comparison)
    legacy = {
      unit = {
        path = "unit/claude-cli-comprehensive-unit.nix";
        description = "Original comprehensive unit tests";
        estimatedTimeMs = 5000;
      };
      integration = {
        path = "integration/claude-cli-comprehensive-integration.nix";
        description = "Original comprehensive integration tests";
        estimatedTimeMs = 8000;
      };
      e2e = {
        path = "e2e/claude-cli-comprehensive-e2e.nix";
        description = "Original comprehensive e2e tests";
        estimatedTimeMs = 12000;
      };
    };
  };

  # Performance benchmarks
  benchmarks = {
    baseline = {
      executionTimeMs = 25000;  # Current total execution time
      memoryUsageKB = 71000;    # Current memory usage
    };
    targets = {
      executionTimeMs = 12500;  # 50% reduction target
      memoryUsageKB = 49700;    # 30% reduction target
    };
  };

  # Utility functions
  utils = {
    # Get test configuration for a specific category
    getTestConfig = category:
      if pkgs.lib.hasAttr category testConfig.categories
      then testConfig.categories.${category}
      else testConfig.categories.unit;

    # Check if optimization is enabled
    isOptimizationEnabled = optimization:
      testConfig.optimization.${optimization} or false;

    # Get performance target
    getPerformanceTarget = metric:
      testConfig.performance.${metric} or 0;
  };
}
