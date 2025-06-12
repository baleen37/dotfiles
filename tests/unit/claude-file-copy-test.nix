{ pkgs, flake ? null, src ? ../.. }:

let

  # Mock activation script result
  mockActivationResult = pkgs.runCommand "mock-claude-files" { } ''
    mkdir -p $out/.claude/commands

    # Create actual files (not symlinks)
    echo "# CLAUDE.md content" > $out/.claude/CLAUDE.md
    echo '{"version": "1.0"}' > $out/.claude/settings.json
    echo "# explore command" > $out/.claude/commands/explore.md
    echo "# tdd command" > $out/.claude/commands/tdd.md
    echo "# fix-github-issue command" > $out/.claude/commands/fix-github-issue.md
  '';

in
pkgs.runCommand "claude-file-copy-test" { } ''
  echo "=== Claude File Copy Test ==="

  # Test that CLAUDE.md is a regular file (not symlink)
  if [[ -f "${mockActivationResult}/.claude/CLAUDE.md" && ! -L "${mockActivationResult}/.claude/CLAUDE.md" ]]; then
    echo "✓ CLAUDE.md is a regular file (not symlink)"
  else
    echo "✗ CLAUDE.md should be a regular file, not symlink"
    exit 1
  fi

  # Test that settings.json is a regular file (not symlink)
  if [[ -f "${mockActivationResult}/.claude/settings.json" && ! -L "${mockActivationResult}/.claude/settings.json" ]]; then
    echo "✓ settings.json is a regular file (not symlink)"
  else
    echo "✗ settings.json should be a regular file, not symlink"
    exit 1
  fi

  # Test that command files are regular files (not symlinks)
  command_files_count=0
  for file in "${mockActivationResult}/.claude/commands"/*.md; do
    if [[ -f "$file" && ! -L "$file" ]]; then
      command_files_count=$((command_files_count + 1))
      echo "✓ $(basename "$file") is a regular file"
    else
      echo "✗ $(basename "$file") should be a regular file, not symlink"
      exit 1
    fi
  done

  # Test that we have expected number of command files
  if [[ $command_files_count -eq 3 ]]; then
    echo "✓ Found $command_files_count command files as expected"
  else
    echo "✗ Expected 3 command files, found $command_files_count"
    exit 1
  fi

  # Test that files are readable and writable
  if [[ -r "${mockActivationResult}/.claude/CLAUDE.md" && -w "${mockActivationResult}/.claude/CLAUDE.md" ]]; then
    echo "✓ CLAUDE.md has correct permissions (readable and writable)"
  else
    echo "✗ CLAUDE.md should be readable and writable"
    exit 1
  fi

  echo "All tests passed!"
  touch $out
''
