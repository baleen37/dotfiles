# Claude Code Module Unit Tests
#
# Claude Code 모듈의 단위 테스트 - 심볼릭 링크 생성 및 모듈 평가 검증
#
# 테스트 항목:
#   - 모듈 평가 (test-module-eval): 모듈이 올바른 구조를 가지는지 확인
#   - Darwin 심볼릭 링크 (test-darwin-links): macOS에서 모든 설정 파일 링크 생성 검증
#   - Linux 심볼릭 링크 (test-linux-links): Linux에서 모든 설정 파일 링크 생성 검증
#   - 패키지 추가 없음 (test-no-packages): 모듈이 불필요한 패키지를 추가하지 않는지 확인
#   - 심볼릭 링크 무결성 (test-symlink-integrity): commands/agents가 symlink로 설정되었는지 확인
#
# VERSION: 2.0.0
# LAST UPDATED: 2025-10-05

{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
}:

let
  # Path to claude module (relative to this test file)
  claudeModule = ../../../modules/shared/programs/claude/default.nix;

  # Files managed via home.file (all through direct symlinks to dotfiles)
  expectedHomeFiles = [
    ".claude/settings.json"
    ".claude/CLAUDE.md"
    ".claude/commands"
    ".claude/agents"
    ".claude/hooks"
  ];

in
rec {
  # Test 1: Module evaluation
  test-module-eval = pkgs.runCommand "test-claude-module-eval" { } ''
    echo "Testing: Claude module evaluates without error"

    # Test that module has expected structure
    ${pkgs.nix}/bin/nix eval --json --impure --expr "
      let
        module = import ${claudeModule} {
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
        module = import ${claudeModule} {
          lib = (import <nixpkgs> {}).lib;
          config = {};
          pkgs = import <nixpkgs> {};
          platformInfo = { isDarwin = true; isLinux = false; };
          userInfo = { paths = { home = \"/tmp\"; }; name = \"test\"; };
        };
      in
        builtins.attrNames module.home.file
    " > result.json

    # Check each expected path (home.file managed files only)
    MISSING=""
    for path in ${lib.escapeShellArgs expectedHomeFiles}; do
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
        module = import ${claudeModule} {
          lib = (import <nixpkgs> {}).lib;
          config = {};
          pkgs = import <nixpkgs> {};
          platformInfo = { isDarwin = false; isLinux = true; };
          userInfo = { paths = { home = \"/tmp\"; }; name = \"test\"; };
        };
      in
        builtins.attrNames module.home.file
    " > result.json

    # Check each expected path (home.file managed files only)
    MISSING=""
    for path in ${lib.escapeShellArgs expectedHomeFiles}; do
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

  # Test 4: Claude hooks package is added
  test-packages = pkgs.runCommand "test-claude-packages" { } ''
    echo "Testing: claude-hooks package is added by module"

    ${pkgs.nix}/bin/nix eval --json --impure --expr "
      let
        module = import ${claudeModule} {
          lib = (import <nixpkgs> {}).lib;
          config = {};
          pkgs = import <nixpkgs> {};
          platformInfo = { isDarwin = true; isLinux = false; };
          userInfo = { paths = { home = \"/tmp\"; }; name = \"test\"; };
        };
      in
        builtins.length module.home.packages
    " | grep -q "1"

    if [[ $? -eq 0 ]]; then
      echo "PASS: claude-hooks package added"
      touch $out
    else
      echo "FAIL: Expected 1 package (claude-hooks), found different number"
      exit 1
    fi
  '';

  # Test 5: CLAUDE.md points to source directory (not Nix store)
  test-claude-md-source-link = pkgs.runCommand "test-claude-md-source-link" { } ''
    echo "Testing: CLAUDE.md symlink points to source directory, not Nix store"

    ${pkgs.nix}/bin/nix eval --json --impure --expr "
      let
        module = import ${claudeModule} {
          lib = (import <nixpkgs> {}).lib;
          config = {};
          pkgs = import <nixpkgs> {};
          platformInfo = { isDarwin = true; isLinux = false; };
          userInfo = { paths = { home = \"/tmp\"; }; name = \"test\"; };
        };
        source = module.home.file.\".claude/CLAUDE.md\".source;
      in
        # Source should be a string path (direct symlink), not a derivation
        builtins.isString source
    " | grep -q "true"

    if [[ $? -eq 0 ]]; then
      echo "PASS: CLAUDE.md is configured as direct symlink to source"
      touch $out
    else
      echo "FAIL: CLAUDE.md should be a direct string path, not a Nix store derivation"
      exit 1
    fi
  '';

  # Test 6: Symlink configuration for directories
  test-symlink-integrity = pkgs.runCommand "test-claude-symlink-integrity" { } ''
    echo "Testing: Symlink configuration for directories"

    ${pkgs.nix}/bin/nix eval --json --impure --expr "
      let
        module = import ${claudeModule} {
          lib = (import <nixpkgs> {}).lib;
          config = {};
          pkgs = import <nixpkgs> {};
          platformInfo = { isDarwin = true; isLinux = false; };
          userInfo = { paths = { home = \"/tmp\"; }; name = \"test\"; };
        };
      in
        {
          commands_recursive = module.home.file.\".claude/commands\".recursive or false;
          agents_recursive = module.home.file.\".claude/agents\".recursive or false;
          hooks_recursive = module.home.file.\".claude/hooks\".recursive or false;
        }
    " > result.json

    # commands and agents should NOT have recursive (direct directory symlink)
    if ${pkgs.jq}/bin/jq -e '.commands_recursive == false' result.json >/dev/null; then
      echo "PASS: commands is configured as direct directory symlink (no recursive)"
    else
      echo "FAIL: commands should not have recursive for direct directory symlink"
      exit 1
    fi

    if ${pkgs.jq}/bin/jq -e '.agents_recursive == false' result.json >/dev/null; then
      echo "PASS: agents is configured as direct directory symlink (no recursive)"
    else
      echo "FAIL: agents should not have recursive for direct directory symlink"
      exit 1
    fi

    # hooks should have recursive=true (managed files within directory)
    if ${pkgs.jq}/bin/jq -e '.hooks_recursive == true' result.json >/dev/null; then
      echo "PASS: hooks is configured with recursive=true (managed files)"
    else
      echo "FAIL: hooks should have recursive=true for managed files"
      exit 1
    fi

    touch $out
  '';

  # Run all tests
  all-tests =
    pkgs.runCommand "test-claude-all"
      {
        buildInputs = [
          test-module-eval
          test-darwin-links
          test-linux-links
          test-packages
          test-claude-md-source-link
          test-symlink-integrity
        ];
      }
      ''
        echo "✅ All Claude module unit tests passed!"
        touch $out
      '';
}
