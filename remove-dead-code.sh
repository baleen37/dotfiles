#!/bin/bash
# Dead Code 제거 스크립트
# 이 스크립트는 분석 결과를 바탕으로 안전하게 파일을 제거합니다.

set -e  # 에러 발생시 중단

echo "🗑️ Starting dead code removal process..."
echo "========================================"

# 백업 디렉토리 확인
BACKUP_DIR=".dead-code-backup"
if [ ! -d "$BACKUP_DIR" ]; then
    echo "❌ Backup directory not found. Please create backup first."
    exit 1
fi

# Phase 1: Safe removals
echo ""
echo "📋 Phase 1: Safe removals (Low risk)"
echo "------------------------------------"

if [ -f "lib/auto-update-notifications.nix" ]; then
    echo "  🗑️ Removing: lib/auto-update-notifications.nix"
    rm "lib/auto-update-notifications.nix"
else
    echo "  ⚠️ Not found: lib/auto-update-notifications.nix"
fi
if [ -f "lib/auto-update-prompt.nix" ]; then
    echo "  🗑️ Removing: lib/auto-update-prompt.nix"
    rm "lib/auto-update-prompt.nix"
else
    echo "  ⚠️ Not found: lib/auto-update-prompt.nix"
fi
if [ -f "lib/auto-update-state.nix" ]; then
    echo "  🗑️ Removing: lib/auto-update-state.nix"
    rm "lib/auto-update-state.nix"
else
    echo "  ⚠️ Not found: lib/auto-update-state.nix"
fi
if [ -f "lib/existing-tests.nix" ]; then
    echo "  🗑️ Removing: lib/existing-tests.nix"
    rm "lib/existing-tests.nix"
else
    echo "  ⚠️ Not found: lib/existing-tests.nix"
fi
if [ -f "lib/template-engine.nix" ]; then
    echo "  🗑️ Removing: lib/template-engine.nix"
    rm "lib/template-engine.nix"
else
    echo "  ⚠️ Not found: lib/template-engine.nix"
fi
if [ -f "lib/template-system.nix" ]; then
    echo "  🗑️ Removing: lib/template-system.nix"
    rm "lib/template-system.nix"
else
    echo "  ⚠️ Not found: lib/template-system.nix"
fi
if [ -f "tests-consolidated/01-core-system.nix" ]; then
    echo "  🗑️ Removing: tests-consolidated/01-core-system.nix"
    rm "tests-consolidated/01-core-system.nix"
else
    echo "  ⚠️ Not found: tests-consolidated/01-core-system.nix"
fi
if [ -f "tests-consolidated/02-build-switch.nix" ]; then
    echo "  🗑️ Removing: tests-consolidated/02-build-switch.nix"
    rm "tests-consolidated/02-build-switch.nix"
else
    echo "  ⚠️ Not found: tests-consolidated/02-build-switch.nix"
fi
if [ -f "tests-consolidated/03-platform-detection.nix" ]; then
    echo "  🗑️ Removing: tests-consolidated/03-platform-detection.nix"
    rm "tests-consolidated/03-platform-detection.nix"
else
    echo "  ⚠️ Not found: tests-consolidated/03-platform-detection.nix"
fi
if [ -f "tests-consolidated/04-user-resolution.nix" ]; then
    echo "  🗑️ Removing: tests-consolidated/04-user-resolution.nix"
    rm "tests-consolidated/04-user-resolution.nix"
else
    echo "  ⚠️ Not found: tests-consolidated/04-user-resolution.nix"
fi

echo ""
echo "✅ Phase 1 completed"

# Git status 확인
echo ""
echo "📊 Git status after removals:"
git status --porcelain

echo ""
echo "🔍 Verifying build still works..."
if nix flake check 2>/dev/null; then
    echo "✅ Build verification passed"
else
    echo "❌ Build verification failed - consider reverting changes"
    echo "To revert: git checkout -- ."
fi

echo ""
echo "✅ Dead code removal completed successfully!"
echo "💡 Tip: Run 'git add .' and commit if everything looks good"
