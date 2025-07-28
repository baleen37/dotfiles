# Dead Code 제거 계획서

## 프로젝트 개요
- **대상**: Nix 기반 dotfiles 시스템 (115개 .nix 파일, 21,400 라인)
- **목표**: 사용되지 않는 코드, 함수, 모듈, 파일을 체계적으로 식별하고 제거
- **범위**: Nix 파일, 쉘 스크립트, Python 파일, 설정 파일 포함

## 1단계: 분석 및 준비 (Analysis & Preparation)

### 1.1 코드베이스 의존성 매핑
```
현재 프로젝트의 import/include 관계를 분석하여 의존성 그래프를 생성합니다.
- flake.nix에서 시작하는 의존성 트리 구축
- modules/ 디렉토리의 상호 참조 관계 파악  
- lib/ 디렉토리 함수들의 사용 현황 조사
```

### 1.2 진입점 식별
```
시스템에서 실제로 사용되는 진입점들을 식별합니다.
- flake.nix의 outputs 분석
- 각 플랫폼별 default.nix 파일들 확인
- 빌드 스크립트들이 참조하는 모듈들 확인
```

### 1.3 정적 분석 도구 설정
```
Nix 생태계의 정적 분석 도구들을 활용하여 dead code를 감지합니다.
- nix-tree를 사용한 의존성 시각화
- nixpkgs-review를 통한 사용되지 않는 패키지 식별
- 커스텀 grep 패턴을 통한 참조 검색
```

## 2단계: Dead Code 검출 (Detection)

### 2.1 사용되지 않는 Nix 함수 검출
```
lib/ 디렉토리의 각 함수가 실제로 참조되고 있는지 확인합니다.
- 각 .nix 파일에서 정의된 함수들의 사용 여부 검사
- 테스트에서만 사용되는 함수와 실제 사용되는 함수 구분
- 중복 정의된 함수들 식별
```

### 2.2 사용되지 않는 모듈 검출  
```
modules/ 디렉토리의 각 모듈이 실제로 import되고 있는지 확인합니다.
- home-manager.nix 파일들에서 import되지 않는 모듈들 식별
- platform-specific 모듈들의 실제 사용 여부 확인
- deprecated된 모듈들 식별
```

### 2.3 사용되지 않는 스크립트 및 설정 파일 검출
```
scripts/ 및 config/ 디렉토리의 파일들이 실제로 사용되고 있는지 확인합니다.
- 쉘 스크립트들의 실행 경로 추적
- 설정 파일들의 참조 여부 확인
- 테스트 파일들 중 obsolete한 것들 식별
```

### 2.4 중복 코드 검출
```
동일하거나 유사한 기능을 하는 중복 코드들을 식별합니다.
- 비슷한 함수 구현들 식별
- 중복된 패키지 정의들 확인
- 유사한 설정 패턴들 통합 기회 식별
```

## 3단계: 검증 및 분류 (Validation & Classification)

### 3.1 False Positive 필터링
```
실제로는 사용되지만 정적 분석으로는 감지되지 않는 경우들을 걸러냅니다.
- 동적으로 import되는 모듈들 확인
- 문자열로 참조되는 함수들 확인  
- 조건부로만 사용되는 코드들 확인
```

### 3.2 제거 우선순위 설정
```
검출된 dead code들을 제거 위험도에 따라 분류합니다.
- 안전하게 제거 가능한 코드 (High Priority)
- 주의깊게 제거해야 하는 코드 (Medium Priority)  
- 추가 조사가 필요한 코드 (Low Priority)
```

### 3.3 영향도 분석
```
각 코드 제거가 시스템에 미칠 영향을 분석합니다.
- 빌드 프로세스에 미치는 영향
- 테스트 커버리지에 미치는 영향
- 기존 사용자 워크플로우에 미치는 영향
```

## 4단계: 점진적 제거 (Incremental Removal)

