# CLAUDE.md

> **Last Updated:** 2025-07-07
> **Version:** 2.1
> **For:** Claude Code (claude.ai/code)

[... existing content remains unchanged ...]

## Command Design Reflections

- claude/commands 에 command 통합을 대부분 좋지 못하다. 명시적으로 commands를 나누는게 문제가 적다.
  - Command 통합은 시스템의 복잡성을 증가시키고 명확성을 해친다
  - 각 command는 독립적이고 명확한 책임을 가져야 함
  - 통합보다는 모듈화와 명시적 분리가 더 나은 설계 접근법

## Troubleshooting & Prevention

### Common Issues Prevention

1. **Configuration Validation**
   - 변경사항 적용 전 `./scripts/check-config` 실행
   - nix 설정 일관성 및 시스템 파일 충돌 사전 감지

2. **System File Conflicts**
   - build-switch는 이제 자동으로 `/etc/bashrc`, `/etc/zshrc` 백업
   - 원본 파일은 `.before-nix-darwin` 접미사로 보존

3. **Build Configuration Checks**
   - `nix.enable = false`일 때 `nix.gc.automatic = false` 설정 필수
   - 사전 체크 시스템이 이러한 충돌을 감지하고 경고

### Recommended Workflow

```bash
# 1. 구성 검증
./scripts/check-config

# 2. build-switch 헬스 체크 (Issue #367 방지)
./scripts/test-build-switch-health

# 3. 변경사항 적용
nix run #build-switch

# 4. 문제 발생 시 상세 로그 확인
nix run #build-switch --verbose
```

### Testing Build-Switch Reliability

Issue #367에서 발생한 문제들을 방지하기 위한 테스트 시스템:

```bash
# 1. 단위 테스트: Claude Code 환경 특화 테스트
nix build .#checks.aarch64-darwin.build_switch_claude_code_environment_test

# 2. 통합 테스트: 전체 워크플로우 검증
nix build .#checks.aarch64-darwin.build_switch_workflow_integration_test

# 3. 헬스 체크: 실시간 상태 모니터링
./scripts/test-build-switch-health
```

## Claude Code Limitations & Workarounds

### System-Level Operations & Privilege Management

Claude Code는 비대화식 환경에서 실행되므로 특별한 권한 처리 전략이 필요합니다.

#### Root Privilege Requirements

**Darwin/macOS 특별 요구사항:**
- `darwin-rebuild switch`는 **항상** root 권한이 필요함
- `nix run #build-switch` 실행 시 시스템 활성화 단계에서 sudo 필요
- 비대화식 환경에서도 passwordless sudo 시도 또는 사용자 수동 실행 필요

**Claude의 제약사항:**
- 대화식 sudo 명령 실행 불가능
- 패스워드 프롬프트 처리 불가능
- 시스템 레벨 명령 직접 실행 제한

#### 권한 문제 해결 전략

**1. 코드 분석 우선 접근법**
```bash
# 빌드 단계 오류 확인
nix build .#darwinConfigurations.aarch64-darwin.system --show-trace

# 설정 검증
nix flake check --show-trace

# 스크립트 로직 분석
# sudo 관리 로직, 실행 경로, 권한 요구사항 추적
```

**2. 단계별 진단 프로세스**
- **Phase 1**: 빌드 vs 스위치 단계 분리 확인
- **Phase 2**: sudo 요구사항 및 관리 로직 분석
- **Phase 3**: 플랫폼별 특수 요구사항 식별
- **Phase 4**: 사용자 수동 실행 가이드 제공

**3. 사용자 가이드 전략**
- 명확한 수동 실행 지침 제공
- 오류 예측 및 해결 방법 제시
- 대안적 접근법 (비특권 진단 도구 활용)

### Debugging in Constrained Environments

Claude는 시스템 명령 실행 제약이 있으므로 특별한 디버깅 전략이 필요합니다.

