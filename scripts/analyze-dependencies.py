#!/usr/bin/env python3
"""
Dependency Analysis Tool for Nix Dotfiles Repository
코드베이스의 의존성 관계를 분석하고 시각화하는 도구

이 도구는 다음을 분석합니다:
1. flake.nix의 직접 의존성
2. lib/ 디렉토리의 함수 간 의존성
3. modules/ 디렉토리의 모듈 간 참조
4. 사용되지 않는 파일 및 함수 식별
"""

import os
import re
import json
import sys
from pathlib import Path
from typing import Dict, List
from collections import defaultdict

class NixDependencyAnalyzer:
    def __init__(self, repo_path: str):
        self.repo_path = Path(repo_path)
        self.dependencies = defaultdict(set)
        self.references = defaultdict(set)
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

    def analyze_flake_dependencies(self):
        """flake.nix의 의존성을 분석합니다."""
        print("\n📋 Analyzing flake.nix dependencies...")

        flake_path = "flake.nix"
        if flake_path not in self.file_contents:
            print("❌ flake.nix not found")
            return {}

        content = self.file_contents[flake_path]
        deps = {}

        # import 문 찾기
        import_pattern = r'import\s+([./\w-]+\.nix)'
        imports = re.findall(import_pattern, content)

        deps['direct_imports'] = imports
        self.dependencies[flake_path].update(imports)

        # lib 함수 참조 찾기
        lib_pattern = r'import\s+\./lib/([^;]+\.nix)'
        lib_imports = re.findall(lib_pattern, content)
        deps['lib_imports'] = lib_imports

        print(f"  📦 Direct imports: {len(imports)}")
        print(f"  📚 Library imports: {len(lib_imports)}")

        return deps

    def analyze_lib_dependencies(self):
        """lib/ 디렉토리의 함수 간 의존성을 분석합니다."""
        print("\n📚 Analyzing lib/ directory dependencies...")

        lib_files = [f for f in self.nix_files if str(f).startswith('lib/')]
        lib_deps = {}

        for lib_file in lib_files:
            content = self.file_contents[str(lib_file)]
            deps = set()

            # 다른 lib 파일 import 찾기
            import_pattern = r'import\s+\./([^;]+\.nix)'
            imports = re.findall(import_pattern, content)

            for imp in imports:
                # lib 디렉토리 내의 상대 경로 처리
                if not imp.startswith('/'):
                    lib_import_path = f"lib/{imp}"
                    if lib_import_path in [str(f) for f in self.nix_files]:
                        deps.add(lib_import_path)

            # 절대 경로로 된 lib import 찾기
            abs_lib_pattern = r'import\s+\./lib/([^;]+\.nix)'
            abs_imports = re.findall(abs_lib_pattern, content)
            for imp in abs_imports:
                lib_import_path = f"lib/{imp}"
                deps.add(lib_import_path)

            lib_deps[str(lib_file)] = list(deps)
            self.dependencies[str(lib_file)].update(deps)

        print(f"  📁 Analyzed {len(lib_files)} lib files")
        return lib_deps

    def analyze_module_dependencies(self):
        """modules/ 디렉토리의 모듈 간 의존성을 분석합니다."""
        print("\n🧩 Analyzing modules/ directory dependencies...")

        module_files = [f for f in self.nix_files if str(f).startswith('modules/')]
        module_deps = {}

        for module_file in module_files:
            content = self.file_contents[str(module_file)]
            deps = set()

            # 모듈 import 찾기
            import_patterns = [
                r'import\s+([./\w-]+\.nix)',
                r'./([^/\s;]+\.nix)',
                r'../([^/\s;]+\.nix)'
            ]

            for pattern in import_patterns:
                imports = re.findall(pattern, content)
                for imp in imports:
                    # 상대 경로 정규화
                    if imp.startswith('./'):
                        imp = imp[2:]
                    elif imp.startswith('../'):
                        # 상위 디렉토리 참조 처리
                        current_dir = Path(module_file).parent
                        try:
                            resolved = (current_dir / imp).resolve()
                            relative_to_repo = resolved.relative_to(self.repo_path)
                            imp = str(relative_to_repo)
                        except:
                            continue

                    if imp in [str(f) for f in self.nix_files]:
                        deps.add(imp)

            module_deps[str(module_file)] = list(deps)
            self.dependencies[str(module_file)].update(deps)

        print(f"  🔧 Analyzed {len(module_files)} module files")
        return module_deps

    def find_unused_files(self):
        """사용되지 않는 파일들을 찾습니다."""
        print("\n🗑️  Finding unused files...")

        # 모든 파일에서 참조되는 파일들 수집
        referenced_files = set()

        for file_path, deps in self.dependencies.items():
            referenced_files.update(deps)

        # flake.nix, default.nix는 항상 진입점으로 간주
        entry_points = {'flake.nix'}
        for f in self.nix_files:
            if f.name == 'default.nix':
                entry_points.add(str(f))

        # 참조되지 않는 파일 찾기
        all_files = set(str(f) for f in self.nix_files)
        potentially_unused = all_files - referenced_files - entry_points

        print(f"  📊 Total files: {len(all_files)}")
        print(f"  🔗 Referenced files: {len(referenced_files)}")
        print(f"  🚪 Entry points: {len(entry_points)}")
        print(f"  ❓ Potentially unused: {len(potentially_unused)}")

        return list(potentially_unused)

    def generate_dependency_graph(self):
        """의존성 그래프를 생성합니다."""
        print("\n📊 Generating dependency graph...")

        graph = {
            'nodes': [],
            'edges': []
        }

        # 노드 생성
        for file_path in self.file_contents.keys():
            category = self._categorize_file(file_path)
            graph['nodes'].append({
                'id': file_path,
                'label': Path(file_path).name,
                'category': category,
                'path': file_path
            })

        # 엣지 생성
        for source, targets in self.dependencies.items():
            for target in targets:
                if target in self.file_contents:
                    graph['edges'].append({
                        'source': source,
                        'target': target
                    })

        return graph

    def _categorize_file(self, file_path: str) -> str:
        """파일을 카테고리로 분류합니다."""
        if file_path == 'flake.nix':
            return 'entry'
        elif file_path.startswith('lib/'):
            return 'library'
        elif file_path.startswith('modules/'):
            return 'module'
        elif file_path.startswith('tests/'):
            return 'test'
        elif file_path.startswith('hosts/'):
            return 'host'
        else:
            return 'other'

    def generate_report(self):
        """종합 분석 보고서를 생성합니다."""
        print("\n📝 Generating comprehensive analysis report...")

        # 의존성 분석 실행
        flake_deps = self.analyze_flake_dependencies()
        lib_deps = self.analyze_lib_dependencies()
        module_deps = self.analyze_module_dependencies()
        unused_files = self.find_unused_files()
        dependency_graph = self.generate_dependency_graph()

        # 통계 계산
        stats = {
            'total_files': len(self.nix_files),
            'lib_files': len([f for f in self.nix_files if str(f).startswith('lib/')]),
            'module_files': len([f for f in self.nix_files if str(f).startswith('modules/')]),
            'test_files': len([f for f in self.nix_files if str(f).startswith('tests/')]),
            'total_dependencies': sum(len(deps) for deps in self.dependencies.values()),
            'unused_files_count': len(unused_files)
        }

        report = {
            'timestamp': str(Path().resolve()),
            'statistics': stats,
            'flake_dependencies': flake_deps,
            'lib_dependencies': lib_deps,
            'module_dependencies': module_deps,
            'unused_files': unused_files,
            'dependency_graph': dependency_graph,
            'recommendations': self._generate_recommendations(unused_files, stats)
        }

        return report

    def _generate_recommendations(self, unused_files: List[str], stats: Dict) -> List[str]:
        """분석 결과를 바탕으로 권장사항을 생성합니다."""
        recommendations = []

        if len(unused_files) > 0:
            recommendations.append(f"Consider reviewing {len(unused_files)} potentially unused files for removal")

        if stats['total_dependencies'] > stats['total_files'] * 2:
            recommendations.append("High dependency ratio detected - consider modularization")

        lib_ratio = stats['lib_files'] / stats['total_files'] if stats['total_files'] > 0 else 0
        if lib_ratio > 0.3:
            recommendations.append("Large lib/ directory - consider splitting into smaller modules")

        return recommendations

