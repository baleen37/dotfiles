# lib/performance-baselines.nix
# Performance baselines and thresholds for dotfiles project
# Establishes expected performance metrics for different operations

{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
}:

let
  # Import performance framework
  perf = import ./performance.nix { inherit lib pkgs; };

  # System-specific baselines
  systemBaselines = {
    # macOS (Apple Silicon) baselines
    "aarch64-darwin" = {
      build = {
        # Build performance thresholds
        maxEvaluationTimeMs = 5000; # 5 seconds for config evaluation
        maxFlakeLoadTimeMs = 3000; # 3 seconds for flake loading
        maxDerivationTimeMs = 10000; # 10 seconds for simple derivations
      };
      memory = {
        # Memory usage thresholds
        maxConfigMemoryMb = 100; # 100MB for configuration evaluation
        maxEvaluationMemoryMb = 200; # 200MB for Nix evaluation
        maxBuildMemoryMb = 512; # 512MB for build operations
      };
      test = {
        # Test performance thresholds
        maxUnitTestTimeMs = 1000; # 1 second per unit test
        maxIntegrationTestTimeMs = 30000; # 30 seconds per integration test
        maxVmTestTimeMs = 300000; # 5 minutes for VM tests
      };
    };

    # Linux (Intel) baselines
    "x86_64-linux" = {
      build = {
        maxEvaluationTimeMs = 7000; # 7 seconds (slower than ARM)
        maxFlakeLoadTimeMs = 4000; # 4 seconds
        maxDerivationTimeMs = 15000; # 15 seconds
      };
      memory = {
        maxConfigMemoryMb = 150; # 150MB (higher due to x86_64)
        maxEvaluationMemoryMb = 300; # 300MB
        maxBuildMemoryMb = 768; # 768MB
      };
      test = {
        maxUnitTestTimeMs = 1500; # 1.5 seconds
        maxIntegrationTestTimeMs = 45000; # 45 seconds
        maxVmTestTimeMs = 240000; # 4 minutes (faster than macOS VM)
      };
    };

    # Linux (ARM) baselines
    "aarch64-linux" = {
      build = {
        maxEvaluationTimeMs = 6000; # 6 seconds
        maxFlakeLoadTimeMs = 3500; # 3.5 seconds
        maxDerivationTimeMs = 12000; # 12 seconds
      };
      memory = {
        maxConfigMemoryMb = 120; # 120MB
        maxEvaluationMemoryMb = 250; # 250MB
        maxBuildMemoryMb = 640; # 640MB
      };
      test = {
        maxUnitTestTimeMs = 1200; # 1.2 seconds
        maxIntegrationTestTimeMs = 35000; # 35 seconds
        maxVmTestTimeMs = 270000; # 4.5 minutes
      };
    };
  };

  # Get baseline for current system
  getCurrentBaseline = system: systemBaselines.${system} or systemBaselines."x86_64-linux";

  # Operation-specific baselines
  operationBaselines = {
    # Configuration loading baselines
    "config-load" = {
      small = {
        maxTimeMs = 500;
        maxMemoryMb = 10;
      }; # Small configs (<10 attributes)
      medium = {
        maxTimeMs = 2000;
        maxMemoryMb = 50;
      }; # Medium configs (10-50 attributes)
      large = {
        maxTimeMs = 5000;
        maxMemoryMb = 100;
      }; # Large configs (>50 attributes)
    };

    # Module evaluation baselines
    "module-eval" = {
      simple = {
        maxTimeMs = 100;
        maxMemoryMb = 5;
      }; # Simple modules
      complex = {
        maxTimeMs = 1000;
        maxMemoryMb = 20;
      }; # Complex modules with dependencies
      heavy = {
        maxTimeMs = 3000;
        maxMemoryMb = 50;
      }; # Heavy modules (lots of logic)
    };

    # Build operation baselines
    "build-operation" = {
      eval = {
        maxTimeMs = 1000;
        maxMemoryMb = 25;
      }; # Nix evaluation
      fetch = {
        maxTimeMs = 5000;
        maxMemoryMb = 50;
      }; # Network operations
      compile = {
        maxTimeMs = 30000;
        maxMemoryMb = 200;
      }; # Compilation operations
    };

    # Test execution baselines
    "test-execution" = {
      unit = {
        maxTimeMs = 1000;
        maxMemoryMb = 25;
      }; # Unit tests
      integration = {
        maxTimeMs = 15000;
        maxMemoryMb = 100;
      }; # Integration tests
      vm = {
        maxTimeMs = 300000;
        maxMemoryMb = 512;
      }; # VM tests
    };
  };

  # Create baseline measurements for regression testing
  createBaselineMeasurements =
    system:
    let
      baseline = getCurrentBaseline system;
    in
    {
      # Build performance baselines
      buildBaselines = {
        evaluation = perf.regression.createBaseline "config-evaluation" [
          {
            duration_ms = baseline.build.maxEvaluationTimeMs * 0.7;
            memoryAfter = baseline.memory.maxConfigMemoryMb * 1024 * 1024 * 0.7;
            success = true;
          }
          {
            duration_ms = baseline.build.maxEvaluationTimeMs * 0.8;
            memoryAfter = baseline.memory.maxConfigMemoryMb * 1024 * 1024 * 0.8;
            success = true;
          }
          {
            duration_ms = baseline.build.maxEvaluationTimeMs * 0.6;
            memoryAfter = baseline.memory.maxConfigMemoryMb * 1024 * 1024 * 0.6;
            success = true;
          }
        ];

        flakeLoad = perf.regression.createBaseline "flake-loading" [
          {
            duration_ms = baseline.build.maxFlakeLoadTimeMs * 0.7;
            memoryAfter = baseline.memory.maxEvaluationMemoryMb * 1024 * 1024 * 0.7;
            success = true;
          }
          {
            duration_ms = baseline.build.maxFlakeLoadTimeMs * 0.8;
            memoryAfter = baseline.memory.maxEvaluationMemoryMb * 1024 * 1024 * 0.8;
            success = true;
          }
          {
            duration_ms = baseline.build.maxFlakeLoadTimeMs * 0.6;
            memoryAfter = baseline.memory.maxEvaluationMemoryMb * 1024 * 1024 * 0.6;
            success = true;
          }
        ];
      };

      # Test performance baselines
      testBaselines = {
        unitTests = perf.regression.createBaseline "unit-tests" [
          {
            duration_ms = baseline.test.maxUnitTestTimeMs * 0.7;
            memoryAfter = 25 * 1024 * 1024;
            success = true;
          }
          {
            duration_ms = baseline.test.maxUnitTestTimeMs * 0.8;
            memoryAfter = 25 * 1024 * 1024;
            success = true;
          }
          {
            duration_ms = baseline.test.maxUnitTestTimeMs * 0.6;
            memoryAfter = 25 * 1024 * 1024;
            success = true;
          }
        ];

        integrationTests = perf.regression.createBaseline "integration-tests" [
          {
            duration_ms = baseline.test.maxIntegrationTestTimeMs * 0.7;
            memoryAfter = 100 * 1024 * 1024;
            success = true;
          }
          {
            duration_ms = baseline.test.maxIntegrationTestTimeMs * 0.8;
            memoryAfter = 100 * 1024 * 1024;
            success = true;
          }
          {
            duration_ms = baseline.test.maxIntegrationTestTimeMs * 0.6;
            memoryAfter = 100 * 1024 * 1024;
            success = true;
          }
        ];
      };

      # Memory usage baselines
      memoryBaselines = {
        configEvaluation = perf.regression.createBaseline "config-memory" [
          {
            duration_ms = 1000;
            memoryAfter = baseline.memory.maxConfigMemoryMb * 1024 * 1024 * 0.7;
            success = true;
          }
          {
            duration_ms = 1000;
            memoryAfter = baseline.memory.maxConfigMemoryMb * 1024 * 1024 * 0.8;
            success = true;
          }
          {
            duration_ms = 1000;
            memoryAfter = baseline.memory.maxConfigMemoryMb * 1024 * 1024 * 0.6;
            success = true;
          }
        ];
      };
    };

  # Performance regression thresholds
  regressionThresholds = {
    # Allowable performance degradation
    timeRegressionFactor = 1.5; # 50% slower than baseline
    memoryRegressionFactor = 1.3; # 30% more memory than baseline

    # Critical regression thresholds (fail the build)
    criticalTimeRegression = 2.0; # 2x slower than baseline
    criticalMemoryRegression = 1.5; # 50% more memory than baseline

    # Warning thresholds (report but don't fail)
    warningTimeRegression = 1.2; # 20% slower than baseline
    warningMemoryRegression = 1.1; # 10% more memory than baseline
  };

  # Performance monitoring configuration
  monitoringConfig = {
    # Enable/disable performance monitoring
    enabled = true;

    # Sampling configuration
    sampleInterval = 1000; # Sample every 1 second
    maxSamples = 100; # Keep last 100 samples

    # Alerting configuration
    alerts = {
      enabled = true;
      thresholds = regressionThresholds;
    };

    # Reporting configuration
    reports = {
      enabled = true;
      format = "json"; # json, markdown, text
      outputDir = "/tmp/performance-reports";
    };
  };

in
{
  inherit
    systemBaselines
    operationBaselines
    regressionThresholds
    monitoringConfig
    ;

  inherit (perf.regression) createBaseline checkBaseline analyzeTrend;
  inherit (perf.report) summary formatResults;
  inherit (perf.testing) mkPerfTest mkBenchmarkSuite;

  inherit getCurrentBaseline;
  inherit createBaselineMeasurements;
}
