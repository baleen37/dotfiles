#!/bin/bash

echo "🔧 Setting up git hooks..."

# Check if we're in a git repository or worktree
if [ ! -d ".git" ] && [ ! -f ".git" ]; then
    echo "❌ Error: Not in a git repository or worktree"
    exit 1
fi

# Handle both git directory and worktree
if [ -f ".git" ]; then
    # This is a worktree, read the git directory path
    GIT_DIR=$(cat .git | sed 's/gitdir: //')
    HOOKS_DIR="$GIT_DIR/hooks"
else
    # This is a regular git repository
    HOOKS_DIR=".git/hooks"
fi

# Check if pre-commit script exists
if [ ! -f "scripts/pre-commit" ]; then
    echo "❌ Error: scripts/pre-commit not found"
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p "$HOOKS_DIR"

# Copy pre-commit hook
cp scripts/pre-commit "$HOOKS_DIR/pre-commit"

# Make it executable
chmod +x "$HOOKS_DIR/pre-commit"

echo "✅ Pre-commit hook installed successfully"
echo ""
echo "📋 Hook will run the following checks before each commit:"
echo "   • Code formatting (make fmt)"
echo "   • Linting (make lint)"
echo ""
echo "💡 To bypass hook in emergency (NOT RECOMMENDED):"
echo "   Use: git commit --no-verify"
echo ""
echo "🎉 Setup complete! Your commits will now be automatically checked."