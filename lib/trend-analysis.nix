# lib/trend-analysis.nix
# Statistical trend analysis and regression detection system
# Extracted from tests/unit/trend-analysis-test.nix for reusability

{
  lib,
  pkgs,
}:

rec {
  # Statistical trend analysis
  analyzeStatisticalTrend =
    measurements:
    let
      count = builtins.length measurements;
      values = map (m: m.duration_ms) measurements;

      # Calculate mean
      mean = if count > 0 then (lib.foldl (acc: v: acc + v) 0 values) / count else 0;

      # Calculate variance and standard deviation
      variance =
        if count > 1 then (lib.foldl (acc: v: acc + (v - mean) * (v - mean)) 0 values) / (count - 1) else 0;
      # Use builtins.sqrt if available (Nix 2.19+), otherwise approximation
      stdDev = if variance > 0 then
        if builtins ? sqrt then builtins.sqrt variance
        # Newton's method approximation for sqrt
        else
          let
            sqrtIter = x: epsilon: n:
              if n == 0 then 0
              else if n < 0 then 0
              else
                let
                  next = x / 2.0 + variance / (2.0 * x);
                in
                if builtins.abs (next - x) < epsilon then next else sqrtIter next epsilon (n - 1);
            in
            sqrtIter (variance / 2.0 + 0.5) 0.000001 100
      else 0;

      # Calculate trend slope (simple linear regression)
      indices = builtins.genList (i: i) count;
      meanX = if count > 0 then (lib.foldl (acc: i: acc + i) 0 indices) / count else 0;
      meanY = mean;

      slope =
        if count > 1 then
          let
            numerator = lib.foldl (acc: i: acc + (i - meanX) * ((builtins.elemAt values i) - meanY)) 0 indices;
            denominator = lib.foldl (acc: i: acc + (i - meanX) * (i - meanX)) 0 indices;
          in
          if denominator > 0 then numerator / denominator else 0
        else
          0;

      # Calculate correlation coefficient
      correlation =
        if (count > 1) && (stdDev > 0) then
          let
            numerator = lib.foldl (acc: i: acc + (i - meanX) * ((builtins.elemAt values i) - meanY)) 0 indices;
            xStdDev =
              if count > 1 then
                builtins.sqrt ((lib.foldl (acc: i: acc + (i - meanX) * (i - meanX)) 0 indices) / (count - 1))
              else
                0;
          in
          if xStdDev > 0 && stdDev > 0 then numerator / ((count - 1) * xStdDev * stdDev) else 0
        else
          0;

      # Trend classification
      trendClass =
        if builtins.abs slope < mean * 0.01 then
          "stable"
        else if slope > mean * 0.05 then
          "improving" # Negative slope is improvement for time
        else if slope < -mean * 0.05 then
          "degrading"
        else
          "fluctuating";
    in
    {
      statistical = {
        mean = mean;
        stdDev = stdDev;
        variance = variance;
        count = count;
      };
      trend = {
        slope = slope;
        correlation = correlation;
        classification = trendClass;
        direction =
          if slope > 0 then
            "increasing"
          else if slope < 0 then
            "decreasing"
          else
            "stable";
        strength = builtins.abs correlation;
      };
      quality = {
        consistency =
          if stdDev / mean < 0.1 then
            "high"
          else if stdDev / mean < 0.3 then
            "medium"
          else
            "low";
        predictability =
          if builtins.abs correlation > 0.8 then
            "high"
          else if builtins.abs correlation > 0.5 then
            "medium"
          else
            "low";
      };
    };

  # Performance regression detection
  detectRegressions =
    measurements: baselines: thresholds:
    let
      count = builtins.length measurements;
      recentCount = lib.min 5 count;

      # Helper function to get sublist (compatibility with older Nix)
      sublistCompat =
        start: length: list:
        if start == 0 then
          lib.take length list
        else
          lib.take length (lib.drop start list);

      recentMeasurements = sublistCompat (count - recentCount) recentCount measurements;

      # Recent performance metrics
      recentAvg =
        if recentCount > 0 then
          (lib.foldl (acc: m: acc + m.duration_ms) 0 recentMeasurements) / recentCount
        else
          0;

      # Historical performance metrics
      historicalMeasurements =
        if count > recentCount then sublistCompat 0 (count - recentCount) measurements else [ ];

      historicalAvg =
        if builtins.length historicalMeasurements > 0 then
          (lib.foldl (acc: m: acc + m.duration_ms) 0 historicalMeasurements)
          / builtins.length historicalMeasurements
        else
          recentAvg;

      # Compare against baselines
      baselineTime = baselines.test.maxUnitTestTimeMs or 5000;
      baselineMemory = baselines.memory.maxConfigMemoryMb * 1024 * 1024;

      # Regression detection
      timeRegression = recentAvg > baselineTime * thresholds.time.critical;
      memoryRegression =
        let
          recentMemoryAvg =
            if recentCount > 0 then
              (lib.foldl (acc: m: acc + m.memory_bytes) 0 recentMeasurements) / recentCount
            else
              0;
        in
        recentMemoryAvg > baselineMemory * thresholds.memory.critical;

      # Performance degradation detection
      performanceDegradation = recentAvg > historicalAvg * thresholds.performance.warning;
    in
    {
      regression = {
        detected = timeRegression || memoryRegression || performanceDegradation;
        timeRegression = timeRegression;
        memoryRegression = memoryRegression;
        performanceDegradation = performanceDegradation;
      };
      comparison = {
        recent = recentAvg;
        historical = historicalAvg;
        baseline = baselineTime;
        improvement = historicalAvg > recentAvg;
        degradation = recentAvg > historicalAvg * 1.1;
      };
    };

  # Predictive performance analysis
  predictPerformance =
    measurements: horizon:
    let
      # Use linear regression to predict future performance
      analysis = analyzeStatisticalTrend measurements;
      count = builtins.length measurements;
      lastValue =
        if count > 0 then builtins.elemAt (map (m: m.duration_ms) measurements) (count - 1) else 0;

      # Simple linear prediction
      predictedValue = lastValue + (analysis.trend.slope * horizon);

      # Confidence interval (simplified)
      confidenceInterval = analysis.statistical.stdDev * 1.96; # 95% confidence

      upperBound = predictedValue + confidenceInterval;
      lowerBound = if predictedValue > confidenceInterval then predictedValue - confidenceInterval else 0;

      # Risk assessment
      riskLevel =
        if analysis.trend.classification == "degrading" && analysis.trend.strength > 0.7 then
          "high"
        else if analysis.trend.classification == "degrading" then
          "medium"
        else if analysis.trend.classification == "stable" then
          "low"
        else
          "minimal";
    in
    {
      prediction = {
        horizon = horizon;
        predicted = predictedValue;
        upperBound = upperBound;
        lowerBound = lowerBound;
        confidence = analysis.trend.strength;
      };
      risk = {
        level = riskLevel;
        factors =
          let
            baseFactors = [ ];
            trendFactors =
              if analysis.trend.classification == "degrading" then
                baseFactors ++ [ "degrading-trend" ]
              else
                baseFactors;
            consistencyFactors =
              if analysis.quality.consistency == "low" then trendFactors ++ [ "high-variance" ] else trendFactors;
            predictabilityFactors =
              if analysis.quality.predictability == "low" then
                consistencyFactors ++ [ "low-correlation" ]
              else
                consistencyFactors;
          in
          predictabilityFactors;
      };
      recommendations =
        let
          baseRecs = [ ];
          riskRecs =
            if riskLevel == "high" then
              baseRecs ++ [ "Immediate investigation required - high regression risk" ]
            else
              baseRecs;
          trendRecs =
            if analysis.trend.classification == "degrading" then
              riskRecs ++ [ "Performance is trending downward - investigate root causes" ]
            else
              riskRecs;
          consistencyRecs =
            if analysis.quality.consistency == "low" then
              trendRecs ++ [ "High performance variance - system may be unstable" ]
            else
              trendRecs;
          predictionRecs =
            if predictedValue > lastValue * 1.2 then
              consistencyRecs ++ [ "Performance predicted to degrade - consider optimization" ]
            else
              consistencyRecs;
        in
        predictionRecs;
    };

  # Performance benchmark comparison
  compareBenchmarks =
    currentMeasurements: historicalBenchmarks:
    let
      currentStats = analyzeStatisticalTrend currentMeasurements;
      currentAvg = currentStats.statistical.mean;

      # Compare with historical benchmarks
      comparisons = map (benchmark: {
        name = benchmark.name;
        timestamp = benchmark.timestamp;
        baseline = benchmark.avgDuration;
        current = currentAvg;
        change = if benchmark.avgDuration > 0 then ((currentAvg - benchmark.avgDuration) / benchmark.avgDuration) * 100 else 0;
        status =
          if benchmark.avgDuration > 0 then
            if currentAvg < benchmark.avgDuration * 0.8 then
              "improved"
            else if currentAvg > benchmark.avgDuration * 1.2 then
              "regressed"
            else
              "stable"
          else
            "unknown";
      }) historicalBenchmarks;

      # Find best and worst comparisons
      improved = builtins.filter (c: c.status == "improved") comparisons;
      regressed = builtins.filter (c: c.status == "regressed") comparisons;
      stable = builtins.filter (c: c.status == "stable") comparisons;
    in
    {
      comparison = {
        total = builtins.length comparisons;
        improved = builtins.length improved;
        regressed = builtins.length regressed;
        stable = builtins.length stable;
      };
      details = comparisons;
      summary = {
        overallStatus =
          if builtins.length regressed > builtins.length improved then
            "degraded"
          else if builtins.length improved > builtins.length regressed then
            "improved"
          else
            "stable";
        worstRegression =
          if builtins.length regressed > 0 then
            lib.foldl (acc: c: if c.change > acc.change then c else acc) (builtins.head regressed) regressed
          else
            null;
        bestImprovement =
          if builtins.length improved > 0 then
            lib.foldl (acc: c: if c.change < acc.change then c else acc) (builtins.head improved) improved
          else
            null;
      };
    };
}