#### Phase 0: Environment Assessment
**실행 제약 사항 식별**
- sudo 권한 필요 여부 확인
- 대화식 vs 비대화식 환경 구분
- 플랫폼별 특수 요구사항 파악

#### Enhanced Root Cause Investigation
**코드 분석 우선 접근법**
- 직접 실행이 불가능한 경우 코드 경로 추적
- 설정 파일 및 스크립트 로직 분석
- 로그 파일 및 오류 메시지 패턴 분석

**실행 제약 하에서의 가설 형성**
- 코드 분석을 통한 논리적 추론
- 유사한 패턴 및 기존 구현 참조
- 플랫폼별 문서 및 요구사항 검토

#### Alternative Diagnostic Approaches
**비특권 진단 도구**
- `nix flake check` - 설정 검증
- `nix build` - 빌드 단계 분리 테스트
- 스크립트 로직 정적 분석
- 설정 파일 구문 검사

### macOS System Configuration Limitations

#### nix-darwin 특수 요구사항
- `system.defaults`에서 직접 지원하지 않는 설정들
- 시스템 활성화 스크립트 권한 요구사항
- 플랫폼별 plist 파일 직접 수정 필요성

**예시: Advanced System Settings**
```nix
# com.apple.HIToolbox.AppleSymbolicHotKeys 등
system.activationScripts.customSettings = {
  text = ''
    # Python 스크립트를 통한 plist 직접 수정
    ${pkgs.python3}/bin/python3 ${./scripts/configure-hotkeys.py}
  '';
};
```

#### 권한 및 시스템 통합 고려사항
- 빌드 시점 vs 런타임 설정 적용
- 시스템 무결성 보호(SIP) 제약사항
- 사용자 세션 vs 시스템 전역 설정

## Project Context & History Preservation

### Context Discovery Protocol

**CRITICAL**: 프로젝트가 커질수록 agent는 기존 히스토리와 컨벤션을 놓치기 쉽습니다. 다음 프로토콜을 **반드시** 따르세요:

#### 1. Pre-Task Context Analysis
작업 시작 전 **필수** 수행:
```bash
# 최근 커밋 히스토리 분석
git log --oneline -10

# 관련 파일들의 최근 변경사항 확인
git log --follow -p <관련파일경로>

# 기존 패턴과 컨벤션 파악
grep -r "similar_pattern" . --include="*.extension"
```

#### 2. Convention Discovery Process
- **기존 파일 구조 분석**: 새로운 기능 추가 전 유사한 기능이 어떻게 구현되었는지 확인
- **네이밍 컨벤션 준수**: 기존 파일, 함수, 변수명 패턴을 **정확히** 따름
- **아키텍처 패턴 유지**: 기존 디렉토리 구조와 모듈 분리 방식 준수

#### 3. Breaking Changes Prevention
- **하위 호환성 확인**: 기존 설정이나 스크립트가 깨지지 않는지 사전 검증
- **의존성 영향 분석**: 변경사항이 다른 모듈에 미치는 영향 사전 파악
- **테스트 실행**: 변경 전후 기존 기능이 정상 작동하는지 확인

#### 4. Historical Context Questions
작업 전 스스로에게 질문:
- "이 기능과 유사한 것이 이미 구현되어 있는가?"
- "기존 컨벤션에서 벗어나는 부분은 없는가?"
- "이 변경이 기존 워크플로우를 깨뜨리지 않는가?"
- "과거 이슈나 PR에서 비슷한 논의가 있었는가?"

#### 5. Documentation-First Approach
- **변경 사유 문서화**: 왜 이런 방식으로 구현했는지 명확히 기록
- **마이그레이션 가이드**: 기존 사용자가 새로운 구조로 전환할 방법 제공
- **컨벤션 업데이트**: 새로운 패턴이 생겼다면 이 문서에 반영

### Agent Handoff Protocol

새로운 agent나 세션에서 프로젝트를 이어받을 때:

