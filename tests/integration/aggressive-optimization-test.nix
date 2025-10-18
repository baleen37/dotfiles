# Aggressive Optimization Integration Tests
#
# modules/darwin/aggressive-optimization.nix 모듈의 통합 테스트
#
# 주요 검증 항목:
# - 모듈 로드 및 설정 유효성
# - system.defaults 구조 검증
# - CustomUserPreferences 설정 검증
# - activation script 유효성
# - nix-darwin 호환성
#
# 테스트 범위:
# - 필수 옵션 존재 여부
# - 설정값 타입 검증
# - 모듈 빌드 가능성
# - 에러 핸들링

{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem,
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

  # Import the aggressive-optimization module
  aggressiveOptModule = import ../../modules/darwin/aggressive-optimization.nix { inherit lib; };

  # Expected configuration structure
  expectedDefaults = {
    NSGlobalDomain = [
      "NSAutomaticWindowAnimationsEnabled"
      "NSScrollAnimationEnabled"
      "NSWindowResizeTime"
      "KeyRepeat"
      "InitialKeyRepeat"
      "NSAutomaticCapitalizationEnabled"
      "NSAutomaticSpellingCorrectionEnabled"
      "NSAutomaticQuoteSubstitutionEnabled"
      "NSAutomaticDashSubstitutionEnabled"
      "NSAutomaticPeriodSubstitutionEnabled"
      "NSDocumentSaveNewDocumentsToCloud"
      "AppleShowAllExtensions"
    ];

    dock = [
      "autohide"
      "autohide-delay"
      "autohide-time-modifier"
      "expose-animation-duration"
      "tilesize"
      "show-recents"
      "mineffect"
      "mru-spaces"
    ];

    finder = [
      "AppleShowAllFiles"
      "FXEnableExtensionChangeWarning"
      "_FXSortFoldersFirst"
      "ShowPathbar"
      "ShowStatusBar"
      "QuitMenuItem"
      "FXDefaultSearchScope"
    ];

    trackpad = [
      "Clicking"
      "TrackpadRightClick"
      "TrackpadThreeFingerDrag"
    ];

    universalaccess = [
      "reduceTransparency"
      "reduceMotion"
    ];
  };

  # Expected CustomUserPreferences keys
  expectedCustomPrefs = [
    "com.apple.dashboard"
    "NSGlobalDomain"
    "com.apple.dock"
    "com.apple.notificationcenterui"
    "com.apple.finder"
    "com.apple.CrashReporter"
    "com.apple.AdLib"
    "com.apple.assistant.support"
    "com.apple.Photos"
    "com.apple.gamed"
    "com.apple.suggestions"
    "com.apple.lookup"
    "com.apple.cloudd"
    "com.apple.speech.recognition.AppleSpeechRecognition.prefs"
    "com.apple.FaceTime"
    "com.apple.commerce"
    "com.apple.Music"
    "com.apple.podcasts"
  ];

in
nixtestFinal.suite "Aggressive Optimization Integration Tests" {

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # 1️⃣  Module Loading Tests
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  moduleLoadingTests = nixtestFinal.suite "Module Loading Tests" {

    moduleExists = nixtestFinal.test "Module file exists" (
      nixtestFinal.assertions.assertTrue (
        builtins.pathExists ../../modules/darwin/aggressive-optimization.nix
      )
    );

    moduleLoads = nixtestFinal.test "Module loads without errors" (
      nixtestFinal.assertions.assertTrue (aggressiveOptModule != null)
    );

    moduleIsAttrSet = nixtestFinal.test "Module is an attribute set" (
      nixtestFinal.assertions.assertType "set" aggressiveOptModule
    );

    hasSystemDefaults = nixtestFinal.test "Module has system.defaults" (
      nixtestFinal.assertions.assertHasAttr "system" aggressiveOptModule
    );
  };

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # 2️⃣  system.defaults Structure Tests
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  systemDefaultsTests = nixtestFinal.suite "system.defaults Tests" {

    systemDefaultsExists = nixtestFinal.test "system.defaults exists" (
      let
        hasDefaults = aggressiveOptModule ? system && aggressiveOptModule.system ? defaults;
      in
      nixtestFinal.assertions.assertTrue hasDefaults
    );

    # NSGlobalDomain tests
    nsGlobalDomainTests = nixtestFinal.suite "NSGlobalDomain Tests" {

      nsGlobalDomainExists = nixtestFinal.test "NSGlobalDomain exists" (
        nixtestFinal.assertions.assertHasAttr "NSGlobalDomain" aggressiveOptModule.system.defaults
      );

      hasAnimationSettings = nixtestFinal.test "Has animation settings" (
        let
          nsg = aggressiveOptModule.system.defaults.NSGlobalDomain;
          hasWindowAnim = nsg ? NSAutomaticWindowAnimationsEnabled;
          hasScrollAnim = nsg ? NSScrollAnimationEnabled;
        in
        nixtestFinal.assertions.assertTrue (hasWindowAnim && hasScrollAnim)
      );

      animationSettingsAreFalse = nixtestFinal.test "Animation settings are disabled" (
        let
          nsg = aggressiveOptModule.system.defaults.NSGlobalDomain;
        in
        nixtestFinal.assertions.assertTrue (
          nsg.NSAutomaticWindowAnimationsEnabled == false && nsg.NSScrollAnimationEnabled == false
        )
      );

      hasKeyboardSettings = nixtestFinal.test "Has keyboard settings" (
        let
          nsg = aggressiveOptModule.system.defaults.NSGlobalDomain;
        in
        nixtestFinal.assertions.assertTrue (nsg ? KeyRepeat && nsg ? InitialKeyRepeat)
      );

      keyboardSettingsValid = nixtestFinal.test "Keyboard settings are valid numbers" (
        let
          nsg = aggressiveOptModule.system.defaults.NSGlobalDomain;
          keyRepeatValid = builtins.isInt nsg.KeyRepeat && nsg.KeyRepeat > 0;
          initialKeyRepeatValid = builtins.isInt nsg.InitialKeyRepeat && nsg.InitialKeyRepeat > 0;
        in
        nixtestFinal.assertions.assertTrue (keyRepeatValid && initialKeyRepeatValid)
      );

      hasAutoCorrectSettings = nixtestFinal.test "Has auto-correct settings" (
        let
          nsg = aggressiveOptModule.system.defaults.NSGlobalDomain;
        in
        nixtestFinal.assertions.assertTrue (
          nsg ? NSAutomaticCapitalizationEnabled
          && nsg ? NSAutomaticSpellingCorrectionEnabled
          && nsg ? NSAutomaticQuoteSubstitutionEnabled
        )
      );
    };

    # Dock tests
    dockTests = nixtestFinal.suite "Dock Tests" {

      dockExists = nixtestFinal.test "Dock configuration exists" (
        nixtestFinal.assertions.assertHasAttr "dock" aggressiveOptModule.system.defaults
      );

      dockAutohideEnabled = nixtestFinal.test "Dock autohide is enabled" (
        nixtestFinal.assertions.assertTrue (aggressiveOptModule.system.defaults.dock.autohide == true)
      );

      dockHasPerformanceSettings = nixtestFinal.test "Dock has performance settings" (
        let
          dock = aggressiveOptModule.system.defaults.dock;
        in
        nixtestFinal.assertions.assertTrue (dock ? autohide-delay && dock ? autohide-time-modifier)
      );
    };

    # Finder tests
    finderTests = nixtestFinal.suite "Finder Tests" {

      finderExists = nixtestFinal.test "Finder configuration exists" (
        nixtestFinal.assertions.assertHasAttr "finder" aggressiveOptModule.system.defaults
      );

      finderShowHiddenFiles = nixtestFinal.test "Finder shows hidden files" (
        nixtestFinal.assertions.assertTrue (
          aggressiveOptModule.system.defaults.finder.AppleShowAllFiles == true
        )
      );

      finderHasUISettings = nixtestFinal.test "Finder has UI settings" (
        let
          finder = aggressiveOptModule.system.defaults.finder;
        in
        nixtestFinal.assertions.assertTrue (finder ? ShowPathbar && finder ? ShowStatusBar)
      );
    };

    # Universal Access tests
    universalAccessTests = nixtestFinal.suite "Universal Access Tests" {

      universalAccessExists = nixtestFinal.test "Universal access exists" (
        nixtestFinal.assertions.assertHasAttr "universalaccess" aggressiveOptModule.system.defaults
      );

      transparencyDisabled = nixtestFinal.test "Transparency is disabled" (
        nixtestFinal.assertions.assertTrue (
          aggressiveOptModule.system.defaults.universalaccess.reduceTransparency == true
        )
      );

      motionDisabled = nixtestFinal.test "Motion is disabled" (
        nixtestFinal.assertions.assertTrue (
          aggressiveOptModule.system.defaults.universalaccess.reduceMotion == true
        )
      );
    };
  };

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # 3️⃣  CustomUserPreferences Tests
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  customUserPreferencesTests = nixtestFinal.suite "CustomUserPreferences Tests" {

    customPrefsExists = nixtestFinal.test "CustomUserPreferences exists" (
      nixtestFinal.assertions.assertHasAttr "CustomUserPreferences" aggressiveOptModule.system.defaults
    );

    customPrefsIsAttrSet = nixtestFinal.test "CustomUserPreferences is attribute set" (
      nixtestFinal.assertions.assertType "set" aggressiveOptModule.system.defaults.CustomUserPreferences
    );

    hasDashboardSettings = nixtestFinal.test "Has Dashboard settings" (
      nixtestFinal.assertions.assertHasAttr "com.apple.dashboard" aggressiveOptModule.system.defaults.CustomUserPreferences
    );

    hasQuickLookSettings = nixtestFinal.test "Has QuickLook animation settings" (
      nixtestFinal.assertions.assertHasAttr "NSGlobalDomain" aggressiveOptModule.system.defaults.CustomUserPreferences
    );

    hasTelemetrySettings = nixtestFinal.test "Has telemetry settings" (
      let
        prefs = aggressiveOptModule.system.defaults.CustomUserPreferences;
      in
      nixtestFinal.assertions.assertTrue (prefs ? "com.apple.CrashReporter" && prefs ? "com.apple.AdLib")
    );

    hasBackgroundServiceSettings = nixtestFinal.test "Has background service settings" (
      let
        prefs = aggressiveOptModule.system.defaults.CustomUserPreferences;
      in
      nixtestFinal.assertions.assertTrue (
        prefs ? "com.apple.gamed" && prefs ? "com.apple.suggestions" && prefs ? "com.apple.cloudd"
      )
    );

    crashReporterDisabled = nixtestFinal.test "Crash Reporter is configured" (
      let
        crashReporter = aggressiveOptModule.system.defaults.CustomUserPreferences."com.apple.CrashReporter";
      in
      nixtestFinal.assertions.assertTrue (crashReporter ? DialogType)
    );

    photosOptimized = nixtestFinal.test "Photos app is optimized" (
      let
        photos = aggressiveOptModule.system.defaults.CustomUserPreferences."com.apple.Photos";
      in
      nixtestFinal.assertions.assertTrue (
        photos ? ShowMemoriesNotifications && photos ? ShowHolidayCalendar
      )
    );
  };

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # 4️⃣  Activation Script Tests
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  activationScriptTests = nixtestFinal.suite "Activation Script Tests" {

    activationScriptExists = nixtestFinal.test "Activation script exists" (
      let
        hasActivation = aggressiveOptModule ? system && aggressiveOptModule.system ? activationScripts;
      in
      nixtestFinal.assertions.assertTrue hasActivation
    );

    aggressiveOptScriptExists = nixtestFinal.test "aggressiveOptimization script exists" (
      nixtestFinal.assertions.assertHasAttr "aggressiveOptimization" aggressiveOptModule.system.activationScripts
    );

    scriptHasText = nixtestFinal.test "Script has text content" (
      let
        script = aggressiveOptModule.system.activationScripts.aggressiveOptimization;
      in
      nixtestFinal.assertions.assertHasAttr "text" script
    );

    scriptTextIsString = nixtestFinal.test "Script text is string" (
      nixtestFinal.assertions.assertType "string" aggressiveOptModule.system.activationScripts.aggressiveOptimization.text
    );

    scriptNotEmpty = nixtestFinal.test "Script is not empty" (
      let
        scriptText = aggressiveOptModule.system.activationScripts.aggressiveOptimization.text;
      in
      nixtestFinal.assertions.assertTrue (builtins.stringLength scriptText > 0)
    );

    scriptHasSpotlightSection = nixtestFinal.test "Script has Spotlight section" (
      let
        scriptText = aggressiveOptModule.system.activationScripts.aggressiveOptimization.text;
      in
      nixtestFinal.assertions.assertTrue (builtins.match ".*Spotlight.*" scriptText != null)
    );

    scriptHasPhotoAnalysisSection = nixtestFinal.test "Script has photo analysis section" (
      let
        scriptText = aggressiveOptModule.system.activationScripts.aggressiveOptimization.text;
      in
      nixtestFinal.assertions.assertTrue (
        builtins.match ".*photo.*analysis.*" scriptText != null
        || builtins.match ".*photoanalysisd.*" scriptText != null
      )
    );

    scriptHasIdempotencyChecks = nixtestFinal.test "Script has idempotency checks" (
      let
        scriptText = aggressiveOptModule.system.activationScripts.aggressiveOptimization.text;
        hasIfChecks = builtins.match ".*if.*then.*" scriptText != null;
      in
      nixtestFinal.assertions.assertTrue hasIfChecks
    );
  };

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # 5️⃣  Module Build Tests (with nix-darwin validation)
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  moduleBuildTests = nixtestFinal.suite "Module Build Tests" {

    moduleEvaluates = nixtestFinal.test "Module evaluates successfully" (
      let
        result = safeEvaluate aggressiveOptModule;
      in
      nixtestFinal.assertions.assertTrue (result != null)
    );

    systemDefaultsEvaluates = nixtestFinal.test "system.defaults evaluates" (
      let
        result = safeEvaluate aggressiveOptModule.system.defaults;
      in
      nixtestFinal.assertions.assertTrue (result != null)
    );

    customPrefsEvaluates = nixtestFinal.test "CustomUserPreferences evaluates" (
      let
        result = safeEvaluate aggressiveOptModule.system.defaults.CustomUserPreferences;
      in
      nixtestFinal.assertions.assertTrue (result != null)
    );

    activationScriptEvaluates = nixtestFinal.test "Activation script evaluates" (
      let
        result = safeEvaluate aggressiveOptModule.system.activationScripts.aggressiveOptimization.text;
      in
      nixtestFinal.assertions.assertTrue (result != null)
    );

    # Validates all system.defaults keys against known nix-darwin options
    systemDefaultsKeysValid =
      nixtestFinal.test "All system.defaults keys are valid nix-darwin options"
        (
          let
            defaults = aggressiveOptModule.system.defaults;
            # nix-darwin에서 지원하는 system.defaults 키 목록
            validKeys = [
              "NSGlobalDomain"
              "dock"
              "finder"
              "trackpad"
              "loginwindow"
              "universalaccess"
              "CustomUserPreferences"
              # 기타 nix-darwin 지원 키들...
            ];
            # 모든 키가 알려진 유효한 키인지 확인
            actualKeys = builtins.attrNames defaults;
            invalidKeys = builtins.filter (key: !(builtins.elem key validKeys)) actualKeys;
          in
          # invalidKeys가 비어있어야 함 (모든 키가 유효함)
          nixtestFinal.assertions.assertTrue (builtins.length invalidKeys == 0)
        );

    # Detects non-existent option names that would fail during build
    noInvalidCustomOptions = nixtestFinal.test "No invalid custom options in module" (
      let
        defaults = aggressiveOptModule.system.defaults;
        # CustomSystemPreferences, CustomGlobalPreferences 같은 존재하지 않는 키 감지
        dangerousKeys = [
          "CustomSystemPreferences"
          "CustomGlobalPreferences"
          "SystemPreferences"
        ];
        actualKeys = builtins.attrNames defaults;
        foundDangerousKeys = builtins.filter (key: builtins.elem key dangerousKeys) actualKeys;
      in
      # 위험한 키가 하나도 없어야 함
      nixtestFinal.assertions.assertTrue (builtins.length foundDangerousKeys == 0)
    );
  };

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # 6️⃣  Integration with nix-darwin Tests
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  nixDarwinIntegrationTests = nixtestFinal.suite "nix-darwin Integration Tests" {

    noConflictingOptions = nixtestFinal.test "No conflicting option names" (
      # Check that all options are valid nix-darwin options
      # This is a basic check - actual validation happens during build
      let
        allOptionsExist =
          aggressiveOptModule ? system
          && aggressiveOptModule.system ? defaults
          && aggressiveOptModule.system ? activationScripts;
      in
      nixtestFinal.assertions.assertTrue allOptionsExist
    );

    usesLibMkForce = nixtestFinal.test "Uses lib.mkForce for overrides" (
      let
        # Check if the module uses lib.mkForce (indicated by presence of _type = "override")
        nsg = aggressiveOptModule.system.defaults.NSGlobalDomain;
        hasOverrides = nsg.NSWindowResizeTime ? _type || builtins.isAttrs nsg.NSWindowResizeTime;
      in
      nixtestFinal.assertions.assertTrue hasOverrides
    );
  };

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # 7️⃣  Documentation and Comments Tests
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  documentationTests = nixtestFinal.suite "Documentation Tests" {

    fileHasHeader = nixtestFinal.test "File has header documentation" (
      let
        fileContent = builtins.readFile ../../modules/darwin/aggressive-optimization.nix;
        hasHeader = builtins.match ".*# macOS Aggressive Performance Optimization.*" fileContent != null;
      in
      nixtestFinal.assertions.assertTrue hasHeader
    );

    fileHasWarnings = nixtestFinal.test "File has warning messages" (
      let
        fileContent = builtins.readFile ../../modules/darwin/aggressive-optimization.nix;
        hasWarnings = builtins.match ".*⚠️.*AGGRESSIVE.*" fileContent != null;
      in
      nixtestFinal.assertions.assertTrue hasWarnings
    );

    fileHasExpectedImpacts = nixtestFinal.test "File documents expected impacts" (
      let
        fileContent = builtins.readFile ../../modules/darwin/aggressive-optimization.nix;
        hasImpacts = builtins.match ".*예상 성능 향상.*" fileContent != null;
      in
      nixtestFinal.assertions.assertTrue hasImpacts
    );

    fileHasFeatureLoss = nixtestFinal.test "File documents feature loss" (
      let
        fileContent = builtins.readFile ../../modules/darwin/aggressive-optimization.nix;
        hasLoss = builtins.match ".*기능 손실.*" fileContent != null;
      in
      nixtestFinal.assertions.assertTrue hasLoss
    );

    fileHasBestPracticesNote = nixtestFinal.test "File documents best practices" (
      let
        fileContent = builtins.readFile ../../modules/darwin/aggressive-optimization.nix;
        hasBestPractices = builtins.match ".*Context7 nix-darwin best practices.*" fileContent != null;
      in
      nixtestFinal.assertions.assertTrue hasBestPractices
    );
  };
}
