# lib/performance.nix
# Performance testing and benchmarking framework
# Provides comprehensive performance measurement utilities for Nix configurations

{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
}:

let
  inherit (builtins)
    currentSystem
    toString
    typeOf
    attrNames
    listToAttrs
    ;
  inherit (lib) optionalAttrs optional;

  # Core performance measurement utilities
  perf = {
    # Time measurement utilities
    time = {
      # Get current timestamp in nanoseconds
      now = builtins.currentTime;

      # Measure execution time of a function
      measure =
        func:
        let
          start = perf.time.now;
          result = builtins.seq start (builtins.tryEval func);
          end = perf.time.now;
          duration = end - start;
        in
        {
          inherit (result) value;
          inherit duration start end;
          success = result.success;
          duration_ms = duration / 1000000;
          duration_s = duration / 1000000000;
        };

      # Benchmark function with multiple runs
      benchmark =
        func: iterations:
        let
          results = builtins.genList (i: perf.time.measure func) iterations;
          durations = map (r: r.duration) (builtins.filter (r: r.success) results);
          successfulRuns = builtins.length durations;
          totalDuration = lib.foldl (acc: d: acc + d) 0 durations;
          averageDuration = if successfulRuns > 0 then totalDuration / successfulRuns else 0;
        in
        if successfulRuns > 0 then
          {
            iterations = successfulRuns;
            inherit totalDuration averageDuration;
            minDuration = lib.foldl (acc: d: if d < acc then d else acc) (builtins.head durations) durations;
            maxDuration = lib.foldl (acc: d: if d > acc then d else acc) (builtins.head durations) durations;
            successRate = successfulRuns / builtins.length results;
            results = results;
            averageDuration_ms = averageDuration / 1000000;
            averageDuration_s = averageDuration / 1000000000;
          }
        else
          {
            iterations = 0;
            totalDuration = 0;
            averageDuration = 0;
            minDuration = 0;
            maxDuration = 0;
            successRate = 0;
            results = results;
            averageDuration_ms = 0;
            averageDuration_s = 0;
          };
    };

    # Memory usage measurement utilities
    memory = {
      # Estimate memory usage of a Nix value
      estimateSize =
        value:
        let
          result = builtins.tryEval (
            if typeOf value == "string" then
              builtins.stringLength value
            else if typeOf value == "list" then
              lib.foldl (acc: elem: acc + perf.memory.estimateSize elem) 0 value
            else if typeOf value == "set" then
              lib.foldl (acc: name: acc + builtins.stringLength name + perf.memory.estimateSize value.${name}) 0 (
                attrNames value
              )
            else if typeOf value == "lambda" then
              100 # Estimated function size
            else
              8 # Basic type size
          );
        in
        if result.success then result.value else 0;

      # Monitor memory usage during function execution
      monitor =
        func:
        let
          beforeSize = perf.memory.estimateSize func;
          result = perf.time.measure func;
          afterSize = perf.memory.estimateSize result.value;
        in
        result
        // {
          memoryBefore = beforeSize;
          memoryAfter = afterSize;
          memoryDelta = afterSize - beforeSize;
        };
    };

    # Build performance measurement
    build = {
      # Measure Nix evaluation performance
      measureEval = expr: perf.time.measure (builtins.deepSeq expr expr);

      # Measure derivation build time (simulated)
      measureDerivation = drv: perf.time.measure (builtins.isDerivation drv);

      # Benchmark configuration complexity
      measureConfigComplexity =
        config:
        let
          attrs = attrNames config;
          attrCount = builtins.length attrs;
          totalSize = perf.memory.estimateSize config;
          evalResult = perf.build.measureEval config;
        in
        evalResult
        // {
          attributeCount = attrCount;
          estimatedSize = totalSize;
          complexity = {
            attributes = attrCount;
            size_bytes = totalSize;
            size_kb = totalSize / 1024;
            size_mb = totalSize / (1024 * 1024);
          };
        };
    };

    # Resource usage monitoring
    resources = {
      # Create resource profile for an operation
      profile =
        operation:
        let
          memResult = perf.memory.monitor operation;
          timeResult = perf.time.measure operation;
        in
        memResult
        // {
          cpu = {
            # CPU usage estimation based on time complexity
            estimatedCycles = timeResult.duration * 1000; # Rough estimate
            efficiency = if memResult.duration_ms > 0 then memResult.memoryDelta / memResult.duration_ms else 0;
          };
          profile = {
            timestamp = perf.time.now;
            operation = "profiled_operation";
            hostSystem = currentSystem;
          };
        };

      # Compare resource usage between operations
      compare =
        op1: op2:
        let
          profile1 = perf.resources.profile op1;
          profile2 = perf.resources.profile op2;
        in
        {
          operation1 = profile1;
          operation2 = profile2;
          comparison = {
            timeRatio = if profile2.duration_ms > 0 then profile1.duration_ms / profile2.duration_ms else 0;
            memoryRatio = if profile2.memoryAfter > 0 then profile1.memoryAfter / profile2.memoryAfter else 0;
            efficiency =
              if profile1.duration_ms > 0 && profile2.duration_ms > 0 then
                profile2.duration_ms / profile1.duration_ms
              else
                1.0;
          };
        };
    };

    # Performance regression testing
    regression = {
      # Create performance baseline
      createBaseline =
        name: measurements:
        let
          avgTime = lib.foldl (acc: m: acc + m.duration_ms) 0 measurements / builtins.length measurements;
          avgMemory = lib.foldl (acc: m: acc + m.memoryAfter) 0 measurements / builtins.length measurements;
        in
        {
          inherit name;
          baseline = {
            avgTime_ms = avgTime;
            avgMemory_bytes = avgMemory;
            maxTime_ms = lib.foldl (acc: m: if m.duration_ms > acc then m.duration_ms else acc) 0 measurements;
            maxMemory_bytes = lib.foldl (
              acc: m: if m.memoryAfter > acc then m.memoryAfter else acc
            ) 0 measurements;
            sampleCount = builtins.length measurements;
            timestamp = perf.time.now;
          };
        };

      # Check performance against baseline
      checkBaseline =
        baseline: measurement: thresholds:
        let
          timeRatio =
            if baseline.baseline.avgTime_ms > 0 then
              measurement.duration_ms / baseline.baseline.avgTime_ms
            else
              1.0;
          memoryRatio =
            if baseline.baseline.avgMemory_bytes > 0 then
              measurement.memoryAfter / baseline.baseline.avgMemory_bytes
            else
              1.0;
          timeThreshold = thresholds.time or 2.0; # 2x slower threshold
          memoryThreshold = thresholds.memory or 1.5; # 1.5x memory threshold
        in
        {
          passed = timeRatio <= timeThreshold && memoryRatio <= memoryThreshold;
          timeRegression = timeRatio > timeThreshold;
          memoryRegression = memoryRatio > memoryThreshold;
          metrics = {
            timeRatio = timeRatio;
            memoryRatio = memoryRatio;
            timeThreshold = timeThreshold;
            memoryThreshold = memoryThreshold;
            actualTime = measurement.duration_ms;
            baselineTime = baseline.baseline.avgTime_ms;
            actualMemory = measurement.memoryAfter;
            baselineMemory = baseline.baseline.avgMemory_bytes;
          };
        };

      # Performance trend analysis
      analyzeTrend =
        measurements:
        let
          len = builtins.length measurements;
          sorted = builtins.sort (a: b: a.duration_ms < b.duration_ms) measurements;
          recent = builtins.sublist (lib.max 0 (len - 5)) 5 sorted; # Last 5 measurements
          recentAvg =
            if builtins.length recent > 0 then
              lib.foldl (acc: m: acc + m.duration_ms) 0 recent / builtins.length recent
            else
              0;
          overallAvg = if len > 0 then lib.foldl (acc: m: acc + m.duration_ms) 0 measurements / len else 0;
        in
        {
          trend =
            if recentAvg > overallAvg * 1.1 then
              "degrading"
            else if recentAvg < overallAvg * 0.9 then
              "improving"
            else
              "stable";
          recentAverage = recentAvg;
          overallAverage = overallAvg;
          sampleCount = len;
          direction = if recentAvg > overallAvg then "up" else "down";
          changePercent = if overallAvg > 0 then ((recentAvg - overallAvg) / overallAvg) * 100 else 0;
        };
    };

    # Performance reporting
    report = {
      # Generate performance summary
      summary =
        measurements:
        let
          times = map (m: m.duration_ms) measurements;
          memories = map (m: m.memoryAfter) measurements;
          successful = builtins.filter (m: m.success) measurements;
        in
        {
          totalMeasurements = builtins.length measurements;
          successfulMeasurements = builtins.length successful;
          successRate =
            if builtins.length measurements > 0 then
              builtins.length successful / builtins.length measurements
            else
              0;
          timing = {
            avg_ms =
              if builtins.length times > 0 then
                lib.foldl (acc: t: acc + t) 0 times / builtins.length times
              else
                0;
            min_ms =
              if builtins.length times > 0 then
                lib.foldl (acc: t: if t < acc then t else acc) (builtins.head times) times
              else
                0;
            max_ms =
              if builtins.length times > 0 then
                lib.foldl (acc: t: if t > acc then t else acc) (builtins.head times) times
              else
                0;
            total_ms = lib.foldl (acc: t: acc + t) 0 times;
          };
          memory = {
            avg_bytes =
              if builtins.length memories > 0 then
                lib.foldl (acc: m: acc + m) 0 memories / builtins.length memories
              else
                0;
            min_bytes =
              if builtins.length memories > 0 then
                lib.foldl (acc: m: if m < acc then m else acc) (builtins.head memories) memories
              else
                0;
            max_bytes =
              if builtins.length memories > 0 then
                lib.foldl (acc: m: if m > acc then m else acc) (builtins.head memories) memories
              else
                0;
            total_bytes = lib.foldl (acc: m: acc + m) 0 memories;
          };
        };

      # Format performance results for display
      formatResults = results: ''
        # Performance Test Results

        ## Summary
        - Total measurements: ${toString results.totalMeasurements}
        - Success rate: ${toString (results.successRate * 100)}%

        ## Timing Metrics
        - Average: ${toString results.timing.avg_ms}ms
        - Min: ${toString results.timing.min_ms}ms
        - Max: ${toString results.timing.max_ms}ms
        - Total: ${toString results.timing.total_ms}ms

        ## Memory Metrics
        - Average: ${toString results.memory.avg_bytes} bytes
        - Min: ${toString results.memory.min_bytes} bytes
        - Max: ${toString results.memory.max_bytes} bytes
        - Total: ${toString results.memory.total_bytes} bytes

        Generated at: ${toString (perf.time.now)}
      '';
    };

    # Test helpers for performance testing
    testing = {
      # Create performance test
      mkPerfTest = name: operation: expectedThresholds: {
        inherit name operation expectedThresholds;
        type = "performance-test";

        # Execute the performance test
        run =
          let
            result = perf.resources.profile operation;
            passed =
              (
                if expectedThresholds ? maxTimeMs then result.duration_ms <= expectedThresholds.maxTimeMs else true
              )
              && (
                if expectedThresholds ? maxMemoryBytes then
                  result.memoryAfter <= expectedThresholds.maxMemoryBytes
                else
                  true
              );
          in
          result // { inherit passed; };
      };

      # Benchmark test suite
      mkBenchmarkSuite =
        name: tests:
        let
          results = builtins.listToAttrs (
            map (test: {
              name = test.name;
              value = test.run;
            }) tests
          );
        in
        {
          inherit name results;
          type = "benchmark-suite";
          summary = perf.report.summary (builtins.attrValues results);
        };
    };
  };

in
{
  inherit perf;

  # Legacy exports for compatibility
  inherit (perf.time) measure benchmark;
  inherit (perf.memory) estimateSize monitor;
  inherit (perf.build) measureEval measureDerivation measureConfigComplexity;
  inherit (perf.resources) profile compare;
  inherit (perf.regression) createBaseline checkBaseline analyzeTrend;
  inherit (perf.report) summary formatResults;
  inherit (perf.testing) mkPerfTest mkBenchmarkSuite;
}
