# 코드베이스 의존성 매핑 보고서

**생성일**: 2025-07-28  
**분석 대상**: /Users/jito/dev/dotfiles  
**분석 도구**: 개선된 Nix 의존성 분석기

## 📊 요약 통계

- **총 .nix 파일**: 115개
- **실제 사용 중인 파일**: 29개 (25.2%)
- **미사용 파일**: 86개 (74.8%)
- **최대 의존성 깊이**: 3단계
- **의존성 순환**: 1개 발견

### 카테고리별 파일 분포

| 카테고리 | 총 파일 수 | 사용 중 | 미사용 |
|----------|------------|---------|--------|
| Library (lib/) | 24 | 13 | 11 |
| Modules (modules/) | 21 | 13 | 8 |
| Tests (tests/) | 29 | 0 | 29 |
| Hosts (hosts/) | 2 | 2 | 0 |
| 기타 | 39 | 1 | 36 |

## 🔗 의존성 구조 분석

### 진입점 (Entry Points)
1. `flake.nix` - 메인 flake 설정
2. `hosts/darwin/default.nix` - macOS 호스트 설정  
3. `hosts/nixos/default.nix` - NixOS 호스트 설정

### 핵심 사용 중인 파일들

#### Library 파일들 (lib/)
```
✅ 사용 중:
- flake-config.nix        (flake 설정)
- system-configs.nix      (시스템 설정 빌더)
- check-builders.nix      (테스트 빌더)
- platform-apps.nix      (플랫폼별 앱)
- test-apps.nix           (테스트 앱)
- user-resolution.nix     (사용자 해석)
- utils-system.nix        (시스템 유틸리티)
- platform-system.nix     (플랫폼 시스템)
- error-system.nix        (에러 처리)
- test-system.nix         (테스트 시스템)
- platform-utils.nix      (플랫폼 유틸리티)
- package-utils.nix       (패키지 유틸리티)
- keyboard-input-settings.nix (키보드 설정)

❌ 미사용:
- auto-update-*.nix       (자동 업데이트 관련)
- consolidation-engine.nix (통합 엔진)
- template-*.nix          (템플릿 시스템)
- performance-config.nix  (성능 설정)
- common-utils.nix        (공통 유틸리티)
```

#### Module 파일들 (modules/)
```
✅ 사용 중:
Darwin:
- app-links.nix, casks.nix, files.nix
- home-manager.nix, packages.nix

NixOS:
- disk-config.nix, files.nix
- home-manager.nix, packages.nix

Shared:
- files.nix, home-manager.nix, packages.nix
- lib/claude-activation.nix

❌ 미사용:
- dock/default.nix (dock 설정)
- shared/default.nix (공유 기본값)
- shared/lib의 일부 파일들
```

## 🗑️ Dead Code 분석 결과

### 제거 가능한 파일 분류

#### 🟢 안전하게 제거 가능 (43개 파일)
- **tests-consolidated/** 디렉토리 전체 (29개 파일)
- **lib/auto-update-*** 시리즈 (3개 파일)
- **lib/existing-tests.nix**
- **lib/template-engine.nix**
- **lib/template-system.nix**
- 기타 백업 및 임시 파일들

#### 🟡 검토 필요 (34개 파일)
- **lib/common-utils.nix** - 공통 유틸리티
- **lib/consolidation-engine.nix** - 통합 엔진
- **lib/platform-detector.nix** - 플랫폼 감지
- **tests/** 디렉토리의 일부 파일들
- **scripts/** 디렉토리의 .nix 파일들

#### 🔴 False Positive 가능성 (9개 파일)
- **modules/shared/default.nix** - 공유 모듈 기본값
- **modules/darwin/dock/default.nix** - Dock 설정
- **overlays/** 파일들
- **lib/performance-config.nix** - 성능 설정

## 🔄 발견된 의존성 순환

**순환 1**: `lib/auto-update-prompt.nix` → `lib/auto-update-prompt.nix`
- 자기 자신을 참조하는 순환 (제거 대상에 포함됨)

## 📈 예상 개선 효과

### 파일 수 감소
- **현재**: 115개 .nix 파일
- **1단계 제거 후**: ~105개 파일 (10개 제거)
- **전체 제거 후**: ~29개 파일 (86개 제거)
- **감소율**: 최대 74.8%

### 빌드 시간 개선
- 불필요한 파일 검사 시간 단축
- 의존성 해석 시간 감소
- 예상 개선: 5-15%

### 유지보수성 향상
- 코드베이스 복잡도 대폭 감소
- 핵심 기능에 집중 가능
- 신규 개발자 온보딩 시간 단축

## 💡 권장 실행 계획

### 1단계: 안전한 제거 (위험도: 낮음)
```bash
# 백업 생성
python3 scripts/detect-dead-code.py

# 안전한 파일들 제거
./remove-dead-code.sh

# 빌드 검증
nix flake check
```

### 2단계: 검토 후 제거 (위험도: 중간)
1. `lib/common-utils.nix` 등 검토 필요 파일들 개별 분석
2. 실제 사용 여부 수동 확인
3. 단계적 제거 및 테스트

### 3단계: 수동 검증 (위험도: 높음)
1. `modules/shared/default.nix` 등 중요 파일들 신중히 검토
2. 숨겨진 참조나 런타임 로딩 확인
3. 충분한 테스트 후 제거 결정

## 🔧 생성된 도구들

1. **analyze-dependencies-improved.py** - 개선된 의존성 분석기
2. **detect-dead-code.py** - Dead code 검출 및 분류 도구
3. **remove-dead-code.sh** - 안전한 제거 스크립트
4. **dependency-analysis-report.json** - 상세 분석 결과
5. **dead-code-removal-plan.json** - 제거 계획

## ✅ 다음 단계

1. ✅ **의존성 매핑 완료**
2. 🔄 **1단계 안전한 제거 실행** (todo.md 업데이트 대기)
3. ⏳ **빌드 검증 및 테스트**
4. ⏳ **2단계 검토 후 제거**
5. ⏳ **최종 검증 및 문서화**

---

*이 보고서는 자동 생성된 분석 결과를 바탕으로 작성되었습니다. 실제 제거 전 반드시 수동 검토를 수행하시기 바랍니다.*
