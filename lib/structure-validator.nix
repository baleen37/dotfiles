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

  # Validate directory structure
  checkRequiredDirs =
    root:
    pkgs.runCommand "check-required-dirs" { } ''
      echo "Checking required directories..."
      ERRORS=0

      ${lib.concatMapStringsSep "\n" (dir: ''
        if [[ ! -d "${root}/${dir}" ]]; then
          echo "❌ Required directory missing: ${dir}"
          ((ERRORS++))
        fi
      '') requiredDirs}

      if [[ $ERRORS -gt 0 ]]; then
        exit 1
      fi

      touch $out
    '';

  # Validate platform separation
  checkPlatformSeparation =
    root:
    pkgs.runCommand "check-platform-separation" { } ''
      echo "Checking platform separation..."
      ERRORS=0

      # Darwin modules should not reference NixOS-specific patterns
      darwin_violations=$(${pkgs.gnugrep}/bin/grep -r --include="*.nix" \
        -E "${darwinExcludedPatterns}" \
        "${root}/modules/darwin" 2>/dev/null || true)

      if [[ -n $darwin_violations ]]; then
        echo "❌ Darwin modules contain NixOS-specific code:"
        echo "$darwin_violations" | head -5
        ((ERRORS++))
      fi

      # NixOS modules should not reference Darwin-specific patterns
      nixos_violations=$(${pkgs.gnugrep}/bin/grep -r --include="*.nix" \
        -E "${nixosExcludedPatterns}" \
        "${root}/modules/nixos" 2>/dev/null || true)

      if [[ -n $nixos_violations ]]; then
        echo "❌ NixOS modules contain Darwin-specific code:"
        echo "$nixos_violations" | head -5
        ((ERRORS++))
      fi

      # Shared modules should be platform-agnostic
      shared_violations=$(${pkgs.gnugrep}/bin/grep -r --include="*.nix" \
        -E "${sharedExcludedPatterns}" \
        "${root}/modules/shared" 2>/dev/null | \
        ${pkgs.gnugrep}/bin/grep -v "config/" | \
        ${pkgs.gnugrep}/bin/grep -v "optionalString" | \
        ${pkgs.gnugrep}/bin/grep -v "^#" | \
        ${pkgs.gnugrep}/bin/grep -v "모두" || true)

      if [[ -n $shared_violations ]]; then
        echo "❌ Shared modules contain unconditional platform-specific code:"
        echo "$shared_violations" | head -5
        ((ERRORS++))
      fi

      if [[ $ERRORS -gt 0 ]]; then
        exit 1
      fi

      touch $out
    '';

  # Validate naming conventions
  checkNamingConventions =
    root:
    pkgs.runCommand "check-naming-conventions" { } ''
      echo "Checking naming conventions..."
      ERRORS=0

      # lib/ should only contain .nix, .sh, and .md files
      invalid_files=$(${pkgs.findutils}/bin/find "${root}/lib" -type f \
        ! -name "*.nix" ! -name "*.sh" ! -name "*.md" 2>/dev/null || true)

      if [[ -n $invalid_files ]]; then
        echo "❌ lib/ contains invalid file types (only .nix/.sh/.md allowed):"
        echo "$invalid_files"
        ((ERRORS++))
      fi

      if [[ $ERRORS -gt 0 ]]; then
        exit 1
      fi

      touch $out
    '';

  # Run all validations
  validateStructure =
    root:
    pkgs.runCommand "validate-structure"
      {
        buildInputs = [
          pkgs.gnugrep
          pkgs.findutils
        ];
      }
      ''
        echo "📁 Validating project folder structure..." > $out
        ERRORS=0

        # Check required directories
        ${lib.concatMapStringsSep "\n" (dir: ''
          if [[ ! -d "${root}/${dir}" ]]; then
            echo "❌ Required directory missing: ${dir}" >> $out
            ((ERRORS++))
          fi
        '') requiredDirs}

        # Check platform separation - Darwin
        darwin_violations=$(${pkgs.gnugrep}/bin/grep -r --include="*.nix" --max-count=1 \
          -E "${darwinExcludedPatterns}" \
          "${root}/modules/darwin" 2>/dev/null || true)

        if [[ -n $darwin_violations ]]; then
          echo "❌ Darwin modules contain NixOS-specific code:" >> $out
          echo "$darwin_violations" >> $out
          ((ERRORS++))
        fi

        # Check platform separation - NixOS
        nixos_violations=$(${pkgs.gnugrep}/bin/grep -r --include="*.nix" --max-count=1 \
          -E "${nixosExcludedPatterns}" \
          "${root}/modules/nixos" 2>/dev/null || true)

        if [[ -n $nixos_violations ]]; then
          echo "❌ NixOS modules contain Darwin-specific code:" >> $out
          echo "$nixos_violations" >> $out
          ((ERRORS++))
        fi

        # Check platform separation - Shared
        shared_violations=$(${pkgs.gnugrep}/bin/grep -r --include="*.nix" --max-count=1 \
          -E "${sharedExcludedPatterns}" \
          "${root}/modules/shared" 2>/dev/null | \
          ${pkgs.gnugrep}/bin/grep -v "config/" | \
          ${pkgs.gnugrep}/bin/grep -v "optionalString" | \
          ${pkgs.gnugrep}/bin/grep -v "^#" | \
          ${pkgs.gnugrep}/bin/grep -v "모두" || true)

        if [[ -n $shared_violations ]]; then
          echo "❌ Shared modules contain unconditional platform-specific code:" >> $out
          echo "$shared_violations" >> $out
          ((ERRORS++))
        fi

        # Check naming conventions
        invalid_files=$(${pkgs.findutils}/bin/find "${root}/lib" -type f \
          ! -name "*.nix" ! -name "*.sh" ! -name "*.md" 2>/dev/null || true)

        if [[ -n $invalid_files ]]; then
          echo "❌ lib/ contains invalid file types (only .nix/.sh/.md allowed):" >> $out
          echo "$invalid_files" >> $out
          ((ERRORS++))
        fi

        # Report results
        if [[ $ERRORS -gt 0 ]]; then
          echo "" >> $out
          echo "⚠️  Found $ERRORS violation(s)" >> $out
          exit 1
        fi

        echo "✅ All folder structure checks passed!" >> $out
      '';

in
{
  inherit
    checkRequiredDirs
    checkPlatformSeparation
    checkNamingConventions
    validateStructure
    ;
}