### 4.1 안전한 코드부터 제거
```
가장 위험도가 낮은 코드들부터 순차적으로 제거합니다.
- 명확히 사용되지 않는 utility 함수들
- 더 이상 지원하지 않는 legacy 코드들
- 주석 처리된 코드 블록들
```

### 4.2 모듈 단위 제거
```
개별 파일이나 모듈 전체를 제거할 수 있는 경우들을 처리합니다.
- 완전히 사용되지 않는 .nix 파일들
- deprecated된 스크립트들
- 오래된 설정 파일들
```

### 4.3 리팩토링을 통한 중복 제거
```
중복 코드들을 통합하여 코드베이스를 정리합니다.
- 유사한 함수들을 하나로 통합
- 공통 패턴들을 lib 함수로 추출
- 중복된 설정들을 공통 모듈로 통합
```

## 5단계: 검증 및 테스트 (Verification & Testing)

### 5.1 빌드 테스트
```
각 제거 단계 후에 시스템이 정상적으로 빌드되는지 확인합니다.
- nix build 명령어로 전체 시스템 빌드 테스트
- 각 플랫폼별 빌드 테스트 (darwin, nixos)
- 에러 발생 시 즉시 롤백
```

### 5.2 기능 테스트  
```
제거된 코드가 실제 기능에 영향을 주지 않는지 확인합니다.
- 기존 테스트 스위트 실행
- 수동 기능 테스트 수행
- 설정 파일들이 올바르게 적용되는지 확인
```

### 5.3 회귀 테스트
```
dead code 제거로 인한 예상치 못한 부작용이 없는지 확인합니다.
- 전체 dotfiles 시스템 재배포 테스트
- 각종 도구들의 정상 작동 확인
- 사용자 워크플로우 검증
```

## 6단계: 문서화 및 마무리 (Documentation & Cleanup)

### 6.1 변경사항 문서화
```
제거된 코드들과 그 이유를 문서화합니다.
- CHANGELOG.md 업데이트
- 중요한 변경사항들에 대한 migration guide 작성
- 제거된 기능들에 대한 대안 제시
```

### 6.2 코드 정리
```
남은 코드들의 품질을 개선합니다.
- import 문들 정리
- 사용되지 않는 변수들 제거  
- 코드 포매팅 통일
```

### 6.3 최종 검증
```
전체 과정을 거쳐 정리된 코드베이스의 최종 점검을 수행합니다.
- 전체 시스템 통합 테스트
- 성능 개선 효과 측정
- 코드 복잡도 감소 효과 확인
```

## 실행을 위한 구체적인 프롬프트들

각 단계는 다음과 같은 세부 프롬프트들로 구성됩니다:

### Stage 1 프롬프트들

#### 1.1 의존성 매핑
```
flake.nix 파일을 분석하여 모든 imports와 outputs를 매핑하고,
각 모듈이 어떤 다른 모듈들을 참조하는지 의존성 그래프를 생성해주세요.
lib/ 디렉토리의 모든 함수들이 어디서 사용되는지도 함께 조사해주세요.
```

#### 1.2 진입점 식별  
```
dotfiles 시스템의 모든 진입점을 식별해주세요.
flake.nix의 outputs, 각 플랫폼의 default.nix, 그리고 빌드 스크립트들이
실제로 사용하는 모듈들의 목록을 만들어주세요.
```

#### 1.3 정적 분석 도구 설정
```
Nix 코드베이스에서 dead code를 검출하기 위한 분석 스크립트를 작성해주세요.
grep과 find를 활용하여 각 함수와 모듈의 참조 횟수를 계산하는 도구를 만들어주세요.
```

### Stage 2 프롬프트들

#### 2.1 사용되지 않는 함수 검출
```
lib/ 디렉토리의 모든 .nix 파일을 스캔하여 정의된 함수들의 목록을 만들고,
각 함수가 코드베이스에서 몇 번 참조되는지 계산해주세요.
0번 참조되는 함수들을 dead code 후보로 분류해주세요.
```

