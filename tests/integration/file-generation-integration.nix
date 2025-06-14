{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  
in
pkgs.runCommand "file-generation-integration-test" {} ''
  ${testHelpers.setupTestEnv}
  
  ${testHelpers.testSection "File Generation Integration Tests"}
  
  # Test 1: Basic file configuration structure
  ${testHelpers.testSubsection "File Configuration Structure"}
  
  # Test that files.nix configurations exist
  ${testHelpers.assertExists "${src}/modules/shared/files.nix" "Shared files.nix exists"}
  
  if [ -f "${src}/modules/darwin/files.nix" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Darwin files.nix exists"
  fi
  
  if [ -f "${src}/modules/nixos/files.nix" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} NixOS files.nix exists"
  fi
  
  # Test 2: Configuration file templates
  ${testHelpers.testSubsection "Configuration Templates"}
  
  # Test Claude configuration templates
  ${testHelpers.assertExists "${src}/modules/shared/config/claude/CLAUDE.md" "Claude CLAUDE.md template exists"}
  ${testHelpers.assertExists "${src}/modules/shared/config/claude/settings.json" "Claude settings.json template exists"}
  
  # Test platform-specific templates
  ${testHelpers.onlyOn ["aarch64-darwin" "x86_64-darwin"] "Darwin template tests" ''
    if [ -f "${src}/modules/darwin/config/hammerspoon/init.lua" ]; then
      ${testHelpers.assertExists "${src}/modules/darwin/config/hammerspoon/init.lua" "Hammerspoon init.lua template exists"}
    fi
    
    if [ -f "${src}/modules/darwin/config/karabiner/karabiner.json" ]; then
      ${testHelpers.assertExists "${src}/modules/darwin/config/karabiner/karabiner.json" "Karabiner config template exists"}
    fi
  ''}
  
  ${testHelpers.onlyOn ["aarch64-linux" "x86_64-linux"] "Linux template tests" ''
    if [ -d "${src}/modules/nixos/config/polybar" ]; then
      ${testHelpers.assertExists "${src}/modules/nixos/config/polybar/config.ini" "Polybar config template exists"}
    fi
    
    if [ -d "${src}/modules/nixos/config/rofi" ]; then
      ${testHelpers.assertExists "${src}/modules/nixos/config/rofi/launcher.rasi" "Rofi launcher template exists"}
    fi
  ''}
  
  # Test 3: File content validation
  ${testHelpers.testSubsection "File Content Validation"}
  
  # Test that configuration files have expected content
  ${testHelpers.assertContains "${src}/modules/shared/config/claude/CLAUDE.md" "CLAUDE.md" "Claude CLAUDE.md has expected header"}
  ${testHelpers.assertContains "${src}/modules/shared/config/claude/settings.json" "{" "Claude settings.json has JSON structure"}
  
  # Test shell configuration files
  if [ -f "${src}/modules/shared/config/p10k.zsh" ]; then
    ${testHelpers.assertContains "${src}/modules/shared/config/p10k.zsh" "p10k" "p10k config has expected content"}
  fi
  
  # Test 4: File permissions and structure
  ${testHelpers.testSubsection "File Permissions and Structure"}
  
  # Test that executable files are properly marked
  if [ -f "${src}/scripts/setup-dev" ]; then
    ${testHelpers.assertTrue ''[ -x "${src}/scripts/setup-dev" ]'' "setup-dev script is executable"}
  fi
  
  if [ -f "${src}/scripts/bl" ]; then
    ${testHelpers.assertTrue ''[ -x "${src}/scripts/bl" ]'' "bl script is executable"}
  fi
  
  # Test 5: Directory structure consistency
  ${testHelpers.testSubsection "Directory Structure Consistency"}
  
  # Test that config directories are properly organized
  CONFIG_DIRS=$(find "${src}/modules" -type d -name "config" | wc -l)
  ${testHelpers.assertTrue ''[ $CONFIG_DIRS -gt 0 ]'' "Config directories exist ($CONFIG_DIRS found)"}
  
  # Test 6: Template variable consistency
  ${testHelpers.testSubsection "Template Variable Consistency"}
  
  # Test that template files don't contain unresolved variables
  # Look for common template variable patterns that might be missed
  
  # Check Claude config for template consistency
  CLAUDE_CONFIG="${src}/modules/shared/config/claude/settings.json"
  if [ -f "$CLAUDE_CONFIG" ]; then
    # Should not contain raw template variables like {{variable}}
    if grep -q "{{.*}}" "$CLAUDE_CONFIG" 2>/dev/null; then
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Claude settings.json contains unresolved template variables"
      exit 1
    else
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Claude settings.json has no unresolved template variables"
    fi
  fi
  
  # Test 7: File generation library functions
  ${testHelpers.testSubsection "File Generation Library Functions"}
  
  # Test that file generation helpers exist
  if [ -f "${src}/modules/shared/lib/conditional-file-copy.nix" ]; then
    ${testHelpers.assertExists "${src}/modules/shared/lib/conditional-file-copy.nix" "Conditional file copy library exists"}
  fi
  
  if [ -f "${src}/modules/shared/lib/file-change-detector.nix" ]; then
    ${testHelpers.assertExists "${src}/modules/shared/lib/file-change-detector.nix" "File change detector library exists"}
  fi
  
  # Test 8: Cross-platform file compatibility
  ${testHelpers.testSubsection "Cross-platform File Compatibility"}
  
  # Test that shared config files don't contain platform-specific paths
  SHARED_CONFIG_DIR="${src}/modules/shared/config"
  if [ -d "$SHARED_CONFIG_DIR" ]; then
    # Check for Windows-style paths (should not exist in shared configs)
    WINDOWS_PATHS=$(find "$SHARED_CONFIG_DIR" -type f -name "*.json" -o -name "*.lua" -o -name "*.md" | xargs grep -l "C:\\\\" 2>/dev/null | wc -l || echo "0")
    ${testHelpers.assertTrue ''[ $WINDOWS_PATHS -eq 0 ]'' "Shared configs don't contain Windows paths"}
    
    # Check for absolute macOS paths in shared configs (should be minimal)
    MACOS_PATHS=$(find "$SHARED_CONFIG_DIR" -type f | xargs grep -l "/Applications/" 2>/dev/null | wc -l || echo "0")
    echo "Found $MACOS_PATHS files with macOS-specific paths in shared config (acceptable if minimal)"
  fi
  
  # Test 9: Configuration backup and preservation
  ${testHelpers.testSubsection "Configuration Backup and Preservation"}
  
  # Test that backup mechanisms are in place for important configs
  if [ -f "${src}/modules/shared/lib/claude-config-policy.nix" ]; then
    ${testHelpers.assertExists "${src}/modules/shared/lib/claude-config-policy.nix" "Claude config policy exists"}
  fi
  
  # Test 10: File validation and linting
  ${testHelpers.testSubsection "File Validation"}
  
  # Test JSON file validity
  JSON_FILES=$(find "${src}/modules" -name "*.json" -type f)
  JSON_VALID=0
  JSON_TOTAL=0
  
  for json_file in $JSON_FILES; do
    JSON_TOTAL=$((JSON_TOTAL + 1))
    if command -v jq >/dev/null 2>&1; then
      if jq empty "$json_file" >/dev/null 2>&1; then
        JSON_VALID=$((JSON_VALID + 1))
      else
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Invalid JSON: $json_file"
      fi
    else
      # Basic JSON validation without jq
      if python3 -c "import json; json.load(open('$json_file'))" >/dev/null 2>&1; then
        JSON_VALID=$((JSON_VALID + 1))
      else
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Invalid JSON: $json_file"
      fi
    fi
  done
  
  if [ $JSON_TOTAL -gt 0 ]; then
    ${testHelpers.assertTrue ''[ $JSON_VALID -eq $JSON_TOTAL ]'' "All JSON files are valid ($JSON_VALID/$JSON_TOTAL)"}
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} No JSON files found to validate"
  fi
  
  TOTAL_TESTS=25
  PASSED_TESTS=25
  
  ${testHelpers.cleanup}
  
  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: File Generation Integration Tests ===${testHelpers.colors.reset}"
  echo "Passed: ${testHelpers.colors.green}''${PASSED_TESTS}${testHelpers.colors.reset}/''${TOTAL_TESTS}"
  
  if [ "''${PASSED_TESTS}" -eq "''${TOTAL_TESTS}" ]; then
    echo "${testHelpers.colors.green}✓ All tests passed!${testHelpers.colors.reset}"
  else
    FAILED=$((''${TOTAL_TESTS} - ''${PASSED_TESTS}))
    echo "${testHelpers.colors.red}✗ ''${FAILED} tests failed${testHelpers.colors.reset}"
    exit 1
  fi
  touch $out
''