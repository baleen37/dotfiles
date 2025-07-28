#!/usr/bin/env python3
"""
개선된 Nix 의존성 분석 도구
더 정확한 import 구문 파싱과 의존성 추적 기능 제공
"""

import os
import re
import json
import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple
from collections import defaultdict, deque

class ImprovedNixDependencyAnalyzer:
    def __init__(self, repo_path: str):
        self.repo_path = Path(repo_path)
        self.dependencies = defaultdict(set)
        self.reverse_dependencies = defaultdict(set)
        self.file_contents = {}
        self.nix_files = []

    def scan_repository(self):
        """저장소의 모든 .nix 파일을 스캔합니다."""
        print("🔍 Scanning repository for .nix files...")

        for file_path in self.repo_path.rglob("*.nix"):
            if file_path.is_file():
                relative_path = file_path.relative_to(self.repo_path)
                self.nix_files.append(relative_path)

                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                        self.file_contents[str(relative_path)] = content
                except Exception as e:
                    print(f"❌ Error reading {relative_path}: {e}")

        print(f"✅ Found {len(self.nix_files)} .nix files")
        return self.nix_files

    def normalize_path(self, import_path: str, current_file: str) -> str:
        """import 경로를 정규화합니다."""
        # ./로 시작하는 상대 경로 처리
        if import_path.startswith('./'):
            import_path = import_path[2:]
            current_dir = Path(current_file).parent
            normalized = (current_dir / import_path).as_posix()
            return normalized

        # ../로 시작하는 상대 경로 처리
        elif import_path.startswith('../'):
            current_dir = Path(current_file).parent
            try:
                resolved = (current_dir / import_path).resolve()
                relative_to_repo = resolved.relative_to(self.repo_path)
                return str(relative_to_repo)
            except:
                return import_path

        # 절대 경로나 단순 파일명은 그대로 반환
        return import_path

    def extract_imports(self, content: str, current_file: str) -> Set[str]:
        """파일에서 모든 import 구문을 추출합니다."""
        imports = set()

        # 다양한 import 패턴 정의
        patterns = [
            # import ./path/file.nix
            r'import\s+(\./[^;\s}]+\.nix)',
            # import ../path/file.nix
            r'import\s+(\.\.\/[^;\s}]+\.nix)',
            # import /absolute/path.nix
            r'import\s+(\/[^;\s}]+\.nix)',
            # import file.nix (같은 디렉토리)
            r'import\s+([^/\s;{}]+\.nix)(?!\s*\{)',
            # ../modules/something.nix (직접 경로 참조)
            r'(?<!")(\.\./[^"\s;{}]+\.nix)(?!")',
            # ./something.nix (직접 경로 참조)
            r'(?<!")(\./[^"\s;{}]+\.nix)(?!")',
        ]

        for pattern in patterns:
            matches = re.findall(pattern, content, re.MULTILINE)
            for match in matches:
                if isinstance(match, tuple):
                    match = match[0]

                # 경로 정규화
                normalized = self.normalize_path(match, current_file)

                # 실제 파일이 존재하는지 확인
                if normalized in [str(f) for f in self.nix_files]:
                    imports.add(normalized)
                elif (self.repo_path / normalized).exists():
                    imports.add(normalized)

        return imports

    def analyze_all_dependencies(self):
        """모든 파일의 의존성을 분석합니다."""
        print("\n🔗 Analyzing dependencies for all files...")

        for nix_file in self.nix_files:
            file_str = str(nix_file)
            content = self.file_contents[file_str]

            # 파일의 모든 import 추출
            imports = self.extract_imports(content, file_str)

            # 의존성 그래프 구성
            self.dependencies[file_str] = imports

            # 역 의존성 그래프 구성
            for imported_file in imports:
                self.reverse_dependencies[imported_file].add(file_str)

        total_deps = sum(len(deps) for deps in self.dependencies.values())
        print(f"  📊 Total dependencies found: {total_deps}")

        return self.dependencies

    def find_entry_points(self) -> Set[str]:
        """진입점 파일들을 식별합니다."""
        entry_points = set()

        # 명시적 진입점들
        explicit_entries = [
            'flake.nix',
            'default.nix'
        ]

        for entry in explicit_entries:
            if entry in [str(f) for f in self.nix_files]:
                entry_points.add(entry)

        # hosts/ 디렉토리의 default.nix들도 진입점
        for nix_file in self.nix_files:
            if str(nix_file).startswith('hosts/') and nix_file.name == 'default.nix':
                entry_points.add(str(nix_file))

        # app 관련 파일들도 진입점으로 간주
        for nix_file in self.nix_files:
            if '/build' in str(nix_file) or '/apply' in str(nix_file):
                continue  # 실행 파일은 제외
            if str(nix_file).startswith('apps/'):
                entry_points.add(str(nix_file))

        return entry_points

    def find_reachable_files(self, entry_points: Set[str]) -> Set[str]:
        """진입점에서 도달 가능한 모든 파일을 찾습니다."""
        reachable = set()
        queue = deque(entry_points)

        while queue:
            current = queue.popleft()
            if current in reachable:
                continue

            reachable.add(current)

            # 현재 파일이 의존하는 파일들을 큐에 추가
            for dependency in self.dependencies.get(current, set()):
                if dependency not in reachable:
                    queue.append(dependency)

        return reachable

    def find_unused_files(self):
        """실제로 사용되지 않는 파일들을 찾습니다."""
        print("\n🗑️  Finding truly unused files...")

        # 진입점 식별
        entry_points = self.find_entry_points()
        print(f"  🚪 Entry points found: {len(entry_points)}")
        for ep in sorted(entry_points):
            print(f"     - {ep}")

        # 진입점에서 도달 가능한 파일들 찾기
        reachable = self.find_reachable_files(entry_points)
        print(f"  🔗 Reachable files: {len(reachable)}")

        # 모든 파일 집합
        all_files = set(str(f) for f in self.nix_files)

        # 사용되지 않는 파일들
        unused = all_files - reachable

        print(f"  📊 Total files: {len(all_files)}")
        print(f"  ✅ Used files: {len(reachable)}")
        print(f"  ❌ Unused files: {len(unused)}")

        return {
            'unused': sorted(unused),
            'used': sorted(reachable),
            'entry_points': sorted(entry_points)
        }

    def analyze_dependency_depth(self):
        """의존성 깊이를 분석합니다."""
        print("\n📏 Analyzing dependency depth...")

        entry_points = self.find_entry_points()
        depth_map = {}

        for entry in entry_points:
            depths = {}
            queue = deque([(entry, 0)])
            visited = set()

            while queue:
                current, depth = queue.popleft()
                if current in visited:
                    continue
                visited.add(current)

                if current not in depths or depth < depths[current]:
                    depths[current] = depth

                for dependency in self.dependencies.get(current, set()):
                    if dependency not in visited:
                        queue.append((dependency, depth + 1))

            for file, depth in depths.items():
                if file not in depth_map or depth < depth_map[file]:
                    depth_map[file] = depth

        return depth_map

    def generate_detailed_report(self):
        """상세한 분석 보고서를 생성합니다."""
        print("\n📝 Generating detailed analysis report...")

        # 의존성 분석 실행
        self.analyze_all_dependencies()

        # 미사용 파일 분석
        unused_analysis = self.find_unused_files()

        # 의존성 깊이 분석
        depth_map = self.analyze_dependency_depth()

        # 통계 계산
        stats = {
            'total_files': len(self.nix_files),
            'lib_files': len([f for f in self.nix_files if str(f).startswith('lib/')]),
            'module_files': len([f for f in self.nix_files if str(f).startswith('modules/')]),
            'test_files': len([f for f in self.nix_files if str(f).startswith('tests/')]),
            'script_files': len([f for f in self.nix_files if str(f).startswith('scripts/')]),
            'host_files': len([f for f in self.nix_files if str(f).startswith('hosts/')]),
            'total_dependencies': sum(len(deps) for deps in self.dependencies.values()),
            'unused_files_count': len(unused_analysis['unused']),
            'used_files_count': len(unused_analysis['used']),
            'entry_points_count': len(unused_analysis['entry_points']),
            'max_dependency_depth': max(depth_map.values()) if depth_map else 0
        }

        # 카테고리별 미사용 파일 분석
        unused_by_category = self._categorize_unused_files(unused_analysis['unused'])

        # 의존성 순환 검사
        cycles = self._detect_dependency_cycles()

        report = {
            'timestamp': str(Path().resolve()),
            'statistics': stats,
            'unused_analysis': unused_analysis,
            'unused_by_category': unused_by_category,
            'dependency_cycles': cycles,
            'depth_analysis': {
                'max_depth': stats['max_dependency_depth'],
                'depth_distribution': self._calculate_depth_distribution(depth_map)
            },
            'recommendations': self._generate_improved_recommendations(unused_analysis, stats, cycles)
        }

        return report

    def _categorize_unused_files(self, unused_files: List[str]) -> Dict[str, List[str]]:
        """미사용 파일들을 카테고리별로 분류합니다."""
        categories = {
            'lib': [],
            'modules': [],
            'tests': [],
            'hosts': [],
            'overlays': [],
            'scripts': [],
            'other': []
        }

        for file in unused_files:
            if file.startswith('lib/'):
                categories['lib'].append(file)
            elif file.startswith('modules/'):
                categories['modules'].append(file)
            elif file.startswith('tests/'):
                categories['tests'].append(file)
            elif file.startswith('hosts/'):
                categories['hosts'].append(file)
            elif file.startswith('overlays/'):
                categories['overlays'].append(file)
            elif file.startswith('scripts/') and file.endswith('.nix'):
                categories['scripts'].append(file)
            else:
                categories['other'].append(file)

        return categories

    def _detect_dependency_cycles(self) -> List[List[str]]:
        """의존성 순환을 검사합니다."""
        def dfs(node, visited, rec_stack, path):
            visited.add(node)
            rec_stack.add(node)
            path.append(node)

            for neighbor in self.dependencies.get(node, set()):
                if neighbor not in visited:
                    cycle = dfs(neighbor, visited, rec_stack, path[:])
                    if cycle:
                        return cycle
                elif neighbor in rec_stack:
                    # 순환 발견
                    cycle_start = path.index(neighbor)
                    return path[cycle_start:] + [neighbor]

            rec_stack.remove(node)
            return None

        visited = set()
        cycles = []

        for node in self.dependencies:
            if node not in visited:
                cycle = dfs(node, visited, set(), [])
                if cycle:
                    cycles.append(cycle)

        return cycles

    def _calculate_depth_distribution(self, depth_map: Dict[str, int]) -> Dict[int, int]:
        """깊이별 파일 분포를 계산합니다."""
        distribution = defaultdict(int)
        for depth in depth_map.values():
            distribution[depth] += 1
        return dict(distribution)

    def _generate_improved_recommendations(self, unused_analysis: Dict, stats: Dict, cycles: List) -> List[str]:
        """개선된 권장사항을 생성합니다."""
        recommendations = []

        unused_count = len(unused_analysis['unused'])
        if unused_count > 0:
            recommendations.append(f"🗑️ Review {unused_count} unused files for potential removal")

        if len(cycles) > 0:
            recommendations.append(f"🔄 Fix {len(cycles)} dependency cycles detected")

        if stats['max_dependency_depth'] > 5:
            recommendations.append(f"📏 Consider flattening dependency tree (max depth: {stats['max_dependency_depth']})")

        lib_files = stats['lib_files']
        if lib_files > 30:
            recommendations.append(f"📚 Large lib/ directory ({lib_files} files) - consider modularization")

        dependency_ratio = stats['total_dependencies'] / stats['total_files'] if stats['total_files'] > 0 else 0
        if dependency_ratio > 1.5:
            recommendations.append(f"🔗 High dependency ratio ({dependency_ratio:.2f}) - review coupling")

        return recommendations

