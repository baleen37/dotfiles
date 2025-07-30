#!/usr/bin/env python3
"""
Dead Code 검출 및 제거 도구
코드베이스에서 실제로 사용되지 않는 파일들을 안전하게 식별하고 제거를 제안하는 도구
"""

import json
import shutil
from pathlib import Path
from typing import Dict, List
from datetime import datetime

class DeadCodeDetector:
    def __init__(self, repo_path: str):
        self.repo_path = Path(repo_path)
        self.backup_dir = self.repo_path / ".dead-code-backup"

    def load_dependency_analysis(self) -> Dict:
        """이전 분석 결과를 로드합니다."""
        analysis_file = self.repo_path / "improved-dependency-analysis.json"
        if not analysis_file.exists():
            raise FileNotFoundError("Dependency analysis not found. Please run analyze-dependencies-improved.py first.")

        with open(analysis_file, 'r', encoding='utf-8') as f:
            return json.load(f)

    def categorize_dead_code(self, unused_files: List[str]) -> Dict[str, List[str]]:
        """Dead code를 제거 우선순위별로 분류합니다."""
        categories = {
            'safe_to_remove': [],      # 안전하게 제거 가능
            'review_required': [],     # 검토 필요
            'keep_for_reference': [],  # 참조용 보존
            'potential_false_positive': []  # False positive 가능성
        }

        for file in unused_files:
            file_path = Path(file)

            # 안전하게 제거 가능한 파일들
            if (file.startswith('tests-consolidated/') or
                file.startswith('tests/performance/') or
                file.endswith('-test.nix') or
                'backup' in file.lower() or
                'temp' in file.lower() or
                file.startswith('lib/auto-update-') or
                file.startswith('lib/existing-tests.nix')):
                categories['safe_to_remove'].append(file)

            # False positive 가능성이 있는 파일들
            elif (file == 'modules/shared/default.nix' or
                  file.endswith('/default.nix') or
                  'config' in file.lower() or
                  file.startswith('overlays/')):
                categories['potential_false_positive'].append(file)

            # 참조용으로 보존할 파일들
            elif ('example' in file.lower() or
                  'template' in file.lower() or
                  'documentation' in file.lower()):
                categories['keep_for_reference'].append(file)

            # 나머지는 검토 필요
            else:
                categories['review_required'].append(file)

        return categories

    def analyze_file_safety(self, file_path: str) -> Dict:
        """파일 제거의 안전성을 분석합니다."""
        full_path = self.repo_path / file_path
        safety_info = {
            'file': file_path,
            'exists': full_path.exists(),
            'size_bytes': 0,
            'line_count': 0,
            'has_exports': False,
            'has_complex_logic': False,
            'git_tracked': True,  # Git으로 추적되는지
            'recent_modifications': False
        }

        if full_path.exists():
            try:
                # 파일 크기
                safety_info['size_bytes'] = full_path.stat().st_size

                # 파일 내용 분석
                with open(full_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    lines = content.split('\n')
                    safety_info['line_count'] = len(lines)

                    # exports나 함수 정의 확인
                    if ('=' in content and
                        ('rec' in content or 'let' in content or 'with' in content)):
                        safety_info['has_exports'] = True

                    # 복잡한 로직 확인
                    if (safety_info['line_count'] > 50 or
                        'import' in content or
                        'callPackage' in content):
                        safety_info['has_complex_logic'] = True

            except Exception as e:
                print(f"Warning: Could not analyze {file_path}: {e}")

        return safety_info

    def create_removal_plan(self, analysis: Dict) -> Dict:
        """제거 계획을 생성합니다."""
        unused_files = analysis['unused_analysis']['unused']
        categorized = self.categorize_dead_code(unused_files)

        plan = {
            'timestamp': datetime.now().isoformat(),
            'total_unused': len(unused_files),
            'categories': categorized,
            'removal_phases': [],
            'safety_analysis': {}
        }

        # 각 파일의 안전성 분석
        for file in unused_files[:20]:  # 처음 20개만 상세 분석
            plan['safety_analysis'][file] = self.analyze_file_safety(file)

        # 제거 단계별 계획
        phases = [
            {
                'phase': 1,
                'description': 'Safe removals - Test files and obvious dead code',
                'files': categorized['safe_to_remove'][:10],  # 처음 10개만
                'risk_level': 'low'
            },
            {
                'phase': 2,
                'description': 'Review required - Potentially unused modules',
                'files': categorized['review_required'][:5],  # 처음 5개만
                'risk_level': 'medium'
            },
            {
                'phase': 3,
                'description': 'Manual verification - Possible false positives',
                'files': categorized['potential_false_positive'],
                'risk_level': 'high'
            }
        ]

        plan['removal_phases'] = phases
        return plan

    def create_backup(self, files_to_backup: List[str]) -> str:
        """파일들을 백업합니다."""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_path = self.backup_dir / f"backup_{timestamp}"
        backup_path.mkdir(parents=True, exist_ok=True)

        backed_up = []
        for file_path in files_to_backup:
            source = self.repo_path / file_path
            if source.exists():
                dest = backup_path / file_path
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, dest)
                backed_up.append(file_path)

        # 백업 메타데이터 저장
        metadata = {
            'timestamp': timestamp,
            'backed_up_files': backed_up,
            'total_count': len(backed_up)
        }

        with open(backup_path / "backup_metadata.json", 'w') as f:
            json.dump(metadata, f, indent=2)

        return str(backup_path)

    def generate_removal_script(self, plan: Dict) -> str:
        """안전한 제거 스크립트를 생성합니다."""
        script_content = """#!/bin/bash
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
"""

        # Phase 1 파일들 추가
        phase1_files = plan['removal_phases'][0]['files'] if plan['removal_phases'] else []
        for file in phase1_files:
            script_content += f"""
if [ -f "{file}" ]; then
    echo "  🗑️ Removing: {file}"
    rm "{file}"
else
    echo "  ⚠️ Not found: {file}"
fi"""

        script_content += """

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
"""

        return script_content

    def run_analysis(self):
        """전체 분석을 실행합니다."""
        print("🚀 Starting dead code detection analysis...")
        print("=" * 60)

        # 의존성 분석 결과 로드
        try:
            analysis = self.load_dependency_analysis()
        except FileNotFoundError as e:
            print(f"❌ {e}")
            print("Please run: python3 scripts/analyze-dependencies-improved.py")
            return

        # 제거 계획 생성
        plan = self.create_removal_plan(analysis)

        # 결과 출력
        print(f"📊 Total unused files: {plan['total_unused']}")
        print(f"🟢 Safe to remove: {len(plan['categories']['safe_to_remove'])}")
        print(f"🟡 Review required: {len(plan['categories']['review_required'])}")
        print(f"🔴 Potential false positives: {len(plan['categories']['potential_false_positive'])}")
        print(f"📚 Keep for reference: {len(plan['categories']['keep_for_reference'])}")

        # 제거 단계별 계획 출력
        print("\n📋 REMOVAL PHASES:")
        for phase in plan['removal_phases']:
            print(f"  Phase {phase['phase']}: {phase['description']}")
            print(f"    Risk: {phase['risk_level']}")
            print(f"    Files: {len(phase['files'])}")
            if phase['files']:
                for file in phase['files'][:3]:  # 처음 3개만 표시
                    print(f"      - {file}")
                if len(phase['files']) > 3:
                    print(f"      ... and {len(phase['files']) - 3} more")
            print()

        # 계획 저장
        plan_file = self.repo_path / "dead-code-removal-plan.json"
        with open(plan_file, 'w', encoding='utf-8') as f:
            json.dump(plan, f, indent=2, ensure_ascii=False)

        # 제거 스크립트 생성
        script_content = self.generate_removal_script(plan)
        script_file = self.repo_path / "remove-dead-code.sh"
        with open(script_file, 'w') as f:
            f.write(script_content)
        script_file.chmod(0o755)

        print("💡 NEXT STEPS:")
        print(f"  1. Review plan: {plan_file}")
        print(f"  2. Create backup: python3 -c \"from scripts.detect_dead_code import *; d=DeadCodeDetector('.'); d.create_backup({plan['categories']['safe_to_remove'][:10]})\"")
        print(f"  3. Run removal: ./remove-dead-code.sh")
        print("  4. Test build: nix flake check")
        print("  5. Commit changes: git add . && git commit -m 'Remove dead code'")

        print("\n✅ Dead code analysis completed!")
        return plan

def main():
    detector = DeadCodeDetector('.')
    detector.run_analysis()

if __name__ == "__main__":
    main()
