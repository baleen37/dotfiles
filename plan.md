# 사용하지 않는 코드 제거 계획 (Dead Code Removal Plan)

## 🎯 목표
dotfiles 리포지토리에서 사용하지 않는 코드, 파일, 구성을 안전하게 제거하여 코드베이스를 정리하고 유지보수성을 향상시킨다.

## 📋 발견된 사용하지 않는 코드

### 1. 확실히 제거 가능한 파일들 (High Confidence)
- **Legacy Error Handling Wrappers** (Dead Code)
  - `lib/error-handler.nix` - `error-system.nix`로 리다이렉트하는 래퍼
  - `lib/error-handling.nix` - `error-system.nix`로 리다이렉트하는 래퍼  
  - `lib/error-messages.nix` - `error-system.nix`로 리다이렉트하는 래퍼

- **Disabled Test Files**
  - `tests/unit/platform-detection-test.nix.disabled` - 명시적으로 비활성화된 테스트

- **Duplicate Configuration Validation Scripts**
  - `scripts/validate-config` (중복)
  - `scripts/utils/validate-config` (중복)
  - `scripts/utils/validate-config.sh` (중복, 하나만 유지)

- **Orphaned Documentation/Plan Files**
  - `main-update.txt` - 임시 업데이트 노트
  - `test-refactoring-plan.md` - 기획 문서
  - `consolidation-report.md` - 생성된 리포트

### 2. 조사 후 제거 검토 대상 (Medium Confidence)
- **tests-new/ 디렉토리** - 불완전한 병렬 테스트 인프라
- **Backup/Refactor Scripts**
  - `scripts/refactor-backup`
  - `scripts/refactor-rollback`
- **중복 가능성 있는 문서**
  - `docs/CONFIGURATION.md` vs `docs/CONFIGURATION-GUIDE.md`

## 🚀 단계별 구현 계획

### Phase 1: 안전한 Dead Code 제거
확실히 사용되지 않는 래퍼 파일들과 비활성화된 파일들을 제거한다.

### Phase 2: 중복 스크립트 통합
동일한 기능을 하는 여러 검증 스크립트를 하나로 통합한다.

### Phase 3: 문서 정리
중복되거나 더 이상 필요하지 않은 문서들을 정리한다.

### Phase 4: 미사용 테스트 인프라 제거
tests-new/ 디렉토리와 같은 미완성 인프라를 제거한다.

### Phase 5: 최종 검증
제거 후 빌드 테스트 및 기능 검증을 수행한다.

---

## 📝 구현 프롬프트 시퀀스

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