1. **CLAUDE.md 전체 읽기** (이 파일)
2. **최근 10개 커밋 메시지 분석**
3. **활성 이슈와 PR 확인**
4. **핵심 설정 파일들 스캔** (package.json, flake.nix, 등)
5. **테스트 실행하여 현재 상태 확인**

### Project Scale Management

#### Large Project Context Strategies
- **모듈별 CONTEXT.md**: 각 주요 모듈에 컨텍스트 파일 유지
- **변경 로그 자동화**: 중요한 아키텍처 변경사항 자동 기록
- **컨벤션 체크리스트**: 새로운 기능 추가 시 확인할 항목들

#### Memory Aids for Agents
- **패턴 레지스트리**: 자주 사용되는 패턴들을 명시적으로 문서화
- **의존성 맵**: 모듈 간 의존 관계 시각화
- **히스토리컬 노트**: 과거 결정사항과 그 이유 기록

### Advanced Strategies for Context Preservation

#### 1. Architecture Decision Records (ADRs)
- **목표**: 중요한 아키텍처 결정과 그 배경, 대안, 결과를 명시적으로 기록하여 미래의 에이전트나 개발자가 결정의 맥락을 이해하도록 돕습니다.
- **구현**: `docs/adr` 디렉토리에 마크다운 파일로 각 ADR을 작성합니다.
  - 예시: `docs/adr/0001-use-nix-flakes-for-dependency-management.md`
- **활용**: 새로운 기능 개발 또는 기존 시스템 변경 시 관련 ADR을 참조하여 일관성을 유지합니다.

#### 2. Automated Convention Enforcement
- **목표**: 코드 스타일, 네이밍 컨벤션, 아키텍처 패턴 등을 CI/CD 파이프라인에서 자동으로 검사하고 강제하여 일관성을 유지합니다.
- **구현**: `pre-commit` 훅, 린터(예: `nixpkgs-fmt`, `markdownlint`), 정적 분석 도구(예: `statix`)를 활용합니다.
- **활용**: 에이전트는 변경사항을 커밋하기 전에 이러한 도구를 실행하여 컨벤션 준수 여부를 확인합니다.

#### 3. Context-Aware Prompt Injection
- **목표**: 에이전트에게 작업을 지시할 때, 관련 컨텍스트 정보(예: 관련 파일 내용, 최근 변경 사항 요약, 특정 컨벤션 가이드라인)를 프롬프트에 동적으로 주입하여 에이전트가 더 정확하고 컨텍스트에 맞는 응답을 생성하도록 돕습니다.
- **구현**: 에이전트 호출 스크립트에서 작업 유형에 따라 필요한 정보를 자동으로 수집하여 프롬프트에 추가합니다.
- **활용**: 에이전트는 주어진 컨텍스트를 바탕으로 작업을 수행하며, 불필요한 정보 탐색 시간을 줄입니다.

#### 4. Test-Plan-Verify (TPV) Development Cycle
- **목표**: 에이전트가 변경사항을 적용하기 전에 명확한 계획을 수립하고, 변경 후에는 철저한 검증 과정을 거치도록 하여 안정성과 컨벤션 준수를 보장합니다.
- **구현**:
  1. **Test**: 기존 테스트를 실행하여 현재 상태를 확인하고, 필요한 경우 새로운 테스트 케이스를 작성합니다.
  2. **Plan**: 변경 계획을 상세히 수립하고, 예상되는 영향과 컨벤션 준수 방안을 명시합니다.
  3. **Verify**: 변경 적용 후 모든 테스트를 다시 실행하고, 린터, 타입 체커 등 프로젝트의 품질 검사 도구를 실행하여 문제가 없는지 확인합니다.
- **활용**: 에이전트는 이 사이클을 반복하며 점진적으로 변경사항을 적용하고 검증하여 오류 발생 가능성을 최소화합니다.

## Claude-Specific Debugging Enhancement

### 실행 제약 환경에서의 디버깅 전략

Claude Code의 실행 제약을 고려한 강화된 디버깅 프로세스:

