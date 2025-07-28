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

if [ -f ".dead-code-backup/phase1_20250728_105904/lib/auto-update-notifications.nix" ]; then
    echo "  🗑️ Removing: .dead-code-backup/phase1_20250728_105904/lib/auto-update-notifications.nix"
    rm ".dead-code-backup/phase1_20250728_105904/lib/auto-update-notifications.nix"
else
    echo "  ⚠️ Not found: .dead-code-backup/phase1_20250728_105904/lib/auto-update-notifications.nix"
fi
if [ -f ".dead-code-backup/phase1_20250728_105904/lib/auto-update-prompt.nix" ]; then
    echo "  🗑️ Removing: .dead-code-backup/phase1_20250728_105904/lib/auto-update-prompt.nix"
    rm ".dead-code-backup/phase1_20250728_105904/lib/auto-update-prompt.nix"
else
    echo "  ⚠️ Not found: .dead-code-backup/phase1_20250728_105904/lib/auto-update-prompt.nix"
fi
if [ -f ".dead-code-backup/phase1_20250728_105904/lib/auto-update-state.nix" ]; then
    echo "  🗑️ Removing: .dead-code-backup/phase1_20250728_105904/lib/auto-update-state.nix"
    rm ".dead-code-backup/phase1_20250728_105904/lib/auto-update-state.nix"
else
    echo "  ⚠️ Not found: .dead-code-backup/phase1_20250728_105904/lib/auto-update-state.nix"
fi
if [ -f ".dead-code-backup/phase1_20250728_105904/lib/consolidation-engine.nix" ]; then
    echo "  🗑️ Removing: .dead-code-backup/phase1_20250728_105904/lib/consolidation-engine.nix"
    rm ".dead-code-backup/phase1_20250728_105904/lib/consolidation-engine.nix"
else
    echo "  ⚠️ Not found: .dead-code-backup/phase1_20250728_105904/lib/consolidation-engine.nix"
fi
if [ -f ".dead-code-backup/phase1_20250728_105904/lib/existing-tests.nix" ]; then
    echo "  🗑️ Removing: .dead-code-backup/phase1_20250728_105904/lib/existing-tests.nix"
    rm ".dead-code-backup/phase1_20250728_105904/lib/existing-tests.nix"
else
    echo "  ⚠️ Not found: .dead-code-backup/phase1_20250728_105904/lib/existing-tests.nix"
fi
if [ -f ".dead-code-backup/phase1_20250728_105904/lib/template-engine.nix" ]; then
    echo "  🗑️ Removing: .dead-code-backup/phase1_20250728_105904/lib/template-engine.nix"
    rm ".dead-code-backup/phase1_20250728_105904/lib/template-engine.nix"
else
    echo "  ⚠️ Not found: .dead-code-backup/phase1_20250728_105904/lib/template-engine.nix"
fi
if [ -f ".dead-code-backup/phase1_20250728_105904/lib/template-system.nix" ]; then
    echo "  🗑️ Removing: .dead-code-backup/phase1_20250728_105904/lib/template-system.nix"
    rm ".dead-code-backup/phase1_20250728_105904/lib/template-system.nix"
else
    echo "  ⚠️ Not found: .dead-code-backup/phase1_20250728_105904/lib/template-system.nix"
fi
if [ -f ".dead-code-backup/phase1_20250728_105904/tests-consolidated/01-core-system.nix" ]; then
    echo "  🗑️ Removing: .dead-code-backup/phase1_20250728_105904/tests-consolidated/01-core-system.nix"
    rm ".dead-code-backup/phase1_20250728_105904/tests-consolidated/01-core-system.nix"
else
    echo "  ⚠️ Not found: .dead-code-backup/phase1_20250728_105904/tests-consolidated/01-core-system.nix"
fi
if [ -f ".dead-code-backup/phase1_20250728_105904/tests-consolidated/02-build-switch.nix" ]; then
    echo "  🗑️ Removing: .dead-code-backup/phase1_20250728_105904/tests-consolidated/02-build-switch.nix"
    rm ".dead-code-backup/phase1_20250728_105904/tests-consolidated/02-build-switch.nix"
else
    echo "  ⚠️ Not found: .dead-code-backup/phase1_20250728_105904/tests-consolidated/02-build-switch.nix"
fi
if [ -f ".dead-code-backup/phase1_20250728_105904/tests-consolidated/03-platform-detection.nix" ]; then
    echo "  🗑️ Removing: .dead-code-backup/phase1_20250728_105904/tests-consolidated/03-platform-detection.nix"
    rm ".dead-code-backup/phase1_20250728_105904/tests-consolidated/03-platform-detection.nix"
else
    echo "  ⚠️ Not found: .dead-code-backup/phase1_20250728_105904/tests-consolidated/03-platform-detection.nix"
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
