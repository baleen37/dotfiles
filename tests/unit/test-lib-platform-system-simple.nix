# Simple Unit Test for lib/platform-system.nix
# Focused on core platform detection and configuration

{ pkgs, lib, ... }:

pkgs.runCommand "lib-platform-system-test"
{
  buildInputs = with pkgs; [ nix jq ];
} ''
  echo "🚀 Testing lib/platform-system.nix"
  echo "==================================="

  # Test 1: Darwin platform detection
  echo "Test 1: Darwin platform detection..."
  platform=$(nix eval --impure --expr '
    let platformSys = import ${../../lib/platform-system.nix} {
      system = "aarch64-darwin";
    };
    in platformSys.platform
  ' | tr -d '"' || echo "error")

  if [ "$platform" = "darwin" ]; then
    echo "✓ Darwin platform detection: PASSED"
  else
    echo "✗ Darwin platform detection: FAILED (got: $platform)"
    exit 1
  fi

  # Test 2: Architecture detection
  echo "Test 2: Architecture detection..."
  arch=$(nix eval --impure --expr '
    let platformSys = import ${../../lib/platform-system.nix} {
      system = "aarch64-darwin";
    };
    in platformSys.arch
  ' | tr -d '"' || echo "error")

  if [ "$arch" = "aarch64" ]; then
    echo "✓ Architecture detection: PASSED"
  else
    echo "✗ Architecture detection: FAILED (got: $arch)"
    exit 1
  fi

  # Test 3: Platform flags
  echo "Test 3: Platform flags..."
  nix eval --impure --json --expr '
    let platformSys = import ${../../lib/platform-system.nix} {
      system = "aarch64-darwin";
    };
    in {
      isDarwin = platformSys.isDarwin;
      isLinux = platformSys.isLinux;
      isAarch64 = platformSys.isAarch64;
      isX86_64 = platformSys.isX86_64;
    }
  ' > platform_flags.json

  isDarwin=$(jq -r '.isDarwin' platform_flags.json)
  isLinux=$(jq -r '.isLinux' platform_flags.json)
  isAarch64=$(jq -r '.isAarch64' platform_flags.json)
  isX86_64=$(jq -r '.isX86_64' platform_flags.json)

  if [ "$isDarwin" = "true" ] && [ "$isLinux" = "false" ] &&
     [ "$isAarch64" = "true" ] && [ "$isX86_64" = "false" ]; then
    echo "✓ Platform flags: PASSED"
  else
    echo "✗ Platform flags: FAILED"
    echo "  isDarwin: $isDarwin (expected: true)"
    echo "  isLinux: $isLinux (expected: false)"
    echo "  isAarch64: $isAarch64 (expected: true)"
    echo "  isX86_64: $isX86_64 (expected: false)"
    exit 1
  fi

  # Test 4: Linux platform detection
  echo "Test 4: Linux platform detection..."
  linuxPlatform=$(nix eval --impure --expr '
    let platformSys = import ${../../lib/platform-system.nix} {
      system = "x86_64-linux";
    };
    in platformSys.platform
  ' | tr -d '"' || echo "error")

  if [ "$linuxPlatform" = "linux" ]; then
    echo "✓ Linux platform detection: PASSED"
  else
    echo "✗ Linux platform detection: FAILED (got: $linuxPlatform)"
    exit 1
  fi

  # Test 5: Supported systems validation
  echo "Test 5: Supported systems validation..."
  supportedCount=$(nix eval --impure --expr '
    let platformSys = import ${../../lib/platform-system.nix} {
      system = "aarch64-darwin";
    };
    in builtins.length platformSys.supportedSystems
  ' || echo "0")

  if [ "$supportedCount" = "4" ]; then
    echo "✓ Supported systems validation: PASSED"
  else
    echo "✗ Supported systems validation: FAILED (got: $supportedCount, expected: 4)"
    exit 1
  fi

  # Test 6: Platform configuration
  echo "Test 6: Platform configuration..."
  nix eval --impure --json --expr '
    let platformSys = import ${../../lib/platform-system.nix} {
      system = "aarch64-darwin";
    };
    in {
      hasHomebrew = platformSys.currentConfig.hasHomebrew;
      packageManager = platformSys.currentConfig.packageManager;
      shellPath = platformSys.currentConfig.shellPath;
    }
  ' > platform_config.json

  hasHomebrew=$(jq -r '.hasHomebrew' platform_config.json)
  packageManager=$(jq -r '.packageManager' platform_config.json)
  shellPath=$(jq -r '.shellPath' platform_config.json)

  if [ "$hasHomebrew" = "true" ] && [ "$packageManager" = "brew" ] &&
     [ "$shellPath" = "/bin/zsh" ]; then
    echo "✓ Platform configuration: PASSED"
  else
    echo "✗ Platform configuration: FAILED"
    echo "  hasHomebrew: $hasHomebrew (expected: true)"
    echo "  packageManager: $packageManager (expected: brew)"
    echo "  shellPath: $shellPath (expected: /bin/zsh)"
    exit 1
  fi

  echo "==================================="
  echo "🎉 All lib/platform-system.nix tests completed!"
  echo "✅ Total: 6 test cases passed"
  echo ""
  echo "Test Coverage:"
  echo "- Darwin platform detection ✅"
  echo "- Architecture detection ✅"
  echo "- Platform boolean flags ✅"
  echo "- Linux platform detection ✅"
  echo "- Supported systems validation ✅"
  echo "- Platform configuration ✅"

  touch $out
''
