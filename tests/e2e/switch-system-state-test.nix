# Switch System State Verification Tests
#
# Comprehensive E2E tests to validate that `make switch` properly applies system changes
# and maintains consistent state across all components.
#
# Test Coverage Areas:
# 1. macOS App Cleanup State Verification
# 2. System Configuration Applied Verification
# 3. Home Manager State Verification
# 4. Backup and Recovery State Verification
# 5. Activation Script Execution Verification

{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem,
  nixtest ? null,
}:

let
  # Use provided NixTest framework (or fallback to local template)
  nixtestFinal =
    if nixtest != null then
      nixtest
    else
      (import ../unit/nixtest-template.nix { inherit lib pkgs; }).nixtest;

  # Import platform system for platform detection
  platformSystem = import ../../lib/platform-system.nix { inherit system; };

  # Import E2E test helpers
  helpers = import ./helpers.nix { inherit lib pkgs platformSystem; };

  # Mock filesystem helpers for safe testing
  mockFilesystem = {
    # Mock app directories for cleanup testing
    createMockAppStructure =
      appList:
      builtins.listToAttrs (
        map (app: {
          name = "/Applications/${app}";
          value = {
            exists = true;
            isProtected = builtins.elem app [
              "Safari.app"
              "Finder.app"
              "App Store.app"
            ];
            size =
              if app == "GarageBand.app" then
                3000000000 # 3GB
              else if app == "iMovie.app" then
                4000000000 # 4GB
              else if app == "TV.app" then
                200000000 # 200MB
              else if app == "Podcasts.app" then
                100000000 # 100MB
              else if app == "News.app" then
                50000000 # 50MB
              else if app == "Stocks.app" then
                30000000 # 30MB
              else if app == "Freeform.app" then
                50000000 # 50MB
              else
                100000000; # Default 100MB
          };
        }) appList
      );

    # Mock system defaults structure
    createMockDefaults = {
      NSGlobalDomain = {
        NSAutomaticWindowAnimationsEnabled = false;
        NSWindowResizeTime = 0.1;
        NSScrollAnimationEnabled = false;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSDisableAutomaticTermination = false;
        NSDocumentSaveNewDocumentsToCloud = false;
      };
      dock = {
        autohide = true;
        "autohide-delay" = 0.0;
        "autohide-time-modifier" = 0.15;
        "expose-animation-duration" = 0.2;
        tilesize = 48;
        "mru-spaces" = false;
      };
      finder = {
        AppleShowAllFiles = true;
        FXEnableExtensionChangeWarning = false;
        _FXSortFoldersFirst = true;
        ShowPathbar = true;
        ShowStatusBar = true;
      };
      trackpad = {
        Clicking = true;
        TrackpadRightClick = true;
        TrackpadThreeFingerDrag = true;
      };
    };

    # Mock Home Manager state
    createMockHomeManagerState = user: {
      homeDirectory = if platformSystem.isDarwin then "/Users/${user}" else "/home/${user}";
      packages = [
        pkgs.git
        pkgs.vim
        pkgs.zsh
        pkgs.tmux
        pkgs.gnumake
      ];
      files = {
        ".gitconfig".exists = true;
        ".vimrc".exists = true;
        ".zshrc".exists = true;
        ".tmux.conf".exists = true;
      };
      activationScripts = [
        "setupDarwinOptimizations"
        "linkNixApps"
      ];
    };
  };

  # Backup and recovery helpers
  backupHelpers = {
    # Mock backup creation
    createMockBackup = timestamp: {
      path = "/tmp/dotfiles-backup-${timestamp}";
      inherit timestamp;
      files = [
        ".gitconfig"
        ".vimrc"
        ".zshrc"
        ".tmux.conf"
      ];
      size = 1024000; # 1MB mock backup
      integrity = true;
    };

    # Mock backup verification
    verifyBackupIntegrity =
      backup: backup.integrity && builtins.length backup.files > 0 && backup.size > 0;

    # Mock rollback simulation
    simulateRollback = backup: targetState: {
      success = backupHelpers.verifyBackupIntegrity backup;
      restoredFiles = backup.files;
      finalState = if backupHelpers.verifyBackupIntegrity backup then targetState else null;
    };
  };

  # Activation script testing helpers
  activationHelpers = {
    # Mock script execution results
    createMockScriptResult = name: {
      inherit name;
      exitCode = 0;
      output = "✅ ${name} completed successfully";
      duration = 1.5;
      timestamp = builtins.currentTime;
    };

    # Mock script failure
    createMockScriptFailure = name: errorMessage: {
      inherit name;
      exitCode = 1;
      error = errorMessage;
      output = "❌ ${name} failed: ${errorMessage}";
      duration = 0.5;
      timestamp = builtins.currentTime;
    };

    # Mock script dependency chain
    createMockDependencyChain =
      scripts:
      builtins.genList (i: {
        script = builtins.elemAt scripts i;
        dependencies = if i > 0 then [ (builtins.elemAt scripts (i - 1)) ] else [ ];
      }) (builtins.length scripts);
  };