#### 2.2 사용되지 않는 모듈 검출
```
modules/ 디렉토리의 모든 .nix 파일들이 실제로 import되고 있는지 확인해주세요.
home-manager.nix 파일들과 default.nix 파일들에서 import되지 않는 모듈들을 찾아주세요.
```

#### 2.3 스크립트 및 설정 파일 검증
```
scripts/ 디렉토리의 모든 파일들이 실제로 실행되거나 참조되고 있는지 확인해주세요.
config/ 디렉토리의 설정 파일들이 어떤 모듈에서 사용되는지 추적해주세요.
```

#### 2.4 중복 코드 검출
```
코드베이스에서 유사하거나 중복된 구현을 찾아주세요.
특히 비슷한 기능을 하는 함수들이나 거의 동일한 설정 블록들을 식별해주세요.
```

### Stage 3 프롬프트들

#### 3.1 False Positive 필터링
```
앞서 식별된 dead code 후보들 중에서 실제로는 사용되지만
정적 분석으로는 감지되지 않는 경우들을 찾아주세요.
동적 import나 문자열 참조 등의 경우를 확인해주세요.
```

#### 3.2 우선순위 설정
```
검출된 dead code들을 안전성에 따라 3단계로 분류해주세요:
1. 즉시 제거 가능 (안전함)
2. 주의깊게 제거 (테스트 필요)  
3. 추가 조사 필요 (위험할 수 있음)
```

#### 3.3 영향도 분석
```
각 dead code 제거가 시스템에 미칠 수 있는 영향을 분석해주세요.
빌드 프로세스, 테스트, 사용자 워크플로우에 대한 영향을 평가해주세요.
```

### Stage 4 프롬프트들

#### 4.1 안전한 코드 제거
```
가장 안전한 등급으로 분류된 dead code들을 제거해주세요.
각 제거 후에는 `nix flake check`를 실행하여 빌드가 성공하는지 확인해주세요.
```

#### 4.2 모듈 단위 제거
```
완전히 사용되지 않는 .nix 파일들을 식별하고 제거해주세요.
제거 전에 해당 파일이 정말로 어디서도 참조되지 않는지 재확인해주세요.
```

#### 4.3 중복 코드 통합
```
중복된 코드들을 하나로 통합하여 유지보수성을 개선해주세요.
공통 패턴들을 lib 함수로 추출하고 기존 사용처들을 업데이트해주세요.
```

### Stage 5 프롬프트들

#### 5.1 빌드 테스트
```
각 플랫폼별로 전체 시스템 빌드를 테스트해주세요:
- `nix build .#darwinConfigurations.default.system`
- `nix build .#nixosConfigurations.default.config.system.build.toplevel`
에러가 발생하면 즉시 해당 변경사항을 롤백해주세요.
```

#### 5.2 기능 테스트
```
기존 테스트 스위트를 실행하여 모든 테스트가 통과하는지 확인해주세요.
`nix build .#tests.default`를 실행하고 결과를 검토해주세요.
```

#### 5.3 회귀 테스트  
```
전체 dotfiles 시스템을 새로 배포해보고 모든 기능이 정상 작동하는지 확인해주세요.
특히 중요한 도구들(zsh, 에디터, 터미널 등)이 올바르게 설정되는지 검증해주세요.
```

### Stage 6 프롬프트들

#### 6.1 변경사항 문서화
```
제거된 모든 dead code들과 그 이유를 문서화해주세요.
사용자가 알아야 할 중요한 변경사항이 있다면 migration guide를 작성해주세요.
```

#### 6.2 코드 정리
```
남은 코드들의 품질을 개선해주세요:
- 불필요한 import 문들 제거
- 사용되지 않는 변수들 정리
- 일관된 코드 포매팅 적용
```

#### 6.3 최종 검증
```
전체 과정을 완료한 후 최종 통합 테스트를 수행해주세요.
코드베이스의 크기가 얼마나 줄어들었는지,
빌드 시간이 개선되었는지 측정해주세요.
```

## 예상 결과

이 계획을 통해 다음과 같은 개선을 기대할 수 있습니다:

- **코드베이스 크기 감소**: 10-20% 예상
- **빌드 시간 단축**: 5-15% 예상  
- **유지보수성 향상**: 중복 코드 제거로 인한 개선
- **복잡도 감소**: 불필요한 의존성 제거

## 위험 요소 및 대응책

- **실수로 필요한 코드 제거**: 각 단계마다 철저한 테스트와 백업
- **빌드 실패**: 즉시 롤백할 수 있는 Git 워크플로우 유지
- **기능 회귀**: 포괄적인 테스트 스위트 실행

각 단계는 독립적으로 실행 가능하며, 문제 발생 시 언제든 중단하고 롤백할 수 있도록 설계되었습니다.

---

## 📝 기존 발견사항 기반 프롬프트들

### Prompt 1: Legacy Error Handling Wrapper 제거
```
Remove the legacy error handling wrapper files that are confirmed dead code:
- lib/error-handler.nix
- lib/error-handling.nix  
- lib/error-messages.nix