def main():
    if len(sys.argv) > 1:
        repo_path = sys.argv[1]
    else:
        repo_path = os.getcwd()

    print(f"🚀 Starting dependency analysis for: {repo_path}")
    print("=" * 60)

    analyzer = NixDependencyAnalyzer(repo_path)

    # 저장소 스캔
    analyzer.scan_repository()

    # 분석 실행 및 보고서 생성
    report = analyzer.generate_report()

    # 결과 출력
    print("\n" + "=" * 60)
    print("📊 ANALYSIS SUMMARY")
    print("=" * 60)

    stats = report['statistics']
    print(f"📁 Total .nix files: {stats['total_files']}")
    print(f"📚 Library files: {stats['lib_files']}")
    print(f"🧩 Module files: {stats['module_files']}")
    print(f"🧪 Test files: {stats['test_files']}")
    print(f"🔗 Total dependencies: {stats['total_dependencies']}")
    print(f"🗑️  Unused files: {stats['unused_files_count']}")

    print("\n💡 RECOMMENDATIONS:")
    for i, rec in enumerate(report['recommendations'], 1):
        print(f"   {i}. {rec}")

    # 상세 보고서 저장
    output_file = Path(repo_path) / "dependency-analysis-report.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)

    print(f"\n📋 Detailed report saved to: {output_file}")
    print("=" * 60)
    print("✅ Analysis completed successfully!")

if __name__ == "__main__":
    main()
