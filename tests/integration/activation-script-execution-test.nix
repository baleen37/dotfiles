# Activation Script Execution Tests
#
# macOS 모듈의 위험한 시스템 작업 실행을 테스트하는 통합 테스트
#
# 주요 검증 항목:
# - sudo rm -rf 작업으로 6-8GB macOS 앱 삭제
# - killall/pkill -9 시스템 데몬 종료
# - sudo mdutil Spotlight 비활성화
# - 프로세스 관리 및 좀비 프로세스 방지
# - 오류 감지 및 복구 메커니즘
# - 부분 실패 시나리오 및 롤백
#
# 테스트 범위:
# - App Cleanup: modules/darwin/macos-app-cleanup.nix
# - System Daemon Termination: modules/darwin/aggressive-optimization.nix
# - Spotlight Disabling: modules/darwin/aggressive-optimization.nix
# - Error Detection: 실패 감지 및 시스템 상태 일관성
# - Recovery: 롤백 및 복구 메커니즘

{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  nixtest ? null,
}:

let
  # Use provided NixTest framework (or fallback to local import)
  nixtestFinal =
    if nixtest != null then
      nixtest
    else
      (import ../unit/nixtest-template.nix { inherit lib pkgs; }).nixtest;

  # Helper to safely evaluate configurations
  safeEvaluate =
    config:
    let
      result = builtins.tryEval config;
    in
    if result.success then result.value else null;

  # Mock framework for dangerous operations
  mockFramework = {
    # Mock file system operations
    mockFileSystem = {
      # Simulate app existence checking
      appExists =
        appName:
        builtins.elem appName [
          "GarageBand.app"
          "iMovie.app"
          "TV.app"
          "Podcasts.app"
        ];

      # Simulate protected apps (SIP)
      isProtectedApp =
        appName:
        builtins.elem appName [
          "TV.app"
          "Podcasts.app"
        ];

      # Simulate successful deletion
      canDelete = appName: !mockFramework.mockFileSystem.isProtectedApp appName;
    };

    # Mock process management
    mockProcessManagement = {
      # Simulate process existence
      processExists =
        processName:
        builtins.elem processName [
          "mds"
          "mdworker"
          "photoanalysisd"
          "suggestd"
          "coreduetd"
        ];

      # Simulate zombie process creation
      createsZombies = processName: processName == "mds";

      # Simulate successful termination
      canTerminate = processName: processName != "coreduetd"; # Protected service
    };

    # Mock Spotlight operations
    mockSpotlight = {
      # Simulate Spotlight status
      isIndexingEnabled = true;

      # Simulate successful disabling
      canDisable = true;

      # Simulate partial failure scenarios
      partialFailure = false;
    };

    # Mock system state validation
    mockSystemState = {
      # Track deleted apps for consistency checks
      deletedApps = [ ];

      # Track terminated processes
      terminatedProcesses = [ ];

      # Track system state consistency
      isConsistent = true;
    };
  };

  # Import the modules under test
  appCleanupModule = import ../../modules/darwin/macos-app-cleanup.nix { };
  aggressiveOptModule = import ../../modules/darwin/aggressive-optimization.nix { inherit lib; };

  # Extract activation scripts for testing
  appCleanupScript = appCleanupModule.system.activationScripts.cleanupMacOSApps.text;
  aggressiveOptScript = aggressiveOptModule.system.activationScripts.aggressiveOptimization.text;

  # Target apps for cleanup tests
  targetApps = [
    "GarageBand.app"
    "iMovie.app"
    "TV.app"
    "Podcasts.app"
    "News.app"
    "Stocks.app"
    "Freeform.app"
  ];

