#!/usr/bin/env bash
# tests/integration/test-claude-symlink.sh
# Integration test for Claude Code symlink configuration
# Validates that ~/.config/claude correctly symlinks to dotfiles (not Nix store)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
log_pass() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

log_fail() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

log_info() {
    echo -e "${YELLOW}ℹ INFO${NC}: $1"
}

# Determine DOTFILES_ROOT dynamically
DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
log_info "DOTFILES_ROOT detected: $DOTFILES_ROOT"

# Expected paths
CLAUDE_HOME="$HOME/.config/claude"
CLAUDE_SOURCE="$DOTFILES_ROOT/users/shared/.config/claude"

# Test 1: Check if ~/.config/claude exists
echo "Test 1: ~/.config/claude exists..."
if [ -e "$CLAUDE_HOME" ]; then
    log_pass "~/.config/claude exists"
else
    log_fail "~/.config/claude does not exist"
fi

# Test 2: Check if it's a symlink (not a regular directory)
echo "Test 2: ~/.config/claude is a symlink..."
if [ -L "$CLAUDE_HOME" ]; then
    log_pass "~/.config/claude is a symlink"
else
    log_fail "~/.config/claude is NOT a symlink (it's a $([ -d "$CLAUDE_HOME" ] && echo "directory" || echo "file"))"
fi

# Test 3: Check if symlink points to dotfiles (not /nix/store)
echo "Test 3: Symlink points to dotfiles (not /nix/store)..."
if [ -L "$CLAUDE_HOME" ]; then
    LINK_TARGET="$(readlink "$CLAUDE_HOME")"
    log_info "Symlink target: $LINK_TARGET"

    if [[ "$LINK_TARGET" == *"/nix/store/"* ]]; then
        log_fail "Symlink points to /nix/store (should point to $CLAUDE_SOURCE)"
    elif [[ "$LINK_TARGET" == "$CLAUDE_SOURCE" ]]; then
        log_pass "Symlink correctly points to dotfiles source"
    else
        log_fail "Symlink points to unexpected location: $LINK_TARGET (expected: $CLAUDE_SOURCE)"
    fi
else
    log_fail "Cannot check symlink target (not a symlink)"
fi

# Test 4: Check if source directory exists and has expected files
echo "Test 4: Source directory has expected files..."
EXPECTED_FILES=("CLAUDE.md" "settings.json")
EXPECTED_DIRS=("agents" "commands" "hooks" "skills")

ALL_EXIST=true
for file in "${EXPECTED_FILES[@]}"; do
    if [ -f "$CLAUDE_SOURCE/$file" ]; then
        log_pass "Source has $file"
    else
        log_fail "Source missing $file"
        ALL_EXIST=false
    fi
done

for dir in "${EXPECTED_DIRS[@]}"; do
    if [ -d "$CLAUDE_SOURCE/$dir" ]; then
        log_pass "Source has $dir/"
    else
        log_fail "Source missing $dir/"
        ALL_EXIST=false
    fi
done

# Test 5: Check if files are accessible through symlink
echo "Test 5: Files are accessible through symlink..."
if [ -L "$CLAUDE_HOME" ]; then
    for file in "${EXPECTED_FILES[@]}"; do
        if [ -f "$CLAUDE_HOME/$file" ]; then
            log_pass "$file accessible through symlink"
        else
            log_fail "$file NOT accessible through symlink"
        fi
    done

    for dir in "${EXPECTED_DIRS[@]}"; do
        if [ -d "$CLAUDE_HOME/$dir" ]; then
            log_pass "$dir/ accessible through symlink"
        else
            log_fail "$dir/ NOT accessible through symlink"
        fi
    done
fi

# Test 6: Check for unwanted Nix store references
echo "Test 6: No individual file symlinks to /nix/store..."
if [ -L "$CLAUDE_HOME" ]; then
    # If the directory itself is a proper symlink, individual files shouldn't have nix store links
    NIXED_FILES=()
    for file in "${EXPECTED_FILES[@]}"; do
        if [ -L "$CLAUDE_HOME/$file" ]; then
            FILE_TARGET="$(readlink "$CLAUDE_HOME/$file")"
            if [[ "$FILE_TARGET" == *"/nix/store/"* ]]; then
                NIXED_FILES+=("$file")
            fi
        fi
    done

    if [ ${#NIXED_FILES[@]} -eq 0 ]; then
        log_pass "No individual files point to /nix/store"
    else
        log_fail "Files pointing to /nix/store: ${NIXED_FILES[*]}"
    fi
fi

# Summary
echo ""
echo "=========================================="
echo "Test Summary:"
echo "  Passed: $TESTS_PASSED"
echo "  Failed: $TESTS_FAILED"
echo "=========================================="

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed!${NC}"
    exit 1
fi
