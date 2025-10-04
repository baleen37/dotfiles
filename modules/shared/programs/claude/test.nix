# Claude Code Module Unit Tests
#
# Claude Code 모듈의 단위 테스트 - 심볼릭 링크 생성 및 모듈 평가 검증
#
# 테스트 항목:
#   - 모듈 평가 (test-module-eval): 모듈이 올바른 구조를 가지는지 확인
#   - Darwin 심볼릭 링크 (test-darwin-links): macOS에서 모든 설정 파일 링크 생성 검증
#   - Linux 심볼릭 링크 (test-linux-links): Linux에서 모든 설정 파일 링크 생성 검증
#   - 설정 경로 (test-config-path): 설정 디렉토리 경로가 올바른지 확인
#   - 패키지 추가 없음 (test-no-packages): 모듈이 불필요한 패키지를 추가하지 않는지 확인
#
# VERSION: 1.0.0
# LAST UPDATED: 2024-10-04

{ pkgs ? import <nixpkgs> { }
, lib ? pkgs.lib
,
}:

let
  # Test module with mock inputs
  testModule = import ./default.nix {
    inherit lib;
    config = { };
    pkgs = pkgs;
    platformInfo = {
      isDarwin = true;
      isLinux = false;
    };
    userInfo = {
      paths = {
        home = "/tmp/test-home";
      };
      name = "testuser";
    };
  };

  # Expected symlinks for macOS
  expectedDarwinLinks = [
    ".claude/settings.json"
    ".claude/CLAUDE.md"
    ".claude/hooks"
    ".claude/commands"
    ".claude/agents"
  ];

  # Test Linux configuration
  testModuleLinux = import ./default.nix {
    inherit lib;
    config = { };
    pkgs = pkgs;
    platformInfo = {
      isDarwin = false;
      isLinux = true;
    };
    userInfo = {
      paths = {
        home = "/tmp/test-home";
      };
      name = "testuser";
    };
  };

  # Expected symlinks for Linux (same as Darwin - Claude uses ~/.claude)
  expectedLinuxLinks = [
    ".claude/settings.json"
    ".claude/CLAUDE.md"
    ".claude/hooks"
    ".claude/commands"
    ".claude/agents"
  ];

in
rec {
  # Test 1: Module evaluation
  test-module-eval = pkgs.runCommand "test-claude-module-eval" { } ''
    echo "Testing: Claude module evaluates without error"

    # Test that module has expected structure
    ${pkgs.nix}/bin/nix eval --json --impure --expr "
      let
        module = import ${./default.nix} {
          lib = (import <nixpkgs> {}).lib;
          config = {};
          pkgs = import <nixpkgs> {};
          platformInfo = { isDarwin = true; isLinux = false; };
          userInfo = { paths = { home = \"/tmp\"; }; name = \"test\"; };
        };
      in
        (module ? home) && (module.home ? file)
    " | grep -q "true"

    if [[ $? -eq 0 ]]; then
      echo "PASS: Module structure is correct"
      touch $out
    else
      echo "FAIL: Module structure is incorrect"
      exit 1
    fi
  '';

  # Test 2: Darwin symlinks
  test-darwin-links = pkgs.runCommand "test-claude-darwin-links" { } ''
    echo "Testing: Darwin platform creates correct symlinks"

    # Check that all expected Darwin paths exist in home.file
    ${pkgs.nix}/bin/nix eval --json --impure --expr "
      let
        module = import ${./default.nix} {
          lib = (import <nixpkgs> {}).lib;
          config = {};
          pkgs = import <nixpkgs> {};
          platformInfo = { isDarwin = true; isLinux = false; };
          userInfo = { paths = { home = \"/tmp\"; }; name = \"test\"; };
        };
      in
        builtins.attrNames module.home.file
    " > result.json

    # Check each expected path
    MISSING=""
    for path in ${lib.escapeShellArgs expectedDarwinLinks}; do
      if ! ${pkgs.jq}/bin/jq -e "map(select(. == \"$path\")) | length > 0" result.json >/dev/null; then
        MISSING="$MISSING $path"
      fi
    done

    if [[ -z "$MISSING" ]]; then
      echo "PASS: All Darwin symlinks configured"
      touch $out
    else
      echo "FAIL: Missing symlinks:$MISSING"
      exit 1
    fi
  '';

  # Test 3: Linux symlinks
  test-linux-links = pkgs.runCommand "test-claude-linux-links" { } ''
    echo "Testing: Linux platform creates correct symlinks"

    # Check that all expected Linux paths exist in home.file
    ${pkgs.nix}/bin/nix eval --json --impure --expr "
      let
        module = import ${./default.nix} {
          lib = (import <nixpkgs> {}).lib;
          config = {};
          pkgs = import <nixpkgs> {};
          platformInfo = { isDarwin = false; isLinux = true; };
          userInfo = { paths = { home = \"/tmp\"; }; name = \"test\"; };
        };
      in
        builtins.attrNames module.home.file
    " > result.json

    # Check each expected path
    MISSING=""
    for path in ${lib.escapeShellArgs expectedLinuxLinks}; do
      if ! ${pkgs.jq}/bin/jq -e "map(select(. == \"$path\")) | length > 0" result.json >/dev/null; then
        MISSING="$MISSING $path"
      fi
    done

    if [[ -z "$MISSING" ]]; then
      echo "PASS: All Linux symlinks configured"
      touch $out
    else
      echo "FAIL: Missing symlinks:$MISSING"
      exit 1
    fi
  '';

  # Test 4: Config directory path
  test-config-path = pkgs.runCommand "test-claude-config-path" { } ''
    echo "Testing: Config directory path is correct"

    # Verify the config path contains expected directory
    ${pkgs.nix}/bin/nix eval --impure --expr "
      let
        module = import ${./default.nix} {
          lib = (import <nixpkgs> {}).lib;
          config = {};
          pkgs = import <nixpkgs> {};
          platformInfo = { isDarwin = true; isLinux = false; };
          userInfo = { paths = { home = \"/Users/test\"; }; name = \"test\"; };
        };
        settingsPath = module.home.file.\".claude/settings.json\".source;
      in
        builtins.match \".*/modules/shared/config/claude/settings.json\" settingsPath != null
    " | grep -q "true"

    if [[ $? -eq 0 ]]; then
      echo "PASS: Config path points to correct location"
      touch $out
    else
      echo "FAIL: Config path is incorrect"
      exit 1
    fi
  '';

  # Test 5: No packages added
  test-no-packages = pkgs.runCommand "test-claude-no-packages" { } ''
    echo "Testing: No packages are added by module"

    ${pkgs.nix}/bin/nix eval --json --impure --expr "
      let
        module = import ${./default.nix} {
          lib = (import <nixpkgs> {}).lib;
          config = {};
          pkgs = import <nixpkgs> {};
          platformInfo = { isDarwin = true; isLinux = false; };
          userInfo = { paths = { home = \"/tmp\"; }; name = \"test\"; };
        };
      in
        builtins.length module.home.packages
    " | grep -q "0"

    if [[ $? -eq 0 ]]; then
      echo "PASS: No packages added"
      touch $out
    else
      echo "FAIL: Unexpected packages found"
      exit 1
    fi
  '';

  # Run all tests
  all-tests =
    pkgs.runCommand "test-claude-all"
      {
        buildInputs = [
          test-module-eval
          test-darwin-links
          test-linux-links
          test-config-path
          test-no-packages
        ];
      }
      ''
        echo "✅ All Claude module unit tests passed!"
        touch $out
      '';
}
