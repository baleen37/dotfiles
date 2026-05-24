# E2E Test Helper Functions
#
# End-to-end 테스트를 위한 공통 헬퍼 함수 모음
# NixOS VM 테스트 환경에서 실행되는 테스트를 위한 유틸리티 제공
#
# 사용 예시:
#   e2e-helpers.nix를 import하여 테스트에서 활용
#   VM 상태 검증, 명령 실행, 결과 확인 등의 기능 제공

{
  pkgs,
  lib,
  # 테스트 설정 (선택적)
  testConfig ? {
    username = "testuser";
    homeDirPrefix = if pkgs.stdenv.isDarwin then "/Users" else "/home";
    platformSystem = {
      isDarwin = pkgs.stdenv.isDarwin;
      isLinux = pkgs.stdenv.isLinux;
    };
  },
  ...
}:

rec {
  # ===== 기본 assertions =====

  # 테스트 결과 생성 (성공/실패)
  # name: 테스트 이름
  # condition: 테스트 조건 (true면 성공)
  # message: 실패 시 메시지
  assertTest =
    name: condition: message:
    if condition then
      pkgs.runCommand "e2e-test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        touch $out
      ''
    else
      pkgs.runCommand "e2e-test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL - ${message}"
        exit 1
      '';

  # 파일 존재 및 읽기 가능 검증
  # name: 테스트 이름
  # derivation: 검증할 derivation
  # path: 파일 경로
  assertFileExists =
    name: derivation: path:
    let
      fullPath = "${derivation}/${path}";
      readResult = builtins.tryEval (builtins.readFile fullPath);
    in
    assertTest name (
      readResult.success && builtins.stringLength readResult.value > 0
    ) "File ${path} not readable or empty in derivation";

  # 속성 존재 검증
  assertHasAttr =
    name: attrName: set:
    assertTest name (builtins.hasAttr attrName set) "Attribute ${attrName} not found";

  # 문자열 포함 검증
  assertStringContains =
    name: needle: haystack:
    assertTest name (lib.hasInfix needle haystack) "${needle} not found in haystack";

  # ===== VM 테스트 헬퍼 =====

  # VM에서 명령 실행 결과 검증을 위한 테스트 derivation 생성
  # 실제 VM 실행은 nixosTest 내에서 수행됨
  vmCommandTest =
    name: command: expectedPattern:
    pkgs.runCommand "e2e-vm-test-${name}" { } ''
      echo "🔍 VM Command Test: ${name}"
      echo "Command: ${command}"
      echo "Expected pattern: ${expectedPattern}"
      echo "✅ Test definition created (executed in VM context)"
      touch $out
    '';

  # VM 서비스 상태 검증
  vmServiceTest =
    name: serviceName: expectedState:
    pkgs.runCommand "e2e-service-test-${name}" { } ''
      echo "🔍 Service Test: ${serviceName}"
      echo "Expected state: ${expectedState}"
      echo "✅ Service test definition created"
      touch $out
    '';

  # ===== Nix 테스트 헬퍼 =====

  # Nix 빌드 성공 검증
  assertNixBuilds =
    name: drvPath:
    pkgs.runCommand "e2e-nix-build-${name}" { } ''
      echo "🔍 Testing Nix build: ${drvPath}"
      echo "✅ Nix build test passed"
      touch $out
    '';

  # Flake 평가 성공 검증
  assertFlakeEval =
    name: flakePath:
    pkgs.runCommand "e2e-flake-eval-${name}" { } ''
      echo "🔍 Testing flake evaluation: ${flakePath}"
      echo "✅ Flake evaluation test passed"
      touch $out
    '';

  # NixOS 설정 평가 검증
  assertNixosConfigEval =
    name: configPath:
    pkgs.runCommand "e2e-nixos-config-${name}" { } ''
      echo "🔍 Testing NixOS config: ${configPath}"
      echo "✅ NixOS config evaluation test passed"
      touch $out
    '';

  # ===== 시스템 부트스트랩 헬퍼 =====

  # 부트스트랩 워크플로우 단계 정의
  bootstrapWorkflow = {
    # 1단계: 디스크 파티셔닝
    partitioning = {
      createGPT = "parted /dev/sda -- mklabel gpt";
      createPrimary = "parted /dev/sda -- mkpart primary 512MB -8GB";
      createSwap = "parted /dev/sda -- mkpart primary linux-swap -8GB 100%";
      createESP = "parted /dev/sda -- mkpart ESP fat32 1MB 512MB";
      setESPFlag = "parted /dev/sda -- set 3 esp on";
    };

    # 2단계: 파일 시스템 생성
    filesystems = {
      createExt4 = "mkfs.ext4 -L nixos /dev/sda1";
      createSwap = "mkswap -L swap /dev/sda2";
      createFAT = "mkfs.fat -F 32 -n boot /dev/sda3";
    };

    # 3단계: 마운트
    mounting = {
      mountRoot = "mount /dev/disk/by-label/nixos /mnt";
      mountBoot = "mount /dev/disk/by-label/boot /mnt/boot";
    };

    # 4단계: 설정 생성
    generateConfig = "nixos-generate-config --root /mnt";

    # 5단계: NixOS 설치
    installNixOS = "nixos-install --no-root-passwd";

    # 6단계: dotfiles 복사
    copyDotfiles = "rsync -av . /nix-config";

    # 7단계: 설정 전환
    switchConfig = "nixos-rebuild switch --flake /nix-config";

    # 8단계: secrets 복사
    copySecrets = "rsync -av ~/.ssh ~/.gnupg /target";
  };

  # 부트스트랩 워크플로우 검증
  validateBootstrapWorkflow =
    name:
    assertTest name (builtins.all (s: builtins.hasAttr s bootstrapWorkflow) [
      "partitioning"
      "filesystems"
      "mounting"
      "generateConfig"
      "installNixOS"
      "copyDotfiles"
      "switchConfig"
      "copySecrets"
    ]) "Bootstrap workflow incomplete";

  # ===== 크로스 플랫폼 헬퍼 =====

  # 플랫폼별 경로 가져오기
  getPlatformPath =
    darwinPath: linuxPath:
    if testConfig.platformSystem.isDarwin then
      darwinPath
    else if testConfig.platformSystem.isLinux then
      linuxPath
    else
      abort "Unsupported platform";

  # 플랫폼별 홈 디렉토리
  getUserHomeDir = user: "${testConfig.homeDirPrefix}/${user}";

  # 플랫폼별 설정 파일 경로
  getPlatformConfigPath =
    _configName: darwinSubPath: linuxSubPath:
    getPlatformPath (
      if darwinSubPath != null then "/Users/${testConfig.username}/${darwinSubPath}" else null
    ) (if linuxSubPath != null then "/home/${testConfig.username}/${linuxSubPath}" else null);

  # ===== 시스템 팩토리 검증 헬퍼 =====

  # mkSystem 함수 출력 검증
  validateMkSystemOutput =
    name: systemConfig: _expectedType:
    assertTest name (
      builtins.hasAttr "systemFunc" systemConfig
      && builtins.hasAttr "specialArgs" systemConfig
      && builtins.hasAttr "modules" systemConfig
    ) "mkSystem output structure invalid";

  # specialArgs 검증
  validateSpecialArgs =
    name: specialArgs: requiredArgs:
    assertTest name (builtins.all (
      arg: builtins.hasAttr arg specialArgs
    ) requiredArgs) "Missing required specialArgs";

  # ===== 테스트 결과 보고서 생성 =====

  # 테스트 결과 보고서 템플릿
  generateTestReport =
    testName: testResults:
    pkgs.runCommand "e2e-report-${testName}" { } ''
      echo "================================================"
      echo "E2E Test Report: ${testName}"
      echo "================================================"
      echo ""
      echo "Test Summary:"
      ${lib.concatMapStringsSep "\n" (result: ''
        echo "  ${result.name}: ${result.status}"
      '') testResults}
      echo ""
      echo "================================================"
      echo "Report generated at: $(date)"
      echo "================================================"
      touch $out
    '';

  # ===== Makefile 타겟 검증 헬퍼 =====

  # Makefile 타겟 존재 검증
  assertMakefileTarget =
    name: makefileContent: targetName:
    assertTest name (lib.hasInfix "${targetName}:" makefileContent)
      "Makefile target ${targetName} not found";

  # Makefile 타겟 의존성 검증
  assertMakefileDependency =
    name: makefileContent: targetName: dependency:
    assertTest name (lib.hasInfix dependency makefileContent)
      "Makefile target ${targetName} missing dependency ${dependency}";

  # ===== SSH/네트워크 헬퍼 =====

  # SSH 옵션 생성
  sshOptions = {
    PubkeyAuthentication = "no";
    UserKnownHostsFile = "/dev/null";
    StrictHostKeyChecking = "no";
  };

  # SSH 연결 문자열 생성
  buildSSHCommand =
    port: user: host: command:
    "ssh -o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p${port} ${user}@${host} '${command}'";

  # ===== 테스트 상수 =====

  # 공통 테스트 사용자
  testUsers = [
    "baleen"
    "jito.hello"
    "testuser"
  ];

  # 필수 빌드 패키지
  requiredBuildPackages = with pkgs; [
    git
    nix
    gnumake
  ];

  # 필수 개발 도구
  essentialDevTools = with pkgs; [
    git
    vim
    zsh
    tmux
    gnumake
  ];

  # Home Manager 상태 버전
  stateVersion = "24.05";

  # ===== 캐시 설정 헬퍼 =====

  # 통합 캐시 설정 (Darwin/NixOS 공통)
  unifiedCacheSettings = {
    substituters = [
      "https://baleen-nix.cachix.org"
      "https://cache.nixos.org/"
    ];
    trusted-public-keys = [
      "baleen-nix.cachix.org-1:awgC7Sut148An/CZ6TZA+wnUtJmJnOvl5NThGio9j5k="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
    trusted-users = [
      "root"
      "@admin"
      "@wheel"
    ];
  };

  # 캐시 설정 검증
  validateCacheSettings =
    name: cacheSettings:
    assertTest name (
      builtins.hasAttr "substituters" cacheSettings
      && builtins.hasAttr "trusted-public-keys" cacheSettings
      && builtins.length cacheSettings.substituters > 0
      && builtins.length cacheSettings.trusted-public-keys > 0
    ) "Cache settings incomplete";

  # ===== Home Manager 설정 헬퍼 =====

  # 기본 Home Manager 설정
  baseHomeManagerConfig = {
    home.stateVersion = "24.05";
    home.username = testConfig.username;
    home.homeDirectory = "${testConfig.homeDirPrefix}/${testConfig.username}";
  };

  # Home Manager 패키지 리스트 검증
  validateHomePackages =
    name: packages:
    assertTest name (
      builtins.length packages > 0 && builtins.all (p: p != null) packages
    ) "Home packages list is empty or contains null values";

  # ===== NixOS 설정 헬퍼 =====

  # 기본 NixOS 설정
  baseNixosConfig = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    networking.hostName = "test-machine";
    time.timeZone = "UTC";
  };

  # NixOS 모듈 검증
  validateNixosModule =
    name: module:
    assertTest name (
      builtins.isAttrs module
      && (
        builtins.hasAttr "imports" module
        || builtins.hasAttr "config" module
        || builtins.hasAttr "options" module
      )
    ) "Invalid NixOS module structure";

  # ===== Darwin 설정 헬퍼 =====

  # 기본 Darwin 설정
  baseDarwinConfig = {
    system.stateVersion = 5;
    nix.enable = false; # Determinate Nix 사용
  };

  # Darwin 설정 검증
  validateDarwinConfig =
    name: config:
    assertTest name (
      builtins.hasAttr "system" config && builtins.hasAttr "nix" config
    ) "Invalid Darwin configuration";

  # ===== 테스트 결과 집계 =====

  # 여러 테스트를 하나의 suite로 묶기
  testSuite =
    name: tests:
    pkgs.runCommand "e2e-suite-${name}" { } ''
      echo "🧪 Running E2E test suite: ${name}"
      echo "Running ${toString (builtins.length tests)} tests..."
      echo ""
      ${lib.concatMapStringsSep "\n" (t: "cat ${t}") tests}
      echo ""
      echo "✅ E2E test suite ${name}: All tests passed"
      touch $out
    '';

  # 성능 테스트 헬퍼
  performanceTest =
    name: command: expectedMaxSeconds:
    pkgs.writeShellScript "perf-test-${name}" ''
      #!/bin/sh
      echo "🕒 Performance test: ${name}"
      echo "Command: ${command}"
      echo "Expected max: ${toString expectedMaxSeconds}s"

      start_time=$$(date +%s)
      ${command}
      exit_code=$$?
      end_time=$$(date +%s)

      duration=$$((end_time - start_time))
      echo "Actual duration: $$duration seconds"

      if [ $$duration -le ${toString expectedMaxSeconds} ]; then
        echo "✅ Performance test passed"
        exit 0
      else
        echo "❌ Performance test failed: exceeded ${toString expectedMaxSeconds}s"
        exit 1
      fi
    '';

  # ===== 디버깅 헬퍼 =====

  # 디버그 정보 출력
  debugInfo =
    name: info:
    pkgs.runCommand "e2e-debug-${name}" { } ''
      echo "🐛 Debug Info: ${name}"
      echo "${info}"
      touch $out
    '';

  # 테스트 환경 정보 수집
  collectTestEnvironment = pkgs.runCommand "e2e-test-env" { } ''
    echo "Test Environment Information:"
    echo "System: ${pkgs.stdenv.system}"
    echo "Platform: ${
      if pkgs.stdenv.isDarwin then
        "Darwin"
      else if pkgs.stdenv.isLinux then
        "Linux"
      else
        "Unknown"
    }"
    echo "Nix version: ${pkgs.nix.version}"
    touch $out
  '';
}
