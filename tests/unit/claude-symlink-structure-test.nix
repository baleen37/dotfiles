# tests/unit/claude-symlink-structure-test.nix
# Unit test for Claude Code source structure validation
# Validates file and directory existence without runtime checks
{
  pkgs,
  lib,
  self,
  ...
}:

pkgs.runCommand "claude-symlink-test"
  {
    buildInputs = [ pkgs.coreutils ];
    src = self;
  }
  ''
    # Source directory validation (CI-safe)
    CLAUDE_SOURCE="$src/users/shared/.config/claude"

    echo "Checking Claude source structure..."

    # Test 1: Directory exists
    if [ ! -d "$CLAUDE_SOURCE" ]; then
      echo "❌ FAIL: Source directory missing: $CLAUDE_SOURCE"
      exit 1
    fi
    echo "✅ PASS: Source directory exists"

    # Test 2: Required files exist
    for file in CLAUDE.md settings.json; do
      if [ ! -f "$CLAUDE_SOURCE/$file" ]; then
        echo "❌ FAIL: Missing file: $file"
        exit 1
      fi
      echo "✅ PASS: Found file: $file"
    done

    # Test 3: Required directories exist
    for dir in agents commands hooks; do
      if [ ! -d "$CLAUDE_SOURCE/$dir" ]; then
        echo "❌ FAIL: Missing directory: $dir/"
        exit 1
      fi
      echo "✅ PASS: Found directory: $dir/"
    done

    echo "✅ All unit tests passed" > $out
  ''
