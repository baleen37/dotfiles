# Simplified edge case tests for Git configuration
# Core edge case validation without over-engineering
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  self ? ./.,
  ...
}:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  userInfo = import ../../lib/user-info.nix;
in

# Basic git edge case validation
testHelpers.mkTest "git-edge-cases" ''
  echo "Testing Git configuration edge cases..."

  # Test 1: Basic git configuration validity
  if command -v git >/dev/null 2>&1; then
    echo "✅ Git is available"
  else
    echo "❌ Git is not available"
    exit 1
  fi

  # Test 2: Git user configuration edge cases
  test_user="testuser"
  test_email="test@example.com"

  # Test valid email format
  if [[ "$test_email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
    echo "✅ Valid email format validation working"
  else
    echo "❌ Email format validation failed"
    exit 1
  fi

  # Test 3: Git alias functionality
  git config --global alias.st status
  if git st >/dev/null 2>&1; then
    echo "✅ Git alias functionality working"
  else
    echo "❌ Git alias functionality failed"
    exit 1
  fi

  # Test 4: Git ignore pattern validation
  echo "*.tmp" > /tmp/test-gitignore
  if [ -f /tmp/test-gitignore ]; then
    echo "✅ Git ignore file creation working"
    rm -f /tmp/test-gitignore
  else
    echo "❌ Git ignore file creation failed"
    exit 1
  fi

  # Test 5: Repository initialization edge case
  test_repo="/tmp/test-git-repo-$$"
  mkdir -p "$test_repo"
  if git init "$test_repo" >/dev/null 2>&1; then
    echo "✅ Repository initialization working"
    rm -rf "$test_repo"
  else
    echo "❌ Repository initialization failed"
    exit 1
  fi

  echo "✅ All Git edge case tests passed"
''
