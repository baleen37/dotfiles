# CLAUDE.md

> **Last Updated:** 2025-07-30
> **Version:** 3.0
> **For:** Claude Code (claude.ai/code)

<constraints>
- ALWAYS adhere to Rule #1: If you want an exception to ANY rule, YOU MUST STOP and get explicit permission from Jito first. BREAKING THE LETTER OR SPIRIT OF THE RULES IS FAILURE.
- **ABSOLUTE PROHIBITION: NO WORKAROUNDS EVER** - NEVER suggest "임시 비활성화", "일단 스킵", "나중에 처리", "temporarily disable", "skip for now", or ANY form of problem avoidance. IF YOU EVEN CONSIDER A WORKAROUND, STOP IMMEDIATELY and ask Jito for guidance.
- **`--no-verify` IS NOT A SOLUTION**: Using `git commit --no-verify` or `git commit -n` is strictly forbidden. It is a dangerous command that bypasses critical quality checks. Instead of using it, you must identify and fix the root cause of the pre-commit hook failure. This is a non-negotiable rule.
</constraints>

## Key File Conventions

- **`GEMINI.md` (Project Root)**: This is the **primary, project-specific** configuration file. It contains rules, context, and instructions tailored to the current project (e.g., Nix workflows, `build-switch` commands, `Jito` as the user). It overrides or extends the generic template.
- **`modules/shared/config/claude/CLAUDE.md`**: This is the **generic, shared template** for agent behavior. It MUST NOT contain project-specific details. It serves as a base for all projects, defining core principles and universal rules.

---
## Core Agent Protocols
---

### **Protocol 1: Context Discovery & Preservation**

**CRITICAL**: 모든 작업의 시작점은 컨텍스트를 파악하는 것입니다. 이 단계의 분석 결과는 이어지는 모든 의사결정의 기반이 됩니다.

#### 1.1. Pre-Task Context Analysis
작업 시작 전 **필수** 수행:
```bash
# 최근 커밋 히스토리 분석 (프로젝트의 변화 방향 파악)
git log --oneline -10

# 관련 파일들의 최근 변경사항 확인 (작업 대상의 히스토리 파악)
git log --follow -p <path/to/relevant/file>

# 기존 패턴과 컨벤션 파악 (일관성 유지를 위한 탐색)
grep -r "similar_pattern" . --include="*.extension"
```

#### 1.2. Convention Adherence
- **아키텍처 패턴 유지**: 새로운 코드를 추가하기 전에, 기존 기능이 어떤 구조(디렉토리, 모듈 분리 등)로 구현되었는지 확인하고 **정확히** 따릅니다.
- **네이밍 컨벤션 준수**: 기존 파일, 함수, 변수명의 네이밍 패턴을 그대로 따릅니다.
- **ADRs (Architecture Decision Records)**: `docs/adr` 디렉토리가 있다면, 주요 아키텍처 결정의 배경을 이해하기 위해 관련 문서를 참조합니다.

---

### **Protocol 2: Scalable Task Execution**

**목표**: 작업의 복잡성에 맞춰 가장 적절한 수준의 프로세스를 적용함으로써, 단순한 작업의 민첩성과 복잡한 작업의 안정성 및 효율성을 모두 달성합니다.

#### 2.1. Stage 1: Triage & Strategy Selection
**Context Discovery** 단계의 분석 결과를 바탕으로, 작업의 복잡도를 평가하여 처리 방식을 결정합니다.

- **단순 작업 (Simple Task)**:
    - **기준**: 단일 파일 수정, 의존성이 없는 명확한 버그 수정 등.
    - **전략**: **Direct Execution Workflow**를 채택합니다.

- **복합 작업 (Complex Task)**:
    - **기준**: 여러 파일에 걸친 변경, 신규 기능 개발, 중요한 리팩토링 등.
    - **전략**: **Multi-Stage Orchestration Protocol**을 채택합니다.

#### 2.2. Stage 2-A: Direct Execution Workflow (For Simple Tasks)
1.  **Plan**: 메인 에이전트가 변경 사항을 직접 계획합니다.
2.  **Execute**: 메인 에이전트가 직접 코드를 수정하거나 명령을 실행합니다.
3.  **Verify**: 메인 에이전트가 직접 테스트를 실행하고 린팅하여 변경 사항을 검증합니다.

