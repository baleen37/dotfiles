# tests/integration/claude-home-symlink-test.nix
# Integration test for Claude Code home-manager configuration
# Validates source structure (CI-safe)
{
  pkgs,
  lib,
  self,
  ...
}:

pkgs.runCommand "claude-home-symlink-test"
  {
    buildInputs = [ pkgs.coreutils ];
    src = self;
  }
  ''
    # Source validation (CI-safe)
    CLAUDE_SOURCE="$src/users/shared/.config/claude"

    echo "Checking home-manager structure..."

    # Test 1: Basic structure
    if [ ! -d "$CLAUDE_SOURCE" ]; then
      echo "❌ FAIL: Source directory missing"
      exit 1
    fi
    echo "✅ PASS: Source directory exists"

    # Test 2: Configuration files
    for file in settings.json CLAUDE.md .gitignore; do
      if [ ! -f "$CLAUDE_SOURCE/$file" ]; then
        echo "❌ FAIL: Missing: $file"
        exit 1
      fi
      echo "✅ PASS: Found: $file"
    done

    echo "✅ All tests passed" > $out
  ''
