# tests/lib/patterns.nix
#
# 공통 테스트 패턴 추출 및 재사용 가능한 테스트 템플릿
#
# 이 파일은 다음과 같은 공통 테스트 패턴을 제공합니다:
# - 파일 설정 테스트 패턴
# - 패키지 설치 테스트 패턴
# - 사용자 설정 테스트 패턴
# - 시스템 설정 테스트 패턴
# - Home Manager 모듈 테스트 패턴
#
# 사용 예시:
#   patterns = import ../lib/patterns.nix { inherit pkgs lib; };
#   patterns.testFileConfig ".vimrc" vimConfig
#   patterns.testPackageInstalled "git" homeConfig

{
  pkgs,
  lib,
  # 기본 헬퍼 함수들 (test-helpers.nix에서 가져옴)
  helpers ? null,
}:

let
  # helpers가 제공되지 않은 경우 기본 헬퍼 사용
  baseHelpers = if helpers != null then helpers else import ./test-helpers.nix { inherit pkgs lib; };
  inherit (baseHelpers)
    assertTest
    testSuite
    assertHasAttr
    assertContains
    assertFileExists
    ;
in

rec {
  # ===== 파일 설정 테스트 패턴 =====

  # Home Manager 파일 설정 테스트
  #
  # Home Manager의 home.file 또는 xdg.configFile에 파일이 올바르게 설정되었는지 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - homeConfig: Home Manager 설정
  #   - expectedFiles: 예상되는 파일 목록 (속성셋 또는 리스트)
  #
  # Example:
  #   testHomeFileConfig "vim-files" hmConfig {
  #     ".vimrc" = true;
  #     ".vim/plugin/statusline.vim" = true;
  #   }
  testHomeFileConfig =
    name: homeConfig: expectedFiles:
    let
      homeFiles = homeConfig.home.file or { };
      xdgFiles = homeConfig.xdg.configFile or { };
      allFiles = homeFiles // xdgFiles;

      # 리스트인 경우 속성셋으로 변환
      fileSet =
        if builtins.typeOf expectedFiles == "list" then
          builtins.listToAttrs (
            map (f: {
              name = f;
              value = true;
            }) expectedFiles
          )
        else
          expectedFiles;

      # 각 파일에 대한 테스트 생성
      fileTests = builtins.map (filePath: {
        name = "${name}-${builtins.replaceStrings [ "/" "." ] [ "-" "-" ] filePath}";
        value =
          assertTest "${name}-file-${filePath}" (builtins.hasAttr filePath allFiles)
            "Home file should include ${filePath}";
      }) (builtins.attrNames fileSet);

      summaryTest = {
        name = "${name}-summary";
        value = pkgs.runCommand "${name}-files-summary" { } ''
          echo "Home file configuration '${name}': ${toString (builtins.length fileTests)} files validated"
          touch $out
        '';
      };
    in
    builtins.listToAttrs (fileTests ++ [ summaryTest ]);

  # ===== 패키지 설치 테스트 패턴 =====

  # Home Manager 패키지 설치 테스트
  #
  # Home Manager의 home.packages에 패키지가 올바르게 포함되어 있는지 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - homeConfig: Home Manager 설정
  #   - expectedPackages: 예상되는 패키지 이름 목록
  #
  # Example:
  #   testPackagesInstalled "dev-tools" hmConfig [ "git" "vim" "tmux" ]
  testPackagesInstalled =
    name: homeConfig: expectedPackages:
    let
      packages = homeConfig.home.packages or [ ];

      # 패키지 존재 확인 헬퍼
      hasPackage = packageName: builtins.any (pkg: pkg.pname or null == packageName) packages;

      # 각 패키지에 대한 테스트 생성
      packageTests = builtins.map (pkgName: {
        name = "${name}-${pkgName}";
        value =
          assertTest "${name}-pkg-${pkgName}" (hasPackage pkgName)
            "Package ${pkgName} should be installed";
      }) expectedPackages;

      summaryTest = {
        name = "${name}-summary";
        value = pkgs.runCommand "${name}-packages-summary" { } ''
          echo "Package group '${name}': ${toString (builtins.length packageTests)} packages validated"
          touch $out
        '';
      };
    in
    builtins.listToAttrs (packageTests ++ [ summaryTest ]);

  # 패키지가 설치되지 않았는지 테스트
  #
  # 특정 패키지가 포함되지 않았는지 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - homeConfig: Home Manager 설정
  #   - unwantedPackages: 설치되지 않아야 할 패키지 이름 목록
  #
  # Example:
  #   testPackagesNotInstalled "no-heavy-packages" hmConfig [ "emacs" "nano" ]
  testPackagesNotInstalled =
    name: homeConfig: unwantedPackages:
    let
      packages = homeConfig.home.packages or [ ];

      hasPackage = packageName: builtins.any (pkg: pkg.pname or null == packageName) packages;
    in
    builtins.map (
      pkgName:
      assertTest "${name}-no-${pkgName}" (
        !(hasPackage pkgName)
      ) "Package ${pkgName} should NOT be installed"
    ) unwantedPackages;

  # ===== 사용자 설정 테스트 패턴 =====

  # 사용자 이름 테스트
  #
  # Home Manager 설정의 사용자 이름이 예상값과 일치하는지 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - homeConfig: Home Manager 설정
  #   - expectedUsername: 예상되는 사용자 이름
  #
  # Example:
  #   testUsername "default-user" hmConfig "baleen"
  testUsername =
    name: homeConfig: expectedUsername:
    assertTest "${name}-username" (
      homeConfig.home.username == expectedUsername
    ) "Username should be ${expectedUsername}";

  # 홈 디렉토리 테스트
  #
  # Home Manager 설정의 홈 디렉토리가 예상값과 일치하는지 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - homeConfig: Home Manager 설정
  #   - expectedHomeDir: 예상되는 홈 디렉토리 경로
  #
  # Example:
  #   testHomeDirectory "darwin-home" hmConfig "/Users/baleen"
  testHomeDirectory =
    name: homeConfig: expectedHomeDir:
    assertTest "${name}-homedir" (
      homeConfig.home.homeDirectory == expectedHomeDir
    ) "Home directory should be ${expectedHomeDir}";

  # XDG 설정 테스트
  #
  # XDG base directory 설정이 활성화되어 있는지 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - homeConfig: Home Manager 설정
  #   - expectedEnabled: 예상되는 XDG 활성화 상태
  #
  # Example:
  #   testXDGEnabled "xdg-enabled" hmConfig true
  testXDGEnabled =
    name: homeConfig: expectedEnabled:
    assertTest "${name}-xdg" ((homeConfig.xdg.enable or false) == expectedEnabled)
      "XDG should be ${if expectedEnabled then "enabled" else "disabled"}";

  # ===== 시스템 설정 테스트 패턴 =====

  # macOS/Darwin 기본 설정 테스트
  #
  # Darwin defaults 시스템 설정이 올바르게 구성되었는지 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - darwinConfig: Darwin 설정
  #   - domain: defaults domain (예: "NSGlobalDomain", "dock")
  #   - expectedSettings: 예상되는 설정값 (속성셋)
  #
  # Example:
  #   testDarwinDefaults "dock-settings" darwinConfig "dock" {
  #     autohide = true;
  #     tilesize = 48;
  #   }
  testDarwinDefaults =
    name: darwinConfig: domain: expectedSettings:
    let
      defaultsConfig =
        if domain == "NSGlobalDomain" then
          darwinConfig.system.defaults.NSGlobalDomain or { }
        else
          darwinConfig.system.defaults.${domain} or { };

      # 각 설정에 대한 테스트 생성
      settingTests = builtins.map (key: {
        name = "${name}-${domain}-${key}";
        value = assertTest "${name}-${domain}-${key}" (
          builtins.hasAttr key defaultsConfig
          && defaultsConfig.${key} == builtins.getAttr key expectedSettings
        ) "Darwin default ${domain}.${key} should be ${toString (builtins.getAttr key expectedSettings)}";
      }) (builtins.attrNames expectedSettings);

      summaryTest = {
        name = "${name}-summary";
        value = pkgs.runCommand "${name}-defaults-summary" { } ''
          echo "Darwin defaults '${name}.${domain}': ${toString (builtins.length settingTests)} settings validated"
          touch $out
        '';
      };
    in
    builtins.listToAttrs (settingTests ++ [ summaryTest ]);

  # ===== Home Manager 모듈 테스트 패턴 =====

  # 모듈 임포트 테스트
  #
  # Home Manager 설정에서 특정 모듈들이 임포트되었는지 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - homeConfig: Home Manager 설정
  #   - expectedModules: 예상되는 임포트 모듈 경로 목록
  #
  # Example:
  #   testModuleImports "tool-modules" hmConfig [
  #     "./git.nix"
  #     "./vim.nix"
  #     "./zsh.nix"
  #   ]
  testModuleImports =
    name: homeConfig: expectedModules:
    let
      imports = homeConfig.imports or [ ];

      hasImport = importPath: builtins.any (imp: imp == importPath) imports;

      # 각 모듈에 대한 테스트 생성
      moduleTests = builtins.map (modulePath: {
        name = "${name}-${
          builtins.replaceStrings [ "/" "." ] [ "-" "-" ] (lib.strings.removePrefix "./" modulePath)
        }";
        value =
          assertTest "${name}-import-${modulePath}" (hasImport modulePath)
            "Module ${modulePath} should be imported";
      }) expectedModules;

      summaryTest = {
        name = "${name}-summary";
        value = pkgs.runCommand "${name}-imports-summary" { } ''
          echo "Module imports '${name}': ${toString (builtins.length moduleTests)} modules validated"
          touch $out
        '';
      };
    in
    builtins.listToAttrs (moduleTests ++ [ summaryTest ]);

  # 프로그램 활성화 테스트
  #
  # Home Manager 프로그램이 활성화되었는지 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - homeConfig: Home Manager 설정
  #   - programName: 프로그램 이름 (예: "git", "vim", "zsh")
  #   - expectedEnabled: 예상되는 활성화 상태
  #
  # Example:
  #   testProgramEnabled "git-enabled" hmConfig "git" true
  testProgramEnabled =
    name: homeConfig: programName: expectedEnabled:
    let
      isEnabled = (homeConfig.programs.${programName}.enable or false);
    in
    assertTest "${name}-${programName}-enabled" (
      isEnabled == expectedEnabled
    ) "Program ${programName} should be ${if expectedEnabled then "enabled" else "disabled"}";

  # ===== 설정 속성 테스트 패턴 =====

  # 속성 존재 및 값 테스트
  #
  # 설정에 특정 속성이 존재하고 예상값을 가지는지 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - config: 설정 객체
  #   - attrPath: 속성 경로 (예: "programs.git.enable")
  #   - expectedValue: 예상되는 값
  #
  # Example:
  #   testConfigAttr "git-enabled" config "programs.git.enable" true
  testConfigAttr =
    name: config: attrPath: expectedValue:
    let
      # 점으로 구분된 경로에서 실제 값 가져오기
      pathParts = builtins.split "\\." attrPath;
      actualValue = builtins.foldl' (
        acc: part:
        if acc == null then
          null
        else if builtins.isString part then
          acc.${part} or null
        else
          acc
      ) config pathParts;

      hasValue = actualValue != null && actualValue == expectedValue;
    in
    assertTest "${name}-${builtins.replaceStrings [ "." ] [ "-" ] attrPath}" (
      hasValue
    ) "Config attribute ${attrPath} should be ${toString expectedValue}";

  # ===== 복합 테스트 패턴 =====

  # 기본 Home Manager 설정 검증
  #
  # Home Manager 설정의 기본 구조를 검증하는 포괄적인 테스트
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - homeConfig: Home Manager 설정
  #   - options: 선택적 옵션
  #     - checkHome: 홈 설정 검증 (기본값: true)
  #     - checkXDG: XDG 설정 검증 (기본값: true)
  #     - checkStateVersion: stateVersion 검증 (기본값: true)
  #     - checkPackages: 패키지 존재 검증 (기본값: true)
  #
  # Example:
  #   testBasicHomeConfig "hm-basic" hmConfig { checkPackages = true; }
  testBasicHomeConfig =
    name: homeConfig: options:
    let
      opts = {
        checkHome = true;
        checkXDG = true;
        checkStateVersion = true;
        checkPackages = true;
      }
      // options;

      tests =
        lib.optional opts.checkHome (
          assertTest "${name}-has-home" (homeConfig ? home) "Should have home attribute"
        )
        ++ lib.optional opts.checkXDG (
          assertTest "${name}-has-xdg" (homeConfig ? xdg) "Should have xdg attribute"
        )
        ++ lib.optional opts.checkStateVersion (
          assertTest "${name}-has-state-version" (
            homeConfig.home.stateVersion != null
          ) "Should have stateVersion set"
        )
        ++ lib.optional opts.checkPackages (
          assertTest "${name}-has-packages" (
            builtins.length (homeConfig.home.packages or [ ]) > 0
          ) "Should have packages installed"
        );
    in
    testSuite "${name}-basic" tests;

  # Git 설정 검증 패턴
  #
  # Git 설정의 기본 구조를 검증
  #
  # Parameters:
  #   - name: 테스트 이름
  #   - gitConfig: Git 설정
  #   - options: 선택적 옵션
  #     - checkEnabled: Git 활성화 검증 (기본값: true)
  #     - checkUser: 사용자 정보 검증 (기본값: true)
  #     - checkAliases: 별칭 검증 (기본값: true)
  #     - checkIgnores: 무시 패턴 검증 (기본값: true)
  #
  # Example:
  #   testBasicGitConfig "git-basic" gitConfig {}
  testBasicGitConfig =
    name: gitConfig: options:
    let
      opts = {
        checkEnabled = true;
        checkUser = true;
        checkAliases = true;
        checkIgnores = true;
      }
      // options;

      gitProgram = gitConfig.programs.git or { };

      tests =
        lib.optional opts.checkEnabled (
          assertTest "${name}-git-enabled" (gitProgram.enable or false) "Git should be enabled"
        )
        ++ lib.optional opts.checkUser (
          assertTest "${name}-git-has-user" (
            (gitProgram.userName or null) != null && (gitProgram.userEmail or null) != null
          ) "Git should have user name and email"
        )
        ++ lib.optional opts.checkAliases (
          assertTest "${name}-git-has-aliases" (
            builtins.length (gitProgram.aliases or [ ]) > 0
          ) "Git should have aliases configured"
        )
        ++ lib.optional opts.checkIgnores (
          assertTest "${name}-git-has-ignores" (
            builtins.length (gitProgram.ignores or [ ]) > 0
          ) "Git should have ignore patterns"
        );
    in
    testSuite "${name}-basic" tests;
}
