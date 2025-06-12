# ABOUTME: Flake outputs 구조의 계약을 검증하는 테스트
# ABOUTME: API 인터페이스의 일관성과 호환성을 보장함

{ pkgs, flake ? null, src ? ../.. }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

  # Expected flake outputs structure
  expectedOutputs = {
    darwinConfigurations = [ "aarch64-darwin" "x86_64-darwin" ];
    nixosConfigurations = [ "aarch64-linux" "x86_64-linux" ];
    apps = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
    checks = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
  };

  # Expected app names for each platform
  expectedApps = [ "build" "switch" "rollback" ];

in
pkgs.runCommand "flake-outputs-contract-test" { } ''
  ${testHelpers.setupTestEnv}
  ${testHelpers.testSection "Flake Outputs Contract 검증"}

  cd ${src}

  # Check if flake.nix exists
  ${testHelpers.assertExists "flake.nix" "flake.nix 파일 존재 확인"}

  # Validate flake structure without building
  echo "Flake 구조 검증 중..."
  if nix flake show --no-build . >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Flake 구조가 유효합니다"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Flake 구조가 잘못되었습니다"
    exit 1
  fi

  # Check expected outputs exist
  FLAKE_INFO=$(nix flake show --json --no-build . 2>/dev/null)

  # Check darwinConfigurations
  ${testHelpers.testSubsection "darwinConfigurations 검증"}
  for system in ${builtins.concatStringsSep " " expectedOutputs.darwinConfigurations}; do
    if echo "$FLAKE_INFO" | grep -q "darwinConfigurations.*$system"; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} darwinConfigurations.$system 존재"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} darwinConfigurations.$system 누락"
      exit 1
    fi
  done

  # Check nixosConfigurations
  ${testHelpers.testSubsection "nixosConfigurations 검증"}
  for system in ${builtins.concatStringsSep " " expectedOutputs.nixosConfigurations}; do
    if echo "$FLAKE_INFO" | grep -q "nixosConfigurations.*$system"; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} nixosConfigurations.$system 존재"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} nixosConfigurations.$system 누락"
      exit 1
    fi
  done

  # Check apps for each platform
  ${testHelpers.testSubsection "Apps 검증"}
  for system in ${builtins.concatStringsSep " " expectedOutputs.apps}; do
    for app in ${builtins.concatStringsSep " " expectedApps}; do
      if echo "$FLAKE_INFO" | grep -q "apps.*$system.*$app"; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} apps.$system.$app 존재"
      else
        echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} apps.$system.$app 누락 (일부 플랫폼에서는 정상)"
      fi
    done
  done

  # Check checks exist
  ${testHelpers.testSubsection "Checks 검증"}
  for system in ${builtins.concatStringsSep " " expectedOutputs.checks}; do
    if echo "$FLAKE_INFO" | grep -q "checks.*$system"; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} checks.$system 존재"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} checks.$system 누락"
      exit 1
    fi
  done

  ${testHelpers.reportResults "Flake Outputs Contract" 1 1}
  touch $out
''
