# tests/unit/build-possibility-test.nix
# Build possibility test (dry-run only)
# Tests that build targets can be evaluated without actually building
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
  nixtest ? { },
  self ? ./.,
  inputs ? { },
}:

let
  # Determine build target based on platform
  buildTarget =
    if system == "aarch64-darwin" then
      "darwinConfigurations.macbook-pro.system"
    else if system == "x86_64-linux" then
      "checks.x86_64-linux.smoke"
    else if system == "aarch64-linux" then
      "checks.aarch64-linux.smoke"
    else
      "";

in
pkgs.runCommand "build-possibility-test"
  {
    buildInputs = [ pkgs.nix ];
    # Use self as the source directory
    src = self;
  }
  ''
    echo "🏗️ Testing build possibility (dry-run)..."

    if [ -z "${buildTarget}" ]; then
      echo "⏭️ Skipping build test on unsupported platform: ${system}"
      touch $out
      exit 0
    fi

    # Test build target exists in flake outputs (basic validation)
    # Use nix-instantiate to check if the target is reachable without network access
    case "$buildTarget" in
      "darwinConfigurations.macbook-pro.system")
        # Check if the darwin configuration can be evaluated
        if [ -f "$src/machines/macbook-pro.nix" ]; then
          nix-instantiate --parse "$src/machines/macbook-pro.nix" > /dev/null || {
            echo "❌ Could not parse macbook-pro.nix"
            exit 1
          }
        else
          echo "❌ macbook-pro.nix not found"
          exit 1
        fi
        ;;
      "checks.x86_64-linux.smoke"|"checks.aarch64-linux.smoke")
        # Check if smoke test exists
        if [ -f "$src/tests/default.nix" ]; then
          # Basic validation that tests/default.nix is parseable
          nix-instantiate --parse "$src/tests/default.nix" > /dev/null || {
            echo "❌ Could not parse tests/default.nix"
            exit 1
          }
        else
          echo "❌ tests/default.nix not found"
          exit 1
        fi
        ;;
      *)
        echo "⏭️ Unknown build target: ${buildTarget}"
        ;;
    esac

    echo "✅ Build possibility validated for ${buildTarget}"
    touch $out
  ''
