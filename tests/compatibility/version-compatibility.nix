# ABOUTME: Nix 버전 및 플랫폼 호환성을 검증하는 테스트
# ABOUTME: 다양한 환경에서의 설정 호환성을 보장함

{ pkgs, src ? ../.. }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

  # Minimum required versions
  minVersions = {
    nix = "2.18";
    nixpkgs = "23.11";
  };

  # Platform compatibility matrix
  supportedPlatforms = [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];

in
pkgs.runCommand "version-compatibility-test"
{
  buildInputs = [ pkgs.nix ];
} ''
  ${testHelpers.setupTestEnv}
  ${testHelpers.testSection "Version Compatibility 검증"}

  cd ${src}

  ${testHelpers.testSubsection "Nix 버전 호환성"}

  # Check current Nix version
  NIX_VERSION=$(nix --version | grep -o '[0-9]\+\.[0-9]\+' | head -1)
  echo "현재 Nix 버전: $NIX_VERSION"
  echo "최소 요구 버전: ${minVersions.nix}"

  # Simple version comparison (assuming semantic versioning)
  if [ "$(printf '%s\n' "${minVersions.nix}" "$NIX_VERSION" | sort -V | head -n1)" = "${minVersions.nix}" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Nix 버전 호환성 확인"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Nix 버전이 너무 낮음"
    exit 1
  fi

  ${testHelpers.testSubsection "Flake 호환성"}

  # Check if flake is compatible with current Nix version
  echo "Flake 호환성 확인 중..."

  if nix flake check --no-build . >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Flake 호환성 확인"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Flake 호환성 문제"
    exit 1
  fi

  ${testHelpers.testSubsection "플랫폼 지원 확인"}

  # Check supported platforms in flake
  FLAKE_INFO=$(nix flake show --json --no-build . 2>/dev/null)

  for platform in ${builtins.concatStringsSep " " supportedPlatforms}; do
    if echo "$FLAKE_INFO" | grep -q "$platform"; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} $platform 지원됨"
    else
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} $platform 지원되지 않음"
    fi
  done

  ${testHelpers.testSubsection "실험적 기능 확인"}

  # Check if required experimental features are available
  REQUIRED_FEATURES="nix-command flakes"

  for feature in $REQUIRED_FEATURES; do
    if nix show-config | grep "experimental-features" | grep -q "$feature"; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} 실험적 기능 '$feature' 활성화됨"
    else
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} 실험적 기능 '$feature' 비활성화됨"
    fi
  done

  ${testHelpers.testSubsection "종속성 호환성"}

  # Check if critical dependencies are available
  CRITICAL_DEPS="git curl"

  for dep in $CRITICAL_DEPS; do
    if command -v "$dep" >/dev/null 2>&1; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} '$dep' 사용 가능"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} '$dep' 누락"
      exit 1
    fi
  done

  ${testHelpers.reportResults "Version Compatibility" 1 1}
  touch $out
''
