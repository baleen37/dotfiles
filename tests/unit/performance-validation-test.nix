{ pkgs, lib, ... }:

pkgs.runCommand "performance-validation"
  {
    buildInputs = [
      pkgs.nix
      pkgs.bash
    ];
    src = ../.;
  }
  ''
    echo "🚀 Validating performance targets..."

    # Run make test with timeout
    timeout 60s make test || {
      echo "❌ Tests exceeded 60 second timeout"
      exit 1
    }

    echo "✅ Performance validation passed"
    touch $out
  ''
