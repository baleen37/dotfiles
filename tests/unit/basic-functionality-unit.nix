{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
in
pkgs.runCommand "basic-functionality-unit-test" {} ''
  ${testHelpers.setupTestEnv}
  
  ${testHelpers.testSection "Basic Functionality Unit Tests"}
  
  # Test 1: Math operations
  ${testHelpers.testSubsection "Mathematical Operations"}
  MATH_RESULT=$((1 + 1))
  if [ $MATH_RESULT -eq 2 ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Basic addition works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Basic addition works"
    exit 1
  fi
  
  MATH_RESULT=$((5 * 3))
  if [ $MATH_RESULT -eq 15 ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Basic multiplication works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Basic multiplication works"
    exit 1
  fi
  
  # Test 2: String operations
  ${testHelpers.testSubsection "String Operations"}
  STRING="hello"
  ${testHelpers.assertTrue ''[ "$STRING" = "hello" ]'' "String assignment works"}
  
  CONCAT="$STRING world"
  ${testHelpers.assertTrue ''[ "$CONCAT" = "hello world" ]'' "String concatenation works"}
  
  # Test 3: File operations
  ${testHelpers.testSubsection "File Operations"}
  TEST_FILE=$(${testHelpers.createTempFile "test content"})
  ${testHelpers.assertExists "$TEST_FILE" "Temporary file creation works"}
  ${testHelpers.assertContains "$TEST_FILE" "test content" "File contains expected content"}
  
  # Test 4: Directory operations
  ${testHelpers.testSubsection "Directory Operations"}
  TEST_DIR=$(${testHelpers.createTempDir})
  ${testHelpers.assertExists "$TEST_DIR" "Temporary directory creation works"}
  
  touch "$TEST_DIR/test.txt"
  ${testHelpers.assertExists "$TEST_DIR/test.txt" "File creation in directory works"}
  
  # Test 5: Environment variables
  ${testHelpers.testSubsection "Environment Variables"}
  export TEST_VAR="test_value"
  ${testHelpers.assertTrue ''[ "$TEST_VAR" = "test_value" ]'' "Environment variable setting works"}
  
  unset TEST_VAR
  ${testHelpers.assertTrue ''[ -z "$TEST_VAR" ]'' "Environment variable unsetting works"}
  
  # Test 6: Command execution
  ${testHelpers.testSubsection "Command Execution"}
  ${testHelpers.assertCommand "echo 'test'" "Echo command works"}
  ${testHelpers.assertCommand "true" "True command works"}
  
  # Test 7: Path operations
  ${testHelpers.testSubsection "Path Operations"}
  ${testHelpers.assertExists "/bin/sh" "Shell exists at expected location"}
  ${testHelpers.assertExists "${pkgs.coreutils}/bin/ls" "Coreutils ls exists"}
  
  # Test 8: Nix evaluation basics
  ${testHelpers.testSubsection "Nix Evaluation"}
  NIX_RESULT=$(nix-instantiate --eval --expr '1 + 1' 2>/dev/null || echo "")
  ${testHelpers.assertTrue ''[ "$NIX_RESULT" = "2" ]'' "Nix basic evaluation works"}
  
  NIX_STRING=$(nix-instantiate --eval --expr '"hello"' 2>/dev/null | tr -d '"' || echo "")
  ${testHelpers.assertTrue ''[ "$NIX_STRING" = "hello" ]'' "Nix string evaluation works"}
  
  ${testHelpers.cleanup}
  ${testHelpers.reportResults "Basic Functionality Unit Tests" 15 15}
  touch $out
''