#### Phase 0: Execution Constraint Assessment
**🚨 CRITICAL**: 실행 전 환경 제약사항 반드시 확인
- **sudo 권한 요구사항**: 명령이 root 권한이 필요한가?
- **대화식 환경 필요성**: 사용자 입력이나 프롬프트가 필요한가?
- **플랫폼별 특수 요구사항**: Darwin vs Linux 등 플랫폼 특화 제약사항

#### Enhanced Investigation Strategies

**Code-First Analysis (실행 불가 시)**
```bash
# 1. 정적 분석을 통한 문제 파악
# - 스크립트 로직 추적
# - 설정 파일 검증
# - 의존성 및 경로 확인

# 2. 로그 및 오류 메시지 패턴 분석
# - 기존 실행 결과 분석
# - 알려진 오류 패턴 매칭
# - 공식 문서 및 이슈 트래킹

# 3. 대안적 진단 도구 활용
nix flake check --show-trace
nix build .#target --show-trace
./scripts/check-config
```

**Think Hard Protocol for Complex Issues**
1. **코드 경로 완전 추적**: 실행 흐름을 처음부터 끝까지 정적 분석
2. **조건문 및 분기 분석**: 환경에 따른 다른 실행 경로 확인
3. **의존성 체인 분석**: 실패 지점까지의 모든 의존성 검토
4. **유사 사례 패턴 매칭**: 과거 유사한 문제 해결 방법 참조

#### User Guidance Strategy

**명확한 수동 실행 지침**
- 실행할 정확한 명령어 제공
- 예상되는 오류 및 해결 방법 사전 설명
- 대안적 접근 방법 제시

**오류 예측 및 해결 방법**
- 일반적인 실패 시나리오 사전 식별
- 각 시나리오별 구체적 해결책 제공
- 트러블슈팅 단계별 가이드

### Think Hard Mandate for System-Level Issues

**ABSOLUTE REQUIREMENT**: 시스템 레벨 문제 발생 시 반드시 Think Hard 적용

1. **전체 시스템 아키텍처 이해**: 문제 지점이 전체 시스템에서 어떤 역할인지 파악
2. **의존성 체인 완전 분석**: 실패 지점까지의 모든 구성 요소 검토
3. **플랫폼별 특수성 고려**: Darwin, Linux 등 플랫폼 특화 요구사항 반영
4. **코드 분석을 통한 논리적 추론**: 실행 불가 시 정적 분석으로 원인 파악

**금지사항**:
- 추측에 기반한 임시방편 제안 금지
- 근본 원인 분석 없는 워크어라운드 금지
- 불완전한 이해 상태에서의 해결책 제시 금지

---

## Critical Execution Constraints Reminder

**🚨 CLAUDE CODE 실행 환경 제약사항 - 반드시 숙지**

### 환경 제약사항
- **비대화식 환경**: sudo 패스워드 프롬프트 처리 불가
- **Darwin 시스템**: `darwin-rebuild switch` 항상 root 권한 필요
- **시스템 명령 실행 제한**: 권한이 필요한 시스템 레벨 명령 직접 실행 불가

### 대응 전략
- **시스템 레벨 실패 시**: 코드 분석으로 원인 파악 후 사용자 가이드 제공
- **Think Hard 의무 적용**: 복잡한 시스템 문제는 반드시 완전한 분석 후 해결책 제시
- **단계별 진단**: 빌드 vs 스위치 단계 분리, sudo 요구사항 분석, 플랫폼별 특수사항 고려

### 성공 사례 패턴
오늘의 `build-switch` 문제 해결 과정이 모범 사례:
1. **실행 실패 → 코드 분석으로 전환**
2. **sudo 관리 로직 완전 추적**
3. **비대화식 환경 처리 로직 식별**
4. **근본 원인 (SUDO_REQUIRED=false) 발견**
5. **정확한 수정 (플랫폼별 조건 추가) 적용**
