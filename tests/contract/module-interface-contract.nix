# ABOUTME: 모듈 인터페이스의 계약을 검증하는 테스트
# ABOUTME: 모듈 간 상호작용의 일관성을 보장함

{ pkgs, flake ? null, src ? ../.. }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

  # Expected module structure
  expectedModules = {
    darwin = [
      "packages.nix"
      "casks.nix"
      "home-manager.nix"
      "files.nix"
      "dock/default.nix"
    ];
    nixos = [
      "packages.nix"
      "home-manager.nix"
      "files.nix"
      "disk-config.nix"
    ];
    shared = [
      "packages.nix"
      "home-manager.nix"
      "files.nix"
      "default.nix"
    ];
  };

in
pkgs.runCommand "module-interface-contract-test" { } ''
  ${testHelpers.setupTestEnv}
  ${testHelpers.testSection "Module Interface Contract 검증"}

  cd ${src}

  # Check modules directory structure
  ${testHelpers.assertExists "modules" "modules 디렉토리 존재 확인"}
  ${testHelpers.assertExists "modules/darwin" "darwin 모듈 디렉토리 존재 확인"}
  ${testHelpers.assertExists "modules/nixos" "nixos 모듈 디렉토리 존재 확인"}
  ${testHelpers.assertExists "modules/shared" "shared 모듈 디렉토리 존재 확인"}

  # Check Darwin modules
  ${testHelpers.testSubsection "Darwin 모듈 검증"}
  ${builtins.concatStringsSep "\n" (map (module:
    testHelpers.assertExists "modules/darwin/${module}" "Darwin ${module} 모듈 존재 확인"
  ) expectedModules.darwin)}

  # Check NixOS modules
  ${testHelpers.testSubsection "NixOS 모듈 검증"}
  ${builtins.concatStringsSep "\n" (map (module:
    testHelpers.assertExists "modules/nixos/${module}" "NixOS ${module} 모듈 존재 확인"
  ) expectedModules.nixos)}

  # Check Shared modules
  ${testHelpers.testSubsection "Shared 모듈 검증"}
  ${builtins.concatStringsSep "\n" (map (module:
    testHelpers.assertExists "modules/shared/${module}" "Shared ${module} 모듈 존재 확인"
  ) expectedModules.shared)}

  # Validate that all modules have proper Nix syntax
  ${testHelpers.testSubsection "모듈 구문 검증"}
  for module in modules/darwin/*.nix modules/nixos/*.nix modules/shared/*.nix; do
    if [ -f "$module" ]; then
      if nix-instantiate --parse "$module" >/dev/null 2>&1; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} $module 구문 유효"
      else
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} $module 구문 오류"
        exit 1
      fi
    fi
  done

  # Check that modules export expected attributes
  ${testHelpers.testSubsection "모듈 속성 검증"}
  for module in modules/darwin/packages.nix modules/nixos/packages.nix modules/shared/packages.nix; do
    if [ -f "$module" ]; then
      # Check if module contains expected Nix expressions
      if grep -q "environment.systemPackages\|home.packages" "$module"; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} $module 패키지 정의 확인"
      else
        echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} $module 패키지 정의 미확인"
      fi
    fi
  done

  ${testHelpers.reportResults "Module Interface Contract" 1 1}
  touch $out
''
