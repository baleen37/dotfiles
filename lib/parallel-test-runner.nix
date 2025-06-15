# Parallel Test Execution System
# 테스트를 병렬로 실행하여 성능을 개선하는 시스템

{
  # Test configuration
  testCategories ? [ "unit" "integration" "e2e" "performance" ]
, # Maximum parallel jobs (auto-detect if null)
  maxJobs ? null
, # Test timeout in seconds
  testTimeout ? 300
, # Enable detailed timing information
  enableTiming ? true
, # Enable test result aggregation
  enableAggregation ? true
}:

let
  # Detect optimal parallelism based on system
  nixSystem = builtins.currentSystem or "unknown";
  systemParts = builtins.split "-" nixSystem;
  currentArch = if builtins.length systemParts >= 1 then builtins.head systemParts else "unknown";

  # CPU core count estimation (conservative)
  estimatedCores = {
    "x86_64" = 4; # Conservative estimate for x86_64
    "aarch64" = 8; # Apple Silicon typically has more cores
    "unknown" = 2; # Safe fallback
  };

  defaultCores = estimatedCores.${currentArch} or 2;
  optimalJobs = if maxJobs != null then maxJobs else defaultCores;

  # Test categories and their properties
  testCategoryConfig = {
    unit = {
      name = "Unit Tests";
      priority = "high";
      timeout = 60;
      parallelizable = true;
      resourceIntensive = false;
    };
    integration = {
      name = "Integration Tests";
      priority = "medium";
      timeout = 180;
      parallelizable = true;
      resourceIntensive = true;
    };
    e2e = {
      name = "End-to-End Tests";
      priority = "medium";
      timeout = 300;
      parallelizable = false; # E2E tests often conflict
      resourceIntensive = true;
    };
    performance = {
      name = "Performance Tests";
      priority = "low";
      timeout = 600;
      parallelizable = false; # Performance tests need isolated resources
      resourceIntensive = true;
    };
  };

  # Get parallelizable test categories
  parallelizableCategories = builtins.filter
    (cat: testCategoryConfig.${cat}.parallelizable or false)
    testCategories;

  sequentialCategories = builtins.filter
    (cat: !(testCategoryConfig.${cat}.parallelizable or false))
    testCategories;

  # Test execution strategies
  executionStrategies = {
    parallel = {
      name = "Parallel Execution";
      description = "Execute compatible tests simultaneously";
      categories = parallelizableCategories;
      maxConcurrency = optimalJobs;
    };
    sequential = {
      name = "Sequential Execution";
      description = "Execute tests one by one";
      categories = sequentialCategories;
      maxConcurrency = 1;
    };
    hybrid = {
      name = "Hybrid Execution";
      description = "Parallel where possible, sequential where necessary";
      categories = testCategories;
      maxConcurrency = optimalJobs;
    };
  };

  # Performance optimization settings
  performanceOptimizations = {
    # Nix build optimizations for test execution
    buildFlags = [
      "--cores"
      (toString optimalJobs)
      "--max-jobs"
      (toString optimalJobs)
      "--option"
      "build-cores"
      (toString optimalJobs)
    ];

    # Resource management
    resourceLimits = {
      memoryPerTest = "512M";
      diskSpacePerTest = "1G";
      networkBandwidth = "shared";
    };

    # Test-specific optimizations
    testOptimizations = {
      unit = {
        isolation = "lightweight";
        caching = "aggressive";
        cleanup = "minimal";
      };
      integration = {
        isolation = "moderate";
        caching = "selective";
        cleanup = "thorough";
      };
      e2e = {
        isolation = "complete";
        caching = "disabled";
        cleanup = "comprehensive";
      };
    };
  };

  # Test timing and metrics
  timingConfig = {
    collectMetrics = enableTiming;
    metricsToCollect = [
      "execution_time"
      "setup_time"
      "cleanup_time"
      "resource_usage"
      "parallelism_efficiency"
    ];

    # Performance targets
    performanceTargets = {
      unit = { maxTime = 30; targetTime = 15; };
      integration = { maxTime = 120; targetTime = 60; };
      e2e = { maxTime = 300; targetTime = 180; };
      performance = { maxTime = 600; targetTime = 300; };
    };
  };

  # Test result aggregation
  aggregationConfig = {
    enabled = enableAggregation;

    # Result format
    outputFormat = {
      summary = true;
      detailed = true;
      timing = enableTiming;
      errors = true;
      warnings = true;
    };

    # Aggregation rules
    aggregationRules = {
      failOnFirstError = false;
      continueOnFailure = true;
      collectAllResults = true;
      generateReport = true;
    };
  };

  # Error handling and recovery
  errorHandling = {
    # Retry configuration
    retry = {
      maxRetries = 2;
      retryDelay = 5;
      retryOnlyFlaky = true;
    };

    # Failure escalation
    escalation = {
      failureThreshold = 0.1; # 10% failure rate
      escalateToSequential = true;
      notifyOnFailure = true;
    };

    # Recovery strategies
    recovery = {
      fallbackToSequential = true;
      isolateFailingTests = true;
      collectDiagnostics = true;
    };
  };

  # Main API functions
  api = {
    # Core execution functions
    getOptimalJobs = optimalJobs;
    getTestCategories = testCategories;
    getParallelizableCategories = parallelizableCategories;
    getSequentialCategories = sequentialCategories;

    # Execution strategies
    getExecutionStrategy = strategy: executionStrategies.${strategy} or executionStrategies.hybrid;
    getAllStrategies = executionStrategies;

    # Performance configuration
    getBuildFlags = performanceOptimizations.buildFlags;
    getResourceLimits = performanceOptimizations.resourceLimits;
    getTestOptimizations = category: performanceOptimizations.testOptimizations.${category} or { };

    # Test configuration
    getTestConfig = category: testCategoryConfig.${category} or { };
    getTestTimeout = category: (testCategoryConfig.${category} or { }).timeout or testTimeout;
    isParallelizable = category: (testCategoryConfig.${category} or { }).parallelizable or false;

    # Timing and metrics
    getTimingConfig = timingConfig;
    getPerformanceTargets = timingConfig.performanceTargets;
    shouldCollectMetrics = enableTiming;

    # Aggregation
    getAggregationConfig = aggregationConfig;
    shouldAggregateResults = enableAggregation;

    # Error handling
    getErrorHandling = errorHandling;
    getRetryConfig = errorHandling.retry;
    getRecoveryStrategy = errorHandling.recovery;

    # System information
    getSystemInfo = {
      nixSystem = nixSystem;
      arch = currentArch;
      estimatedCores = defaultCores;
      configuredJobs = optimalJobs;
    };

    # Utility functions
    calculateExpectedSpeedup =
      let
        parallelCats = builtins.length parallelizableCategories;
        totalCats = builtins.length testCategories;
        parallelRatio = if totalCats > 0 then (parallelCats * 1.0 / totalCats) else 0;
        jobEfficiency = if optimalJobs > 1 then (optimalJobs * 0.8) else 1; # 80% efficiency
      in
      parallelRatio * jobEfficiency;

    estimateExecutionTime = category:
      let
        baseTime = (testCategoryConfig.${category} or { }).timeout or testTimeout;
        isParallel = (testCategoryConfig.${category} or { }).parallelizable or false;
        speedupFactor = if isParallel then optimalJobs else 1;
      in
      baseTime / speedupFactor;

    # Validation functions
    validateConfiguration = {
      validCategories = builtins.all (cat: builtins.hasAttr cat testCategoryConfig) testCategories;
      validJobs = optimalJobs > 0 && optimalJobs <= 32; # Reasonable limits
      validTimeout = testTimeout > 0 && testTimeout <= 3600; # Max 1 hour
    };
  };

in
api
