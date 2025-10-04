#!/usr/bin/env bash
# Demo script for the auto-formatting system
# Shows the capabilities and usage of the new formatting tools

set -euo pipefail

echo "🎨 Auto-Formatting System Demo"
echo "=============================="
echo

echo "📋 Available formatting commands:"
echo "  make format           - Auto-format all files"
echo "  make format-check     - Check if formatting needed (CI mode)"
echo "  make format-dry-run   - Preview changes without applying"
echo "  make format-nix       - Format only Nix files"
echo "  make format-shell     - Format only shell scripts"
echo "  make format-yaml      - Format only YAML files"
echo "  make format-json      - Format only JSON files"
echo "  make format-markdown  - Format only Markdown files"
echo

echo "🔧 Enhanced pre-commit integration:"
echo "  make lint-autofix             - Run linting with auto-fix"
echo "  make lint-install-autofix     - Install auto-fix pre-commit hooks"
echo

echo "📁 Configuration files:"
echo "  .pre-commit-config-autofix.yaml - Enhanced pre-commit with auto-fix"
echo "  .prettierrc.yaml                - Prettier configuration"
echo "  .editorconfig                   - Editor formatting rules"
echo "  scripts/auto-format.sh          - Standalone formatting script"
echo

echo "🧰 Formatting tools included:"
echo "  ✅ nixpkgs-fmt    - Nix files"
echo "  ✅ shfmt          - Shell scripts (2-space indent)"
echo "  ✅ prettier       - YAML, JSON, Markdown (120 char width)"
echo "  ✅ jq             - JSON formatting"
echo "  ✅ markdownlint   - Markdown with auto-fix"
echo

echo "🚀 Quick start:"
echo "  1. nix develop                    # Enter dev shell with tools"
echo "  2. make format-dry-run            # Preview changes"
echo "  3. make format                    # Apply formatting"
echo "  4. make lint-install-autofix      # Install auto-fix hooks"
echo

echo "💡 For detailed documentation, see:"
echo "   docs/AUTO-FORMATTING.md"
echo

if command -v make >/dev/null 2>&1; then
  echo "🔍 Testing format-check (safe operation):"
  if make format-check >/dev/null 2>&1; then
    echo "  ✅ All files are properly formatted"
  else
    echo "  📝 Some files need formatting - run 'make format' to fix"
  fi
else
  echo "⚠️  Make not available - run commands directly with scripts/auto-format.sh"
fi

echo
echo "🎯 Integration complete! The auto-formatting system is ready to use."