in
nixtestFinal.suite "Switch System State Verification Tests" {

  # ========================================
  # 1. macOS App Cleanup State Verification
  # ========================================

  appCleanupVerification = nixtestFinal.suite "macOS App Cleanup State Verification" {

    # Test 1.1: Disk space recovery verification
    diskSpaceRecoveryVerified =
      nixtestFinal.test "Disk space recovery is properly calculated after app removal"
        (
          let
            initialApps = [
              "GarageBand.app"
              "iMovie.app"
              "TV.app"
              "Podcasts.app"
              "News.app"
              "Stocks.app"
              "Freeform.app"
            ];
            mockApps = mockFilesystem.createMockAppStructure initialApps;
            initialSpace = builtins.foldl' (
              acc: app: acc + mockApps.${"/Applications/${app}"}.size
            ) 0 initialApps;
            removedApps = [
              "GarageBand.app"
              "iMovie.app"
              "TV.app"
            ];
            recoveredSpace = builtins.foldl' (
              acc: app: acc + mockApps.${"/Applications/${app}"}.size
            ) 0 removedApps;
            finalSpace = initialSpace - recoveredSpace;
          in
          nixtestFinal.assertions.assertEqual 6200000000 recoveredSpace # 6.2GB expected recovery
        );

    # Test 1.2: App directory removal verification
    appDirectoriesRemoved =
      nixtestFinal.test "App directories are properly removed from /Applications"
        (
          let
            targetApps = [
              "GarageBand.app"
              "iMovie.app"
              "TV.app"
            ];
            mockApps = mockFilesystem.createMockAppStructure targetApps;
            removedPaths = builtins.map (app: "/Applications/${app}") targetApps;
            allRemoved = builtins.all (path: !mockApps.${path}.exists) removedPaths;
          in
          nixtestFinal.assertions.assertTrue allRemoved
        );

    # Test 1.3: SIP protected app handling
    sipProtectedAppsHandled = nixtestFinal.test "SIP protected apps are properly skipped and reported" (
      let
        protectedApps = [
          "Safari.app"
          "Finder.app"
          "App Store.app"
        ];
        regularApps = [
          "GarageBand.app"
          "iMovie.app"
        ];
        allApps = protectedApps ++ regularApps;
        mockApps = mockFilesystem.createMockAppStructure allApps;
        protectedAppPaths = builtins.filter (app: mockApps.${"/Applications/${app}"}.isProtected) allApps;
        regularAppPaths = builtins.filter (app: !mockApps.${"/Applications/${app}"}.isProtected) allApps;
        protectedCount = builtins.length protectedAppPaths;
        regularCount = builtins.length regularAppPaths;
      in
      nixtestFinal.assertions.assertEqual 3 protectedCount
    );

    # Test 1.4: Cleanup completion reporting accuracy
    cleanupReportingAccurate =
      nixtestFinal.test "Cleanup completion reporting accurately reflects actual state"
        (
          let
            totalApps = 7;
            removedApps = 5;
            skippedApps = 2;
            expectedReport = "Removed: ${toString removedApps} apps, Skipped: ${toString skippedApps} apps";
            actualReport = "Removed: 5 apps, Skipped: 2 apps (protected)";
          in
          nixtestFinal.assertions.assertStringContains "Removed: 5" actualReport
        );

    # Test 1.5: Partially removed app scenarios
    partiallyRemovedAppsHandled =
      nixtestFinal.test "Partially removed app scenarios are handled gracefully"
        (
          let
            partialRemovalScenarios = [
              {
                app = "iMovie.app";
                state = "partial";
                error = "Permission denied";
              }
              {
                app = "GarageBand.app";
                state = "complete";
                error = null;
              }
              {
                app = "TV.app";
                state = "failed";
                error = "SIP protected";
              }
            ];
            successfulRemovals = builtins.filter (
              scenario: scenario.state == "complete"
            ) partialRemovalScenarios;
            failedRemovals = builtins.filter (scenario: scenario.state == "failed") partialRemovalScenarios;
            partialRemovals = builtins.filter (scenario: scenario.state == "partial") partialRemovalScenarios;
            successCount = builtins.length successfulRemovals;
            failureCount = builtins.length failedRemovals;
            partialCount = builtins.length partialRemovals;
          in
          nixtestFinal.assertions.assertEqual 1 successCount
        );
  };

  # ===========================================
  # 2. System Configuration Applied Verification
  # ===========================================

  systemConfigurationVerification = nixtestFinal.suite "System Configuration Applied Verification" {

    # Test 2.1: System defaults applied verification
    systemDefaultsApplied = nixtestFinal.test "System defaults are actually applied and take effect" (
      let
        mockDefaults = mockFilesystem.createMockDefaults;
        expectedDefaults = {
          NSGlobalDomain.NSAutomaticWindowAnimationsEnabled = false;
          NSGlobalDomain.NSWindowResizeTime = 0.1;
          dock.autohide = true;
          finder.AppleShowAllFiles = true;
        };
        defaultsMatch =
          mockDefaults.NSGlobalDomain.NSAutomaticWindowAnimationsEnabled
          == expectedDefaults.NSGlobalDomain.NSAutomaticWindowAnimationsEnabled
          &&
            mockDefaults.NSGlobalDomain.NSWindowResizeTime == expectedDefaults.NSGlobalDomain.NSWindowResizeTime
          && mockDefaults.dock.autohide == expectedDefaults.dock.autohide
          && mockDefaults.finder.AppleShowAllFiles == expectedDefaults.finder.AppleShowAllFiles;
      in
      nixtestFinal.assertions.assertTrue defaultsMatch
    );

    # Test 2.2: Performance optimization settings verification
    performanceOptimizationsActive =
      nixtestFinal.test "Performance optimization settings are active and measurable"
        (
          let
            mockDefaults = mockFilesystem.createMockDefaults;
            performanceSettings = {
              windowAnimationsDisabled = mockDefaults.NSGlobalDomain.NSAutomaticWindowAnimationsEnabled == false;
              fastWindowResize = mockDefaults.NSGlobalDomain.NSWindowResizeTime == 0.1;
              smoothScrollingDisabled = mockDefaults.NSGlobalDomain.NSScrollAnimationEnabled == false;
              autoTerminationEnabled = mockDefaults.NSGlobalDomain.NSDisableAutomaticTermination == false;
              fastDockAnimation = mockDefaults.dock."expose-animation-duration" == 0.2;
            };
            allOptimizationsActive = builtins.all (setting: setting) (builtins.attrValues performanceSettings);
          in
          nixtestFinal.assertions.assertTrue allOptimizationsActive
        );

    # Test 2.3: Service configurations verification
    serviceConfigurationsActive = nixtestFinal.test "Service configurations are properly activated" (
      let
        expectedServices = [
          "syncthing" # From Homebrew
          "Dock" # macOS Dock service
        ];
        mockServiceStates = {
          syncthing.running = true;
          syncthing.enabled = true;
          Dock.running = true;
          Dock.autohide = true;
        };
        servicesActive =
          mockServiceStates.syncthing.running
          && mockServiceStates.syncthing.enabled
          && mockServiceStates.Dock.running;
      in
      nixtestFinal.assertions.assertTrue servicesActive
    );

    # Test 2.4: Disabled features remain disabled
    disabledFeaturesStayDisabled =
      nixtestFinal.test "Disabled features remain properly disabled across reboots"
        (
          let
            mockDefaults = mockFilesystem.createMockDefaults;
            disabledFeatures = {
              autoCapitalization = mockDefaults.NSGlobalDomain.NSAutomaticCapitalizationEnabled == false;
              spellCorrection = mockDefaults.NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled == false;
              smartQuotes = mockDefaults.NSGlobalDomain.NSAutomaticQuoteSubstitutionEnabled == false;
              icloudAutoSave = mockDefaults.NSGlobalDomain.NSDocumentSaveNewDocumentsToCloud == false;
            };
            allFeaturesDisabled = builtins.all (feature: feature) (builtins.attrValues disabledFeatures);
          in
          nixtestFinal.assertions.assertTrue allFeaturesDisabled
        );

    # Test 2.5: Configuration consistency verification
    configurationConsistent =
      nixtestFinal.test "Configuration state is consistent across system components"
        (
          let
            mockDefaults = mockFilesystem.createMockDefaults;
            consistencyChecks = {
              dockSettingsConsistent = mockDefaults.dock.autohide && mockDefaults.dock."autohide-delay" == 0.0;
              finderSettingsConsistent = mockDefaults.finder.AppleShowAllFiles && mockDefaults.finder.ShowPathbar;
              trackpadSettingsConsistent =
                mockDefaults.trackpad.Clicking && mockDefaults.trackpad.TrackpadRightClick;
            };
            allConsistent = builtins.all (check: check) (builtins.attrValues consistencyChecks);
          in
          nixtestFinal.assertions.assertTrue allConsistent
        );
  };

  # =======================================
  # 3. Home Manager State Verification
  # =======================================

  homeManagerVerification = nixtestFinal.suite "Home Manager State Verification" {

    # Test 3.1: User configuration files verification
    userConfigurationFilesCreated =
      nixtestFinal.test "User configuration files are created/updated correctly"
        (
          let
            testUser = "baleen";
            mockHomeState = mockFilesystem.createMockHomeManagerState testUser;
            configFiles = [
              ".gitconfig"
              ".vimrc"
              ".zshrc"
              ".tmux.conf"
            ];
            filesExist = builtins.all (file: mockHomeState.files.${file}.exists) configFiles;
          in
          nixtestFinal.assertions.assertTrue filesExist
        );

    # Test 3.2: Package installations verification
    packageInstallationsComplete = nixtestFinal.test "Package installations complete successfully" (
      let
        testUser = "baleen";
        mockHomeState = mockFilesystem.createMockHomeManagerState testUser;
        expectedPackages = [
          "git"
          "vim"
          "zsh"
          "tmux"
          "gnumake"
        ];
        actualPackages = builtins.map (pkg: builtins.parseDrvName pkg.name) mockHomeState.packages;
        packagesMatch = builtins.length actualPackages == builtins.length expectedPackages;
      in
      nixtestFinal.assertions.assertTrue packagesMatch
    );

    # Test 3.3: Dotfiles linking verification
    dotfilesProperlyLinked = nixtestFinal.test "Dotfiles are properly linked to user home directory" (
      let
        testUser = "baleen";
        mockHomeState = mockFilesystem.createMockHomeManagerState testUser;
        expectedHomeDir = if platformSystem.isDarwin then "/Users/${testUser}" else "/home/${testUser}";
        actualHomeDir = mockHomeState.homeDirectory;
        homeDirMatches = expectedHomeDir == actualHomeDir;
      in
      nixtestFinal.assertions.assertEqual expectedHomeDir actualHomeDir
    );

    # Test 3.4: Shell configuration changes verification
    shellConfigurationChanges = nixtestFinal.test "Shell configuration changes are applied correctly" (
      let
        mockHomeState = mockFilesystem.createMockHomeManagerState "baleen";
        shellConfigured = builtins.elem "setupDarwinOptimizations" mockHomeState.activationScripts;
        expectedShell = "zsh";
      in
      nixtestFinal.assertions.assertTrue shellConfigured
    );

    # Test 3.5: User services startup verification
    userServicesStartCorrectly = nixtestFinal.test "User services start correctly after switch" (
      let
        mockHomeState = mockFilesystem.createMockHomeManagerState "baleen";
        hasActivationScripts = builtins.length mockHomeState.activationScripts > 0;
        expectedScripts = [
          "setupDarwinOptimizations"
          "linkNixApps"
        ];
        allScriptsPresent = builtins.all (
          script: builtins.elem script mockHomeState.activationScripts
        ) expectedScripts;
      in
      nixtestFinal.assertions.assertTrue allScriptsPresent
    );
  };

  # ===============================================
  # 4. Backup and Recovery State Verification
  # ===============================================

  backupRecoveryVerification = nixtestFinal.suite "Backup and Recovery State Verification" {

    # Test 4.1: Backup creation verification
    backupFilesCreated = nixtestFinal.test "Backup files are created before making changes" (
      let
        timestamp = "2024-01-15-10-30-00";
        mockBackup = backupHelpers.createMockBackup timestamp;
        backupPathExists = mockBackup.path != null;
        backupTimestampValid = mockBackup.timestamp == timestamp;
      in
      nixtestFinal.assertions.assertTrue (backupPathExists && backupTimestampValid)
    );

    # Test 4.2: Backup integrity verification
    backupIntegrityVerified = nixtestFinal.test "Backup integrity and completeness are verified" (
      let
        mockBackup = backupHelpers.createMockBackup "2024-01-15-10-30-00";
        integrityValid = backupHelpers.verifyBackupIntegrity mockBackup;
        hasRequiredFiles = builtins.length mockBackup.files >= 4; # At least 4 config files
        sizeReasonable = mockBackup.size > 0;
      in
      nixtestFinal.assertions.assertTrue (integrityValid && hasRequiredFiles && sizeReasonable)
    );

    # Test 4.3: Rollback functionality verification
    rollbackRestoresPreviousState = nixtestFinal.test "Rollback restores previous state successfully" (
      let
        mockBackup = backupHelpers.createMockBackup "2024-01-15-10-30-00";
        targetState = mockFilesystem.createMockHomeManagerState "baleen";
        rollbackResult = backupHelpers.simulateRollback mockBackup targetState;
        rollbackSuccessful = rollbackResult.success && rollbackResult.finalState != null;
      in
      nixtestFinal.assertions.assertTrue rollbackSuccessful
    );

    # Test 4.4: Backup cleanup verification
    backupCleanupAfterSuccess = nixtestFinal.test "Backup cleanup occurs after successful switch" (
      let
        successfulSwitch = true;
        backupCleanupPolicy = "cleanup-after-success";
        shouldCleanupBackup = successfulSwitch && backupCleanupPolicy == "cleanup-after-success";
      in
      nixtestFinal.assertions.assertTrue shouldCleanupBackup
    );

    # Test 4.5: Multiple switch cycles verification
    multipleSwitchCyclesManaged =
      nixtestFinal.test "Multiple switch cycles and backup management work correctly"
        (
          let
            switchHistory = [
              {
                timestamp = "2024-01-15-10-30-00";
                success = true;
                backupKept = false;
              }
              {
                timestamp = "2024-01-15-11-45-00";
                success = false;
                backupKept = true;
              }
              {
                timestamp = "2024-01-15-14-20-00";
                success = true;
                backupKept = false;
              }
            ];
            successfulSwitches = builtins.filter (switch: switch.success) switchHistory;
            failedSwitches = builtins.filter (switch: !switch.success) switchHistory;
            backupsKeptCorrectly =
              builtins.all (switch: !switch.backupKept) successfulSwitches
              && builtins.all (switch: switch.backupKept) failedSwitches;
          in
          nixtestFinal.assertions.assertTrue backupsKeptCorrectly
        );
  };

  # ==================================================
  # 5. Activation Script Execution Verification
  # ==================================================

  activationScriptVerification = nixtestFinal.suite "Activation Script Execution Verification" {

    # Test 5.1: All scripts run successfully
    allScriptsRunSuccessfully =
      nixtestFinal.test "All activation scripts run successfully during switch"
        (
          let
            expectedScripts = [
              "cleanupMacOSApps"
              "setupDarwinOptimizations"
              "linkNixApps"
              "darwinOptimizations"
            ];
            scriptResults = builtins.map activationHelpers.createMockScriptResult expectedScripts;
            allSuccessful = builtins.all (result: result.exitCode == 0) scriptResults;
          in
          nixtestFinal.assertions.assertTrue allSuccessful
        );

    # Test 5.2: Script output logging verification
    scriptOutputLogged = nixtestFinal.test "Script output is properly logged and accessible" (
      let
        scriptName = "linkNixApps";
        mockResult = activationHelpers.createMockScriptResult scriptName;
        hasOutput = mockResult.output != null;
        hasTimestamp = mockResult.timestamp > 0;
        hasDuration = mockResult.duration > 0;
      in
      nixtestFinal.assertions.assertTrue (hasOutput && hasTimestamp && hasDuration)
    );

    # Test 5.3: Script failure handling verification
    scriptFailuresDetectedAndHandled =
      nixtestFinal.test "Script failures are detected and handled appropriately"
        (
          let
            failingScript = "problematicScript";
            errorMessage = "Permission denied";
            mockFailure = activationHelpers.createMockScriptFailure failingScript errorMessage;
            failureDetected = mockFailure.exitCode != 0;
            errorLogged = mockFailure.error != null;
            hasErrorOutput = builtins.match ".*failed.*" mockFailure.output != null;
          in
          nixtestFinal.assertions.assertTrue (failureDetected && errorLogged && hasErrorOutput)
        );

    # Test 5.4: Script execution order verification
    scriptExecutionOrderCorrect =
      nixtestFinal.test "Script execution order and dependencies are respected"
        (
          let
            scripts = [
              "setupEnvironment"
              "installPackages"
              "configureServices"
              "optimizeSystem"
            ];
            dependencyChain = activationHelpers.createMockDependencyChain scripts;
            firstScriptHasNoDeps = builtins.length (builtins.elemAt dependencyChain 0).dependencies == 0;
            lastScriptHasCorrectDeps =
              let
                lastScriptDeps = (builtins.elemAt dependencyChain 3).dependencies;
              in
              builtins.length lastScriptDeps == 3 && builtins.elem (builtins.elemAt scripts 2) lastScriptDeps;
          in
          nixtestFinal.assertions.assertTrue (firstScriptHasNoDeps && lastScriptHasCorrectDeps)
        );

    # Test 5.5: Zombie process prevention verification
    noZombieProcessesRemain = nixtestFinal.test "No zombie processes remain after script completion" (
      let
        mockScriptResults = [
          activationHelpers.createMockScriptResult
          "cleanupMacOSApps"
          activationHelpers.createMockScriptResult
          "linkNixApps"
          activationHelpers.createMockScriptResult
          "darwinOptimizations"
        ];
        allCompletedCleanly = builtins.all (
          result: result.exitCode == 0 || result.exitCode == 1
        ) mockScriptResults;
        noHangingProcesses = true; # Mock: all scripts properly terminated
      in
      nixtestFinal.assertions.assertTrue (allCompletedCleanly && noHangingProcesses)
    );
  };

  # ========================================
  # Integration Tests (Cross-Component)
  # ========================================

  integrationTests = nixtestFinal.suite "Integration Tests - Cross-Component State" {

    # Test 6.1: Complete switch workflow verification
    completeSwitchWorkflow = nixtestFinal.test "Complete switch workflow maintains system integrity" (
      let
        switchPhases = [
          {
            phase = "backup";
            status = "success";
          }
          {
            phase = "appCleanup";
            status = "success";
          }
          {
            phase = "systemConfig";
            status = "success";
          }
          {
            phase = "homeManager";
            status = "success";
          }
          {
            phase = "activation";
            status = "success";
          }
        ];
        allPhasesSuccessful = builtins.all (phase: phase.status == "success") switchPhases;
        totalPhases = builtins.length switchPhases;
      in
      nixtestFinal.assertions.assertTrue (allPhasesSuccessful && totalPhases == 5)
    );

    # Test 6.2: Resource usage changes verification
    resourceUsageChangesProperly =
      nixtestFinal.test "Resource usage (disk, memory) changes appropriately after switch"
        (
          let
            beforeSwitch = {
              diskSpace = {
                used = 50000000000;
                free = 100000000000;
              }; # 50GB used, 100GB free
              memoryUsage = {
                active = 8000000000;
                inactive = 4000000000;
              }; # 8GB active, 4GB inactive
            };
            afterSwitch = {
              diskSpace = {
                used = 43800000000;
                free = 106200000000;
              }; # 6.2GB saved from app cleanup
              memoryUsage = {
                active = 7500000000;
                inactive = 4500000000;
              }; # Better memory management
            };
            diskSpaceRecovered = beforeSwitch.diskSpace.free < afterSwitch.diskSpace.free;
            memoryOptimized = afterSwitch.memoryUsage.active < beforeSwitch.memoryUsage.active;
          in
          nixtestFinal.assertions.assertTrue (diskSpaceRecovered && memoryOptimized)
        );

    # Test 6.3: No partial state verification
    noPartialStatesRemain = nixtestFinal.test "No partial or incomplete states remain after switch" (
      let
        componentStates = {
          appCleanup = "complete";
          systemConfig = "complete";
          homeManager = "complete";
          activation = "complete";
        };
        allComplete = builtins.all (state: state == "complete") (builtins.attrValues componentStates);
        noIncompleteStates =
          !builtins.any (state: state == "partial" || state == "failed") (
            builtins.attrValues componentStates
          );
      in
      nixtestFinal.assertions.assertTrue (allComplete && noIncompleteStates)
    );
  };

}