#### 2.3. Stage 2-B: Multi-Stage Orchestration Protocol (For Complex Tasks)
**원칙**:
- **Architect, then Code**: 코딩 전에 전체 변경 사항의 구조와 영향을 분석하고 최적의 실행 경로를 설계합니다.
- **Respect Dependencies, Maximize Parallelism**: 작업 간의 선후 관계를 지키면서, 독립적인 작업들은 최대한 동시에 처리합니다.
- **Fail Fast, Recover Gracefully**: 각 작업 단위를 즉시 검증하여 문제를 조기에 발견하고, 실패 시 지능적으로 대응합니다.
- **Specialize Roles**: 하위 에이전트에게 '구현', '테스트', '문서화' 등 명확한 역할을 부여합니다.

**실행 단계**:
1.  **Deconstruction**: 작업을 가장 작은 논리적 단위(Atomic Units of Work)로 분해합니다.
2.  **Dependency Mapping & Planning**: 작업 단위 간의 의존 관계를 분석하여, 순차적으로 실행될 '단계(Stage)'와 각 단계 내에서 병렬로 실행될 작업들을 정의하는 실행 계획을 수립합니다.
3.  **Governed Execution & Verification**:
    - 메인 에이전트가 '오케스트레이터'로서 계획을 단계별로 실행합니다.
    - 각 단계에서는 전문 하위 에이전트를 할당하여 병렬로 작업을 수행합니다.
    - 한 단계가 끝나면 즉시 **중간 검증**을 수행하여 문제를 조기에 발견하고, 실패 시 다음 단계로 넘어가지 않고 문제를 먼저 해결합니다.
4.  **Final Integration & Validation**: 모든 단계가 완료되면, 결과물을 통합하고 시스템 전체의 무결성을 최종 검증합니다.

---

### **Protocol 3: Advanced Debugging & Problem Solving**

이 프로토콜은 실행 중 문제가 발생했을 때, 특히 **Orchestration Protocol**의 '실패 처리' 단계에서 사용됩니다.

#### 3.1. Execution Constraint Assessment
**🚨 CRITICAL**: 명령 실행 전, 특히 시스템 레벨의 명령 실행 전에는 반드시 환경 제약사항을 확인합니다.
- **Sudo/Root Privileges**: 명령이 root 권한을 요구하는가?
- **Interactivity**: 사용자 입력이 필요한 대화식 명령인가?
- **Platform Specifics**: Darwin, Linux 등 플랫폼별 특수성이 있는가?

#### 3.2. Think Hard Protocol for Root Cause Analysis
- **Code-First Analysis**: `nix build`, `nix flake check` 등 실행 가능한 명령이 실패하거나, 권한 문제로 직접 실행이 불가능할 경우, 코드 경로 추적, 설정 파일 분석, 의존성 검토 등 정적 분석을 통해 문제의 근본 원인을 파악합니다.
- **Systematic Investigation**:
    1.  **Understand Architecture**: 문제 지점이 전체 시스템에서 어떤 역할인지 파악합니다.
    2.  **Analyze Dependency Chain**: 실패 지점까지의 모든 구성 요소와 그 관계를 검토합니다.
- **금지사항**: 추측에 기반한 임시방편 제안, 근본 원인 분석 없는 워크어라운드, 불완전한 이해 상태에서의 해결책 제시를 절대 금지합니다.

---
## Project-Specific Notes
---

### Command Design Reflections
- claude/commands 에 command 통합을 대부분 좋지 못하다. 명시적으로 commands를 나누는게 문제가 적다.
  - Command 통합은 시스템의 복잡성을 증가시키고 명확성을 해친다
  - 각 command는 독립적이고 명확한 책임을 가져야 함
  - 통합보다는 모듈화와 명시적 분리가 더 나은 설계 접근법

### Troubleshooting & Prevention
- **Configuration Validation**: 변경사항 적용 전 `./scripts/check-config` 실행
- **Recommended Workflow**:
  ```bash
  # 1. 구성 검증
  ./scripts/check-config
  # 2. build-switch 헬스 체크
  ./scripts/test-build-switch-health
  # 3. 변경사항 적용
  nix run #build-switch
  ```
