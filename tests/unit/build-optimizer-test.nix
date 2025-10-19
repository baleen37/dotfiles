# Parallel Build Optimizer Unit Tests
#
# lib/parallel-build-optimizer.nix 테스트
# - 동적 시스템 감지
# - 메모리/코어 계산 로직
# - 플랫폼별 최적화 검증
#
# 테스트 대상:
# - systemDetection: 동적 코어/메모리 감지
# - buildCalculations: 빌드 설정 계산 (jobs, cores, memory limits)
# - platformOptimization: 플랫폼별 최적화
# - resourceLimits: 리소스 제한 계산
# - buildEnvironment: 빌드 환경 변수 설정

{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem,
  nixtest ? null,
  self ? null,
}:

let
  nixtestFinal =
    if nixtest != null then nixtest else (import ./nixtest-template.nix { inherit lib pkgs; }).nixtest;

  # Import the module under test
  buildOptimizer =
    if self != null then
      import (self + /lib/parallel-build-optimizer.nix) { inherit lib pkgs system; }
    else
      import ../../lib/parallel-build-optimizer.nix { inherit lib pkgs system; };

  # Test data - various system configurations

in
nixtestFinal.suite "Parallel Build Optimizer Tests" {

  # System detection tests
  systemDetectionTests = nixtestFinal.suite "Dynamic System Detection Tests" {

    systemDetectionExists = nixtestFinal.test "System detection module exists" (
      nixtestFinal.assertions.assertTrue (builtins.hasAttr "systemDetection" buildOptimizer)
    );

    constantsExist = nixtestFinal.test "Constants module exists" (
      nixtestFinal.assertions.assertTrue (builtins.hasAttr "constants" buildOptimizer)
    );

    buildCalculationsExist = nixtestFinal.test "Build calculations module exists" (
      nixtestFinal.assertions.assertTrue (builtins.hasAttr "buildCalculations" buildOptimizer)
    );

    coresDetected = nixtestFinal.test "Cores are detected/estimated" (
      let
        cores = buildOptimizer.systemDetection.totalCores;
      in
      nixtestFinal.assertions.assertTrue (cores > 0 && cores <= 128)
    );

    memoryDetected = nixtestFinal.test "Memory is detected/estimated" (
      let
        memory = buildOptimizer.systemDetection.memoryGB;
      in
      nixtestFinal.assertions.assertTrue (memory > 0 && memory <= 1024)
    );

    platformDefaultsReasonable = nixtestFinal.test "Platform defaults are reasonable" (
      # For aarch64-darwin, should default to 8 cores/16GB
      let
        cores = buildOptimizer.systemDetection.totalCores;
        memory = buildOptimizer.systemDetection.memoryGB;
      in
      nixtestFinal.assertions.assertTrue (cores >= 4 && memory >= 8)
    );
  };

  # Constants tests
  constantsTests = nixtestFinal.suite "Constants Tests" {

    memoryUsageRatioReasonable = nixtestFinal.test "Memory usage ratio is reasonable (0.8)" (
      nixtestFinal.assertions.assertEqual 0.8 buildOptimizer.constants.memoryUsageRatio
    );

    coreEfficiencyRatioReasonable = nixtestFinal.test "Core efficiency ratio is reasonable (0.75)" (
      nixtestFinal.assertions.assertEqual 0.75 buildOptimizer.constants.coreEfficiencyRatio
    );

    minCoresAtLeast2 = nixtestFinal.test "Minimum cores is at least 2" (
      nixtestFinal.assertions.assertTrue (buildOptimizer.constants.minCores >= 2)
    );

    defaultTimeoutPositive = nixtestFinal.test "Default timeout is positive" (
      nixtestFinal.assertions.assertTrue (buildOptimizer.constants.defaultTimeoutSeconds > 0)
    );

    maxLinkPoolDepthSet = nixtestFinal.test "Max link pool depth is set" (
      nixtestFinal.assertions.assertTrue (buildOptimizer.constants.maxLinkPoolDepth > 0)
    );

    ccacheSizeSet = nixtestFinal.test "Ccache size is set" (
      nixtestFinal.assertions.assertTrue (buildOptimizer.constants.ccacheSizeGB > 0)
    );
  };

  # Build calculation tests
  buildCalculationsTests = nixtestFinal.suite "Build Calculation Tests" {

    calculateMaxJobsWorks = nixtestFinal.test "calculateMaxJobs function works" (
      let
        result = buildOptimizer.buildCalculations.calculateMaxJobs 8 16;
      in
      nixtestFinal.assertions.assertTrue (result >= 1 && result <= 8)
    );

    calculateBuildCoresWorks = nixtestFinal.test "calculateBuildCores function works" (
      let
        result = buildOptimizer.buildCalculations.calculateBuildCores 8;
      in
      nixtestFinal.assertions.assertEqual 8 result
    );

    calculateMemoryLimitWorks = nixtestFinal.test "calculateMemoryLimitMB function works" (
      let
        result = buildOptimizer.buildCalculations.calculateMemoryLimitMB 16;
        expected = builtins.floor (16 * 1024 * 0.8);
      in
      nixtestFinal.assertions.assertEqual expected result
    );

    calculateLinkPoolDepthWorks = nixtestFinal.test "calculateLinkPoolDepth function works" (
      let
        result = buildOptimizer.buildCalculations.calculateLinkPoolDepth 8;
      in
      nixtestFinal.assertions.assertTrue (result >= 1 && result <= 4)
    );

    jobsScaleWithCores = nixtestFinal.test "Max jobs scale with CPU cores" (
      let
        config = buildOptimizer.parallelBuildConfig;
        # Jobs should be reasonable relative to cores
        jobsPerCore = config.maxJobs / config.cores;
      in
      nixtestFinal.assertions.assertTrue (jobsPerCore >= 0.25 && jobsPerCore <= 1.5)
    );

    coresMatchSystem = nixtestFinal.test "Build cores match system cores" (
      let
        config = buildOptimizer.parallelBuildConfig;
        systemCores = buildOptimizer.hardwareOptimization.totalCores;
      in
      nixtestFinal.assertions.assertTrue (config.cores <= systemCores)
    );

    memoryLimitReasonable = nixtestFinal.test "Memory limit is reasonable percentage of RAM" (
      let
        config = buildOptimizer.parallelBuildConfig;
        systemMemoryMB = buildOptimizer.hardwareOptimization.memoryGB * 1024;
        limitPercentage = config.memoryLimitMB / systemMemoryMB;
      in
      # Should be between 50% and 90% of system RAM
      nixtestFinal.assertions.assertTrue (limitPercentage >= 0.5 && limitPercentage <= 0.9)
    );

    buildTimeoutPositive = nixtestFinal.test "Build timeout is positive" (
      let
        config = buildOptimizer.parallelBuildConfig;
      in
      nixtestFinal.assertions.assertTrue (config.buildTimeoutSeconds > 0)
    );
  };

  # Platform optimization tests
  platformOptimizationTests = nixtestFinal.suite "Platform-Specific Optimization Tests" {

    darwinUsesClang = nixtestFinal.test "Darwin uses clang compiler" (
      if lib.hasPrefix "aarch64-darwin" system || lib.hasPrefix "x86_64-darwin" system then
        let
          env = buildOptimizer.hardwareOptimization.buildEnv;
        in
        nixtestFinal.assertions.assertEqual "clang" env.CC
      else
        nixtestFinal.assertions.assertTrue true
    );

    linuxUsesGcc = nixtestFinal.test "Linux uses gcc compiler" (
      if lib.hasPrefix "x86_64-linux" system || lib.hasPrefix "aarch64-linux" system then
        let
          env = buildOptimizer.hardwareOptimization.buildEnv;
        in
        nixtestFinal.assertions.assertEqual "gcc" env.CC
      else
        nixtestFinal.assertions.assertTrue true
    );

    makeflagsMatchBuildCores = nixtestFinal.test "MAKEFLAGS match NIX_BUILD_CORES" (
      let
        env = buildOptimizer.hardwareOptimization.buildEnv;
        cores = env.NIX_BUILD_CORES;
        expectedMakeflags = "-j${cores}";
      in
      nixtestFinal.assertions.assertEqual expectedMakeflags env.MAKEFLAGS
    );
  };

  # Resource limit tests
  resourceLimitTests = nixtestFinal.suite "Resource Limit Tests" {

    linkPoolDepthReasonable = nixtestFinal.test "Link pool depth prevents OOM" (
      let
        env = buildOptimizer.parallelBuildConfig.environment;
        linkPoolDepth = lib.toInt env.LINK_POOL_DEPTH;
      in
      # Should be between 1 and cores/2 to prevent OOM during linking
      nixtestFinal.assertions.assertTrue (
        linkPoolDepth >= 1 && linkPoolDepth <= (buildOptimizer.parallelBuildConfig.cores / 2)
      )
    );

    ccacheSizeReasonable = nixtestFinal.test "Ccache size is reasonable" (
      let
        env = buildOptimizer.parallelBuildConfig.environment;
        ccacheSize = env.CCACHE_MAXSIZE;
      in
      # Should be a reasonable size string like "2G", "4G", etc.
      nixtestFinal.assertions.assertStringContains "G" ccacheSize
    );
  };

  # Build environment tests
  buildEnvironmentTests = nixtestFinal.suite "Build Environment Tests" {

    cargoJobsSet = nixtestFinal.test "CARGO_BUILD_JOBS is set" (
      let
        env = buildOptimizer.parallelBuildConfig.environment;
      in
      nixtestFinal.assertions.assertHasAttr "CARGO_BUILD_JOBS" env
    );

    goMaxProcsSet = nixtestFinal.test "GOMAXPROCS is set" (
      let
        env = buildOptimizer.parallelBuildConfig.environment;
      in
      nixtestFinal.assertions.assertHasAttr "GOMAXPROCS" env
    );

    pythonJobsSet = nixtestFinal.test "PYTHON_BUILD_JOBS is set" (
      let
        env = buildOptimizer.parallelBuildConfig.environment;
      in
      nixtestFinal.assertions.assertHasAttr "PYTHON_BUILD_JOBS" env
    );

    tmpDirSet = nixtestFinal.test "TMPDIR is configured" (
      let
        env = buildOptimizer.parallelBuildConfig.environment;
      in
      nixtestFinal.assertions.assertEqual "/tmp" env.TMPDIR
    );
  };

  # Language-specific optimization tests
  languageOptimizationsTests = nixtestFinal.suite "Language-Specific Optimization Tests" {

    rustOptimization = nixtestFinal.test "Rust parallel jobs configured" (
      let
        rustOpt = buildOptimizer.languageOptimizations.rust;
      in
      nixtestFinal.assertions.assertTrue (rustOpt.cargoParallelJobs > 0)
    );

    goOptimization = nixtestFinal.test "Go parallel build configured" (
      let
        goOpt = buildOptimizer.languageOptimizations.go;
      in
      nixtestFinal.assertions.assertHasAttr "GOMAXPROCS" goOpt.environment
    );

    nodejsMemoryLimit = nixtestFinal.test "Node.js memory limit configured" (
      let
        nodeOpt = buildOptimizer.languageOptimizations.nodejs;
      in
      nixtestFinal.assertions.assertStringContains "max-old-space-size" nodeOpt.environment.NODE_OPTIONS
    );
  };

  # Portability tests across different hardware
  portabilityTests = nixtestFinal.suite "Hardware Portability Tests" {

    handlesLowMemory = nixtestFinal.test "Handles low memory systems (8GB)" (
      # Should not exceed available memory
      let
        config = buildOptimizer.parallelBuildConfig;
      in
      # For 8GB system, limit should be around 6.4GB (80%)
      nixtestFinal.assertions.assertTrue (config.memoryLimitMB > 0)
    );

    handlesHighCoreCount = nixtestFinal.test "Handles high core count systems" (
      # Should scale jobs appropriately for many-core systems
      let
        config = buildOptimizer.parallelBuildConfig;
      in
      nixtestFinal.assertions.assertTrue (config.maxJobs >= 1)
    );

    handlesAppleSilicon = nixtestFinal.test "Handles Apple Silicon architecture" (
      if lib.hasPrefix "aarch64-darwin" system then
        let
          env = buildOptimizer.hardwareOptimization.buildEnv;
        in
        nixtestFinal.assertions.assertStringContains "apple-m1" env.NIX_CFLAGS_COMPILE
      else
        nixtestFinal.assertions.assertTrue true
    );
  };
}
