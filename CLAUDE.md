# CLAUDE.md

> **Last Updated:** 2025-01-06
> **Version:** 2.0
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

# 2. 변경사항 적용
nix run #build-switch

# 3. 문제 발생 시 상세 로그 확인
nix run #build-switch --verbose
```

## Claude Code Limitations & Workarounds

### Root Privilege Requirements

`nix run #build-switch` 실행 시 root 권한이 필요하지만 Claude에서는 sudo 명령을 실행할 수 없음.

**해결 방법:**
1. **코드 분석을 통한 추측**: 빌드 오류 시 `nix build .#darwinConfigurations.aarch64-darwin.system` 명령으로 구체적인 오류 파악
2. **설정 검증**: nix 평가 단계에서 오류 확인 가능
3. **사용자 직접 실행**: Claude가 수정한 코드는 사용자가 직접 테스트 필요

### macOS System Configuration Limitations

nix-darwin에서 일부 macOS 시스템 설정은 `system.defaults`에서 직접 지원하지 않음.
예: `com.apple.HIToolbox.AppleSymbolicHotKeys`

**해결 방법:**
- `system.activationScripts`를 사용하여 Python 스크립트로 plist 파일 직접 수정
- 빌드 시점에 설정 적용되도록 구현

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