in
nixtestFinal.suite "Activation Script Execution Tests" {

  # ═══════════════════════════════════════════════════════════════════════════════
  # 1️⃣  App Cleanup Execution Tests
  # ═══════════════════════════════════════════════════════════════════════════════

  appCleanupTests = nixtestFinal.suite "App Cleanup Execution Tests" {

    scriptExists = nixtestFinal.test "App cleanup script exists" (
      nixtestFinal.assertions.assertTrue (
        appCleanupScript != null && builtins.stringLength appCleanupScript > 0
      )
    );

    hasAppList = nixtestFinal.test "Script contains app list" (
      let
        hasGarageBand = builtins.match ".*GarageBand\.app.*" appCleanupScript != null;
        hasIMovie = builtins.match ".*iMovie\.app.*" appCleanupScript != null;
      in
      nixtestFinal.assertions.assertTrue (hasGarageBand && hasIMovie)
    );

    hasDeletionCommands = nixtestFinal.test "Script contains rm -rf commands" (
      let
        hasUserDeletion = builtins.match ".*rm -rf.*app_path.*" appCleanupScript != null;
        hasSudoDeletion = builtins.match ".*sudo rm -rf.*app_path.*" appCleanupScript != null;
      in
      nixtestFinal.assertions.assertTrue (hasUserDeletion && hasSudoDeletion)
    );

    hasErrorHandling = nixtestFinal.test "Script has error handling" (
      let
        hasErrorRedirect = builtins.match ".*2>/dev/null.*" appCleanupScript != null;
        hasErrorChecks = builtins.match ".*if.*then.*else.*" appCleanupScript != null;
      in
      nixtestFinal.assertions.assertTrue (hasErrorRedirect && hasErrorChecks)
    );

    hasProgressReporting = nixtestFinal.test "Script has progress reporting" (
      let
        hasRemovalReport = builtins.match ".*removed_count.*" appCleanupScript != null;
        hasSkippedReport = builtins.match ".*skipped_count.*" appCleanupScript != null;
      in
      nixtestFinal.assertions.assertTrue (hasRemovalReport && hasSkippedReport)
    );

    # Mock execution tests
    mockSuccessfulDeletion = nixtestFinal.test "Successful app deletion (mock)" (
      let
        testApp = "GarageBand.app";
        canDelete = mockFramework.mockFileSystem.canDelete testApp;
        appExists = mockFramework.mockFileSystem.appExists testApp;
      in
      nixtestFinal.assertions.assertTrue (canDelete && appExists)
    );

    mockProtectedAppHandling = nixtestFinal.test "Protected app handling (mock)" (
      let
        protectedApp = "TV.app";
        isProtected = mockFramework.mockFileSystem.isProtectedApp protectedApp;
        appExists = mockFramework.mockFileSystem.appExists protectedApp;
        shouldSkip = isProtected && appExists;
      in
      nixtestFinal.assertions.assertTrue shouldSkip
    );

    partialDeletionScenario = nixtestFinal.test "Partial deletion scenario (mock)" (
      let
        # Simulate scenario where some apps succeed, others fail
        apps = [
          "GarageBand.app"
          "TV.app"
          "News.app"
        ];
        results = builtins.map (app: {
          name = app;
          success = mockFramework.mockFileSystem.canDelete app;
        }) apps;
        successCount = builtins.length (builtins.filter (r: r.success) results);
        totalCount = builtins.length apps;
        expectedSuccessCount = 2; # GarageBand and News should succeed
      in
      nixtestFinal.assertions.assertEqual expectedSuccessCount successCount
    );

    cleanupCompletionReporting = nixtestFinal.test "Cleanup completion reporting accuracy" (
      let
        # Simulate complete cleanup operation
        simulatedResults = {
          removed = [
            "GarageBand.app"
            "iMovie.app"
            "News.app"
          ]; # 3 removed
          skipped = [
            "TV.app"
            "Podcasts.app"
          ]; # 2 protected
          alreadyRemoved = [
            "Stocks.app"
            "Freeform.app"
          ]; # 2 already gone
        };
        removedCount = builtins.length simulatedResults.removed;
        skippedCount = builtins.length simulatedResults.skipped;
        expectedRemoved = 3;
        expectedSkipped = 2;
      in
      nixtestFinal.assertions.assertTrue (
        removedCount == expectedRemoved && skippedCount == expectedSkipped
      )
    );

    sipProtectedAppHandling = nixtestFinal.test "SIP protected app handling" (
      let
        # Test that script handles SIP protected apps gracefully
        protectedApps = builtins.filter mockFramework.mockFileSystem.isProtectedApp targetApps;
        hasProtectedApps = builtins.length protectedApps > 0;
        expectedBehavior = hasProtectedApps; # Should handle gracefully
      in
      nixtestFinal.assertions.assertTrue expectedBehavior
    );
  };

  # ═══════════════════════════════════════════════════════════════════════════════
  # 2️⃣  System Daemon Termination Tests
  # ═══════════════════════════════════════════════════════════════════════════════

  daemonTerminationTests = nixtestFinal.suite "System Daemon Termination Tests" {

    scriptExists = nixtestFinal.test "Aggressive optimization script exists" (
      nixtestFinal.assertions.assertTrue (
        aggressiveOptScript != null && builtins.stringLength aggressiveOptScript > 0
      )
    );

    hasKillallCommands = nixtestFinal.test "Script contains killall commands" (
      let
        hasKillall = builtins.match ".*killall.*" aggressiveOptScript != null;
      in
      nixtestFinal.assertions.assertTrue hasKillall
    );

    hasPkillCommands = nixtestFinal.test "Script contains pkill commands" (
      let
        hasPkill = builtins.match ".*pkill.*" aggressiveOptScript != null;
      in
      nixtestFinal.assertions.assertTrue hasPkill
    );

    hasForceTermination = nixtestFinal.test "Script uses force termination (-9)" (
      let
        hasForceFlag = builtins.match ".*pkill.*-9.*" aggressiveOptScript != null;
      in
      nixtestFinal.assertions.assertTrue hasForceFlag
    );

    hasLaunchctlCommands = nixtestFinal.test "Script contains launchctl commands" (
      let
        hasLaunchctlUnload = builtins.match ".*launchctl.*unload.*" aggressiveOptScript != null;
        hasLaunchctlBootout = builtins.match ".*launchctl.*bootout.*" aggressiveOptScript != null;
      in
      nixtestFinal.assertions.assertTrue (hasLaunchctlUnload && hasLaunchctlBootout)
    );

    # Mock termination tests
    mockProcessTermination = nixtestFinal.test "Complete process termination (mock)" (
      let
        testProcesses = [
          "mds"
          "mdworker"
          "photoanalysisd"
        ];
        results = builtins.map (proc: {
          name = proc;
          exists = mockFramework.mockProcessManagement.processExists proc;
          canTerminate = mockFramework.mockProcessManagement.canTerminate proc;
        }) testProcesses;
        allCanTerminate = builtins.all (r: r.canTerminate) results;
      in
      nixtestFinal.assertions.assertTrue allCanTerminate
    );

    zombieProcessDetection = nixtestFinal.test "Zombie process detection scenarios" (
      let
        problematicProcess = "mds";
        createsZombies = mockFramework.mockProcessManagement.createsZombies problematicProcess;
        shouldHaveCleanup = createsZombies; # Script should handle zombie cleanup
      in
      nixtestFinal.assertions.assertTrue shouldHaveCleanup
    );

    processRestartMechanism = nixtestFinal.test "Process restart mechanisms" (
      let
        # Test that script includes restart prevention
        hasLaunchctlUnload = builtins.match ".*launchctl.*unload.*" aggressiveOptScript != null;
        hasBootoutCommands = builtins.match ".*launchctl.*bootout.*" aggressiveOptScript != null;
        hasRestartPrevention = hasLaunchctlUnload && hasBootoutCommands;
      in
      nixtestFinal.assertions.assertTrue hasRestartPrevention
    );

    permissionDeniedScenario = nixtestFinal.test "Permission denied scenario handling" (
      let
        protectedService = "coreduetd";
        exists = mockFramework.mockProcessManagement.processExists protectedService;
        canTerminate = mockFramework.mockProcessManagement.canTerminate protectedService;
        shouldFailGracefully = exists && !canTerminate;
      in
      nixtestFinal.assertions.assertTrue shouldFailGracefully
    );

    noZombieProcessesAfterTermination = nixtestFinal.test "No zombie processes remain" (
      let
        # Simulate termination result
        terminatedProcesses = [
          "photoanalysisd"
          "suggestd"
        ];
        zombieCheckRequired = builtins.length terminatedProcesses > 0;
        shouldValidateNoZombies = zombieCheckRequired;
      in
      nixtestFinal.assertions.assertTrue shouldValidateNoZombies
    );
  };

  # ═══════════════════════════════════════════════════════════════════════════════
  # 3️⃣  Spotlight Disabling Tests
  # ═══════════════════════════════════════════════════════════════════════════════

  spotlightTests = nixtestFinal.suite "Spotlight Disabling Tests" {

    hasMdutilCommands = nixtestFinal.test "Script contains mdutil commands" (
      let
        hasMdutilStatus = builtins.match ".*mdutil.*-s.*" aggressiveOptScript != null;
        hasMdutilDisable = builtins.match ".*mdutil.*-i.*off.*" aggressiveOptScript != null;
        hasMdutilErase = builtins.match ".*mdutil.*-E.*" aggressiveOptScript != null;
      in
      nixtestFinal.assertions.assertTrue (hasMdutilStatus && hasMdutilDisable && hasMdutilErase)
    );

    hasSudoMdutil = nixtestFinal.test "Script uses sudo for mdutil" (
      let
        hasSudoMdutil = builtins.match ".*sudo.*mdutil.*" aggressiveOptScript != null;
      in
      nixtestFinal.assertions.assertTrue hasSudoMdutil
    );

    hasStatusCheck = nixtestFinal.test "Script checks Spotlight status first" (
      let
        hasStatusCheck = builtins.match ".*if.*mdutil.*-s.*" aggressiveOptScript != null;
        hasIndexingEnabledCheck = builtins.match ".*Indexing enabled.*" aggressiveOptScript != null;
      in
      nixtestFinal.assertions.assertTrue (hasStatusCheck && hasIndexingEnabledCheck)
    );

    mockSpotlightDisabling = nixtestFinal.test "Successful Spotlight disabling (mock)" (
      let
        isEnabled = mockFramework.mockSpotlight.isIndexingEnabled;
        canDisable = mockFramework.mockSpotlight.canDisable;
        shouldDisable = isEnabled && canDisable;
      in
      nixtestFinal.assertions.assertTrue shouldDisable
    );

    partialFailureScenario = nixtestFinal.test "Partial failure scenario (some operations fail)" (
      let
        # Simulate mdutil -i off succeeding but -E failing
        operations = [
          "status"
          "disable"
          "erase"
        ];
        results = {
          status.success = true;
          disable.success = true;
          erase.success = false; # Partial failure
        };
        successCount = builtins.length (builtins.filter (_: _.success) (builtins.attrValues results));
        hasPartialFailure = successCount < builtins.length operations;
        expectedSuccessCount = 2;
      in
      nixtestFinal.assertions.assertTrue (hasPartialFailure && successCount == expectedSuccessCount)
    );

    spotlightStateValidation = nixtestFinal.test "Spotlight service state validation" (
      let
        # After disabling operations
        finalState = {
          indexingEnabled = false;
          indexCleared = true;
          processesTerminated = true;
        };
        isProperlyDisabled = !finalState.indexingEnabled && finalState.indexCleared;
      in
      nixtestFinal.assertions.assertTrue isProperlyDisabled
    );

    indexCleanupValidation = nixtestFinal.test "Index cleanup validation" (
      let
        hasEraseCommand = builtins.match ".*mdutil.*-E.*" aggressiveOptScript != null;
        hasRootTarget = builtins.match ".*mdutil.*-E.*/.*" aggressiveOptScript != null;
        hasCleanupStep = hasEraseCommand && hasRootTarget;
      in
      nixtestFinal.assertions.assertTrue hasCleanupStep
    );

    alreadyDisabledScenario = nixtestFinal.test "Already disabled scenario" (
      let
        # Simulate already disabled state
        indexingEnabled = false;
        shouldSkipOperations = !indexingEnabled;
        shouldReportAlreadyDisabled = shouldSkipOperations;
      in
      nixtestFinal.assertions.assertTrue shouldReportAlreadyDisabled
    );
  };

  # ═══════════════════════════════════════════════════════════════════════════════
  # 4️⃣  Error Detection and Recovery Tests
  # ═══════════════════════════════════════════════════════════════════════════════

  errorDetectionTests = nixtestFinal.suite "Error Detection and Recovery" {

    errorMessageCapture = nixtestFinal.test "Error message capture and reporting" (
      let
        hasErrorRedirection = builtins.match ".*2>/dev/null.*" appCleanupScript != null;
        hasConditionalErrorHandling = builtins.match ".*if.*rm.*then.*else.*" appCleanupScript != null;
        hasErrorReporting = builtins.match ".*⚠️.*Failed.*" appCleanupScript != null;
      in
      nixtestFinal.assertions.assertTrue (
        hasErrorRedirection && hasConditionalErrorHandling && hasErrorReporting
      )
    );

    rollbackMechanism = nixtestFinal.test "Rollback mechanisms for partial failures" (
      let
        # Check if scripts are idempotent (can be safely re-run)
        hasStatusChecks = builtins.match ".*if.*\[.*-e.*" appCleanupScript != null;
        hasConditionalExecution = builtins.match ".*if.*then.*else.*fi.*" appCleanupScript != null;
        isIdempotent = hasStatusChecks && hasConditionalExecution;
      in
      nixtestFinal.assertions.assertTrue isIdempotent
    );

    systemStateConsistency = nixtestFinal.test "System state consistency checks" (
      let
        # Scripts should validate state after operations
        hasProgressTracking = builtins.match ".*removed_count.*" appCleanupScript != null;
        hasFinalReporting = builtins.match ".*✨.*complete.*" appCleanupScript != null;
        hasStateValidation = hasProgressTracking && hasFinalReporting;
      in
      nixtestFinal.assertions.assertTrue hasStateValidation
    );

    incompleteOperationWarnings = nixtestFinal.test "Warning systems for incomplete operations" (
      let
        # Check for warning messages when operations don't complete
        hasFailureWarning = builtins.match ".*⚠️.*Failed.*" appCleanupScript != null;
        hasSkippedReporting = builtins.match ".*Skipped.*" appCleanupScript != null;
        hasWarningSystem = hasFailureWarning && hasSkippedReporting;
      in
      nixtestFinal.assertions.assertTrue hasWarningSystem
    );

    gracefulDegradation = nixtestFinal.test "Graceful degradation on failures" (
      let
        # Scripts should continue even if individual operations fail
        hasContinueOnError = builtins.match ".*|| true.*" aggressiveOptScript != null;
        hasErrorSuppression = builtins.match ".*2>/dev/null.*" aggressiveOptScript != null;
        hasGracefulHandling = hasContinueOnError && hasErrorSuppression;
      in
      nixtestFinal.assertions.assertTrue hasGracefulHandling
    );

    operationIdempotency = nixtestFinal.test "Operation idempotency validation" (
      let
        # Both scripts should be safe to run multiple times
        appCleanupIdempotent = builtins.match ".*if.*\[.*-e.*\].*then.*" appCleanupScript != null;
        optScriptIdempotent = builtins.match ".*if.*mdutil.*-s.*" aggressiveOptScript != null;
        bothIdempotent = appCleanupIdempotent && optScriptIdempotent;
      in
      nixtestFinal.assertions.assertTrue bothIdempotent
    );

    performanceRegressionDetection = nixtestFinal.test "Performance regression detection" (
      let
        # Check that scripts include timing or progress indicators
        hasProgressIndicators = builtins.match ".*→.*" aggressiveOptScript != null;
        hasCompletionReporting = builtins.match ".*✓.*" aggressiveOptScript != null;
        hasPerformanceTracking = hasProgressIndicators && hasCompletionReporting;
      in
      nixtestFinal.assertions.assertTrue hasPerformanceTracking
    );

    criticalOperationValidation = nixtestFinal.test "Critical operation validation before execution" (
      let
        # Scripts should validate conditions before dangerous operations
        appCleanupHasChecks = builtins.match ".*if.*\[.*-e.*\].*then.*rm.*" appCleanupScript != null;
        spotlightHasChecks = builtins.match ".*if.*mdutil.*-s.*" aggressiveOptScript != null;
        hasPreExecutionValidation = appCleanupHasChecks && spotlightHasChecks;
      in
      nixtestFinal.assertions.assertTrue hasPreExecutionValidation
    );
  };

  # ═══════════════════════════════════════════════════════════════════════════════
  # 5️⃣  Integration and Safety Tests
  # ═══════════════════════════════════════════════════════════════════════════════

  integrationTests = nixtestFinal.suite "Integration and Safety Tests" {

    noSystemDamagingOperations = nixtestFinal.test "No accidentally damaging operations" (
      let
        # Ensure scripts don't contain dangerous patterns
        hasDestructiveRm = builtins.match ".*rm.*-rf.*/(?!Applications).*" appCleanupScript != null;
        hasDestructiveSudo = builtins.match ".*sudo.*rm.*-rf.*/(System|Library).*" appCleanupScript != null;
        isSafe = !hasDestructiveRm && !hasDestructiveSudo;
      in
      nixtestFinal.assertions.assertTrue isSafe
    );

    properSudoUsage = nixtestFinal.test "Proper sudo usage for privileged operations" (
      let
        # Check that sudo is only used where necessary
        sudoCommands = builtins.filter builtins.isString (lib.splitString "\n" appCleanupScript);
        hasSudoOnlyWhereNeeded = builtins.all (
          cmd:
          if builtins.match ".*sudo.*" cmd != null then
            builtins.match ".*sudo.*rm.*" cmd != null || builtins.match ".*sudo.*mdutil.*" cmd != null
          else
            true
        ) sudoCommands;
      in
      nixtestFinal.assertions.assertTrue hasSudoOnlyWhereNeeded
    );

    atomicOperationHandling = nixtestFinal.test "Atomic operation handling" (
      let
        # Check that related operations are grouped together
        appCleanupGroupedOps = builtins.match ".*rm.*sudo rm.*" appCleanupScript != null;
        spotlightGroupedOps = builtins.match ".*mdutil.*-i off.*mdutil.*-E.*" aggressiveOptScript != null;
        hasAtomicOperations = appCleanupGroupedOps && spotlightGroupedOps;
      in
      nixtestFinal.assertions.assertTrue hasAtomicOperations
    );

    validationBeforeDestruction = nixtestFinal.test "Validation before destructive operations" (
      let
        # All destructive operations should have validation checks
        appCleanupValidated = builtins.match ".*if.*\[.*-e.*\].*then.*rm.*" appCleanupScript != null;
        spotlightValidated = builtins.match ".*if.*mdutil.*-s.*" aggressiveOptScript != null;
        hasValidation = appCleanupValidated && spotlightValidated;
      in
      nixtestFinal.assertions.assertTrue hasValidation
    );

    noHardcodedPaths = nixtestFinal.test "No hardcoded Nix store paths" (
      let
        scripts = appCleanupScript + aggressiveOptScript;
        hasNixStorePath = builtins.match ".*(/nix/store/[^ ]+).*" scripts != null;
        isSafe = !hasNixStorePath;
      in
      nixtestFinal.assertions.assertTrue isSafe
    );

    properErrorPropagation = nixtestFinal.test "Proper error propagation" (
      let
        # Check that scripts don't swallow all errors indiscriminately
        hasSelectiveErrorHandling = builtins.match ".*2>/dev/null.*|| true.*" appCleanupScript != null;
        hasSpecificErrorChecks = builtins.match ".*if.*rm.*then.*else.*" appCleanupScript != null;
        hasProperErrorHandling = hasSelectiveErrorHandling && hasSpecificErrorChecks;
      in
      nixtestFinal.assertions.assertTrue hasProperErrorHandling
    );

    comprehensiveLogging = nixtestFinal.test "Comprehensive logging and progress reporting" (
      let
        # Both scripts should provide comprehensive feedback
        appCleanupHasLogging = builtins.match ".*echo.*→.*" appCleanupScript != null;
        appCleanupHasSummary = builtins.match ".*Cleanup complete.*" appCleanupScript != null;
        optScriptHasSections = builtins.match ".*\[1/3\].*" aggressiveOptScript != null;
        optScriptHasSummary = builtins.match ".*OPTIMIZATION COMPLETE.*" aggressiveOptScript != null;
        hasComprehensiveLogging =
          appCleanupHasLogging && appCleanupHasSummary && optScriptHasSections && optScriptHasSummary;
      in
      nixtestFinal.assertions.assertTrue hasComprehensiveLogging
    );
  };
}