def main():
    if len(sys.argv) > 1:
        repo_path = sys.argv[1]
    else:
        repo_path = os.getcwd()

    print(f"🚀 Starting improved dependency analysis for: {repo_path}")
    print("=" * 70)

    analyzer = ImprovedNixDependencyAnalyzer(repo_path)

    # 저장소 스캔
    analyzer.scan_repository()

    # 분석 실행 및 보고서 생성
    report = analyzer.generate_detailed_report()

    # 결과 출력
    print("\n" + "=" * 70)
    print("📊 IMPROVED ANALYSIS SUMMARY")
    print("=" * 70)

    stats = report['statistics']
    print(f"📁 Total .nix files: {stats['total_files']}")
    print(f"📚 Library files: {stats['lib_files']}")
    print(f"🧩 Module files: {stats['module_files']}")
    print(f"🧪 Test files: {stats['test_files']}")
    print(f"🏠 Host files: {stats['host_files']}")
    print(f"🔗 Total dependencies: {stats['total_dependencies']}")
    print(f"🚪 Entry points: {stats['entry_points_count']}")
    print(f"✅ Used files: {stats['used_files_count']}")
    print(f"❌ Unused files: {stats['unused_files_count']}")
    print(f"📏 Max dependency depth: {stats['max_dependency_depth']}")

    # 카테고리별 미사용 파일
    print("\n🗂️ UNUSED FILES BY CATEGORY:")
    for category, files in report['unused_by_category'].items():
        if files:
            print(f"   📁 {category}: {len(files)} files")

    # 의존성 순환
    if report['dependency_cycles']:
        print(f"\n🔄 DEPENDENCY CYCLES DETECTED: {len(report['dependency_cycles'])}")

    print("\n💡 RECOMMENDATIONS:")
    for i, rec in enumerate(report['recommendations'], 1):
        print(f"   {i}. {rec}")

    # 상세 보고서 저장
    output_file = Path(repo_path) / "improved-dependency-analysis.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)

    print(f"\n📋 Detailed report saved to: {output_file}")
    print("=" * 70)
    print("✅ Improved analysis completed successfully!")

if __name__ == "__main__":
    main()
