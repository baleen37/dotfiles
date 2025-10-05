{ pkgs, lib }:

let
  # Required directory structure
  requiredDirs = [
    "modules"
    "modules/darwin"
    "modules/nixos"
    "modules/shared"
    "hosts"
    "hosts/darwin"
    "hosts/nixos"
    "lib"
    "tests"
    "tests/unit"
    "tests/integration"
    "tests/e2e"
  ];

  # Platform-specific patterns that should NOT appear in other platforms
  darwinExcludedPatterns = "systemd|nixos|boot\\.loader|networking\\.networkmanager";
  nixosExcludedPatterns = "darwin-rebuild|homebrew|system\\.defaults|nix-darwin";
  sharedExcludedPatterns = "darwin-rebuild|systemd|nix-darwin";

  # Individual validation checks as independent derivations
  checkRequiredDirs =
    root:
    pkgs.runCommand "check-required-dirs" { } ''
      ${lib.concatMapStringsSep "\n" (dir: ''
        if [[ ! -d "${root}/${dir}" ]]; then
          echo "❌ Required directory missing: ${dir}"
          exit 1
        fi
      '') requiredDirs}

      echo "✅ Required directories check passed" > $out
    '';

  checkDarwinPlatformSeparation =
    root:
    pkgs.runCommand "check-darwin-platform-separation"
      {
        buildInputs = [ pkgs.gnugrep ];
      }
      ''
        violations=$(${pkgs.gnugrep}/bin/grep -r --include="*.nix" --max-count=1 \
          -E "${darwinExcludedPatterns}" \
          "${root}/modules/darwin" 2>/dev/null || true)

        if [[ -n $violations ]]; then
          echo "❌ Darwin modules contain NixOS-specific code:"
          echo "$violations"
          exit 1
        fi

        echo "✅ Darwin platform separation check passed" > $out
      '';

  checkNixosPlatformSeparation =
    root:
    pkgs.runCommand "check-nixos-platform-separation"
      {
        buildInputs = [ pkgs.gnugrep ];
      }
      ''
        violations=$(${pkgs.gnugrep}/bin/grep -r --include="*.nix" --max-count=1 \
          -E "${nixosExcludedPatterns}" \
          "${root}/modules/nixos" 2>/dev/null || true)

        if [[ -n $violations ]]; then
          echo "❌ NixOS modules contain Darwin-specific code:"
          echo "$violations"
          exit 1
        fi

        echo "✅ NixOS platform separation check passed" > $out
      '';

  checkSharedPlatformAgnostic =
    root:
    pkgs.runCommand "check-shared-platform-agnostic"
      {
        buildInputs = [ pkgs.gnugrep ];
      }
      ''
        violations=$(${pkgs.gnugrep}/bin/grep -r --include="*.nix" --max-count=1 \
          -E "${sharedExcludedPatterns}" \
          "${root}/modules/shared" 2>/dev/null | \
          ${pkgs.gnugrep}/bin/grep -v "config/" | \
          ${pkgs.gnugrep}/bin/grep -v "optionalString" | \
          ${pkgs.gnugrep}/bin/grep -v "^#" | \
          ${pkgs.gnugrep}/bin/grep -v "모두" || true)

        if [[ -n $violations ]]; then
          echo "❌ Shared modules contain unconditional platform-specific code:"
          echo "$violations"
          exit 1
        fi

        echo "✅ Shared modules platform-agnostic check passed" > $out
      '';

  checkNamingConventions =
    root:
    pkgs.runCommand "check-naming-conventions"
      {
        buildInputs = [ pkgs.findutils ];
      }
      ''
        invalid_files=$(${pkgs.findutils}/bin/find "${root}/lib" -type f \
          ! -name "*.nix" ! -name "*.sh" ! -name "*.md" 2>/dev/null || true)

        if [[ -n $invalid_files ]]; then
          echo "❌ lib/ contains invalid file types (only .nix/.sh/.md allowed):"
          echo "$invalid_files"
          exit 1
        fi

        echo "✅ Naming conventions check passed" > $out
      '';

  # Composite validation that runs all checks
  validateAll =
    root:
    pkgs.runCommand "validate-structure"
      {
        requiredDirsCheck = checkRequiredDirs root;
        darwinCheck = checkDarwinPlatformSeparation root;
        nixosCheck = checkNixosPlatformSeparation root;
        sharedCheck = checkSharedPlatformAgnostic root;
        namingCheck = checkNamingConventions root;
      }
      ''
        echo "📁 Running all structure validations..."

        # All checks must pass (they're dependencies)
        cat $requiredDirsCheck
        cat $darwinCheck
        cat $nixosCheck
        cat $sharedCheck
        cat $namingCheck

        echo ""
        echo "✅ All folder structure checks passed!" > $out
      '';

in
{
  inherit
    checkRequiredDirs
    checkDarwinPlatformSeparation
    checkNixosPlatformSeparation
    checkSharedPlatformAgnostic
    checkNamingConventions
    validateAll
    ;
}
