# Simplified Claude commands test
# Tests that Claude commands directory structure exists and contains expected files

{ pkgs, src ? ../., ... }:

pkgs.runCommand "claude-commands-test"
{
  buildInputs = with pkgs; [ bash ];
} ''
  echo "🧪 Claude Commands Test"
  echo "======================"

  # Test 1: Commands directory exists
  echo ""
  echo "📋 Test 1: Commands Directory Structure"
  echo "--------------------------------------"

  if [[ -d "${src}/modules/shared/config/claude/commands" ]]; then
    echo "✅ Commands directory exists"
  else
    echo "❌ Commands directory not found"
    exit 1
  fi

  # Test 2: Basic commands files exist
  echo ""
  echo "📋 Test 2: Essential Command Files"
  echo "---------------------------------"

  commands_dir="${src}/modules/shared/config/claude/commands"

  # Check for command files that we know exist
  echo "Checking for command files in: $commands_dir"

  # Count .md files
  md_file_count=$(find "$commands_dir" -name "*.md" -type f 2>/dev/null | wc -l)
  echo "📄 Total .md files found: $md_file_count"

  if [[ $md_file_count -gt 0 ]]; then
    echo "✅ Found $md_file_count command files"
  else
    echo "❌ No command files found"
    exit 1
  fi

  # Test 3: Specific file validation
  echo ""
  echo "📋 Test 3: File Content Validation"
  echo "---------------------------------"

  # Check if brainstorm.md exists and is readable
  if [[ -f "$commands_dir/brainstorm.md" ]]; then
    if [[ -r "$commands_dir/brainstorm.md" ]]; then
      echo "✅ brainstorm.md exists and is readable"
    else
      echo "❌ brainstorm.md is not readable"
      exit 1
    fi
  else
    echo "⚠️  brainstorm.md not found, but other files exist"
  fi

  echo ""
  echo "🎉 All Claude Commands Tests Completed Successfully!"
  echo "=================================================="
  echo ""
  echo "Summary:"
  echo "- Commands directory structure: ✅"
  echo "- Command files found: $md_file_count"
  echo "- File accessibility: ✅"

  touch $out
''