These files are explicitly marked as legacy compatibility wrappers that redirect to error-system.nix. Verify they are not imported anywhere before removing them.
```

### Prompt 2: Disabled Test Files 제거
```
Remove the disabled test file:
- tests/unit/platform-detection-test.nix.disabled

This file is explicitly disabled and superseded by the consolidated test system. Verify it's not referenced anywhere before removal.
```

### Prompt 3: 중복 Configuration Validation Scripts 통합
```
Consolidate the duplicate configuration validation scripts:
- scripts/validate-config
- scripts/utils/validate-config
- scripts/utils/validate-config.sh

Keep the most comprehensive version and update any references to point to the consolidated script. Remove the duplicate files.
```

### Prompt 4: Orphaned Documentation Files 제거
```
Remove orphaned documentation and plan files:
- main-update.txt
- test-refactoring-plan.md
- consolidation-report.md

Verify these files are not referenced in any scripts or documentation before removal.
```

### Prompt 5: tests-new/ 디렉토리 평가
```
Evaluate the tests-new/ directory for removal. Check if:
1. It's referenced by any build scripts or configurations
2. It contains functionality not present in tests-consolidated/
3. It's actively being developed

If it's truly unused, remove the entire directory.
```

### Prompt 6: Backup/Refactor Scripts 평가
```
Evaluate the backup and refactor scripts for necessity:
- scripts/refactor-backup
- scripts/refactor-rollback

Determine if these are still needed for maintenance operations or if they're leftover from a completed refactoring process.
```

### Prompt 7: 중복 문서 검토
```
Review and consolidate duplicate documentation:
- docs/CONFIGURATION.md vs docs/CONFIGURATION-GUIDE.md

Determine which provides better coverage and consolidate information if needed. Remove the redundant file.
```

### Prompt 8: 최종 검증 및 테스트
```
After all removals:
1. Run the build system to ensure nothing broke
2. Execute the test suite
3. Verify all scripts still function correctly
4. Check that no broken imports or references remain
5. Update any documentation that referenced removed files
```

## ⚠️ 주의사항

1. **점진적 제거**: 한 번에 모든 파일을 제거하지 말고 단계별로 진행
2. **참조 확인**: 각 파일 제거 전 다른 파일에서의 참조 여부 확인
3. **백업**: 제거 전 현재 상태를 git으로 커밋
4. **테스트**: 각 단계 후 빌드 및 기능 테스트 실행
5. **문서 업데이트**: 제거된 파일들을 참조하는 문서가 있다면 업데이트

## 📊 예상 결과

- **제거 예상 파일 수**: 10-15개
- **코드베이스 정리**: Legacy wrapper 제거로 명확성 향상  
- **유지보수성**: 중복 제거로 혼란 감소
- **저장소 크기**: 미사용 파일 제거로 소폭 감소
