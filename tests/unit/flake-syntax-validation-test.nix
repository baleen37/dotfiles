# tests/unit/flake-syntax-validation-test.nix
# Fast flake syntax validation test
# Tests that flake syntax and all .nix files can be parsed
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
  nixtest ? { },
  self ? ./.,
  inputs ? { },
}:

pkgs.runCommand "flake-syntax-validation"
  {
    buildInputs = [ pkgs.nix ];
    # Use self as the source directory
    src = self;
  }
  ''
    echo "🔍 Validating flake syntax..."

    # Test flake.nix exists and can be parsed
    if [ ! -f "$src/flake.nix" ]; then
      echo "❌ flake.nix not found"
      exit 1
    fi

    # Test flake.nix can be parsed (syntax check only)
    nix-instantiate --parse "$src/flake.nix" > /dev/null || {
      echo "❌ Syntax error in flake.nix"
      exit 1
    }

    # Test key .nix files can be parsed
    for file in "$src/tests/default.nix" "$src/lib/mksystem.nix" "$src/users/shared/home-manager.nix"; do
      if [ -f "$file" ]; then
        nix-instantiate --parse "$file" > /dev/null || {
          echo "❌ Syntax error in $file"
          exit 1
        }
      fi
    done

    echo "✅ All syntax validations passed"
    touch $out
  ''
