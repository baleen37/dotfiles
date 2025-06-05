# AGENTS Guide

이 저장소는 **Codex agent**를 활용해 자동화된 작업을 수행합니다. 아래 가이드라인은 agent나 기여자가 참고할 수 있는 기본 규칙을 정리한 것입니다.

## Agent 역할
- PR 생성 및 병합
- Nix flake 환경의 테스트 실행
- 문서 갱신

## 기본 원칙
1. **테스트 실행**: Nix 관련 파일을 수정하면 GitHub Actions에서 수행하는 테스트와 동일한 절차를 로컬에서도 실행합니다. 자세한 단계는 아래 "GitHub CI 테스트" 절을 참고하세요.
2. **문서 업데이트**: 주요 설정이나 구조가 바뀌면 반드시 README.md와 관련 문서를 최신 상태로 갱신합니다.
3. **커밋 규칙**: 의미 있는 단위로 커밋하며 커밋 메시지는 영어로 간결하게 작성합니다.

## 개발자 참고
- AGENTS.md는 추후 agent에게 전달할 추가 규칙이나 팁을 기록하는 곳입니다.
- 특별한 지시가 없으면 기본적으로 위 규칙을 따라 작업합니다.

## 문서 관리
- 이 저장소에서 제공하는 주요 지침은 README.md와 AGENTS.md 두 파일에서 관리합니다.
- 새 규칙이나 가이드를 작성할 때는 AGENTS.md를 수정해 내용이 흩어지지 않도록 합니다.

## 추가 가이드라인
- Nix 파일을 수정한 후에는 `pre-commit run --files <경로>`로 변경 사항을 검증합니다.
- 첫 사용 시 `pre-commit install`을 실행해 Git hook을 설치합니다.
- PR 메시지에는 **Summary**와 **Testing** 섹션을 포함해 어떤 수정이 있었는지와 확인 절차를 명시합니다.
- 새 모듈을 추가할 경우 `modules/` 하위 구조를 따르고, 관련 문서도 함께 갱신합니다.
- 커밋 메시지는 명령형 현재 시제로 작성하며 필요 시 관련 이슈 번호를 본문에 포함합니다.

## 코드 작성 가이드
- Nix 코드와 스크립트는 최대한 모듈화해 재사용성을 높입니다.
- 불필요한 의존성 추가를 피하고 명확한 주석을 남깁니다.
- 디렉터리 구조는 apps/, hosts/, modules/, overlays/ 네 영역을 중심으로 유지합니다.
- 공통 기능은 modules/shared/에 두고 플랫폼 전용 내용은 각 플랫폼 디렉터리에 배치합니다.
- 파일명과 옵션 이름은 소문자-hyphen 스타일로 작성합니다.
- **코드 수정 후에는 반드시 테스트를 실행합니다.**
  - `nix flake check --no-build`
  - 필요한 경우 `pre-commit run --files <경로>`

## Agent 테스트
- 문서나 설정 변경 후 `pre-commit run --all-files`로 전체 검사를 수행합니다.
- Nix 환경 통합을 확인하려면 `nix flake check --all-systems --no-build`를 실행합니다.

## GitHub CI 테스트
agent는 변경 사항이 Nix flake에 영향을 줄 경우 다음 절차를 수행해 CI와 동일한 검증을 선행합니다.

1. **Lint**: `pre-commit run --all-files`를 실행합니다.
2. **Smoke test**: 아래 네 가지 시스템을 대상으로 `nix flake check --system <SYSTEM> --no-build`을 수행합니다.
   - `x86_64-linux`
   - `aarch64-linux`
   - `x86_64-darwin`
   - `aarch64-darwin`
3. **Build test**: 각 시스템별 빌드가 필요한 경우 다음 명령을 실행합니다.
   - `nix build --no-link ".#nixosConfigurations.x86_64-linux.config.system.build.toplevel"`
   - `nix build --no-link ".#nixosConfigurations.aarch64-linux.config.system.build.toplevel"`
   - `nix build --no-link ".#darwinConfigurations.x86_64-darwin.system"`
   - `nix build --no-link ".#darwinConfigurations.aarch64-darwin.system"`
4. **최종 확인**: 빌드 후 다시 한 번 각 시스템에서 `nix flake check --system <SYSTEM> --no-build`을 실행합니다.

## Quick Test Workflow
아래 명령을 순서대로 실행하면 CI와 동일한 검증을 로컬에서 수행할 수 있습니다.

```sh
make lint   # pre-commit run --all-files
make smoke  # nix flake check --all-systems --no-build
make build  # build all NixOS/darwin configurations
make smoke  # final flake check after build
```

## 추가 프롬프트 지침
아래 지침은 사용자 정의 프롬프트에 따라 에이전트가 따를 규칙을 정리한 것입니다.

1. **완전한 구현과 테스트**: 어떤 기능을 요청받더라도 먼저 모든 코드를 작성하고 곧바로 단위 테스트를 생성해 실행합니다. 테스트가 실패하면 코드나 테스트를 수정해 통과시킵니다.
2. **폴더 구조와 문서 갱신**: 코드 예시에는 항상 관련 폴더 구조를 포함하며, 새 파일이나 디렉터리를 추가할 때는 README나 STYLEGUIDE 같은 문서를 업데이트하라고 안내합니다.
3. **코드 일원화**: 관련된 코드를 경로와 함께 한꺼번에 제시하고, 중복을 피하며 로직을 단일 위치에 모아 관리합니다.
4. **간결한 설명**: 설명은 최소화하고, 필요한 경우 인라인 주석을 사용하며 추가 설명이 필요하면 코드 블록 하단에 `## 추가 설명` 섹션을 둡니다.
5. **의존성 템플릿**: Maven, Gradle, npm 등 빌드 파일은 버전을 플레이스홀더로 표기하고 프로젝트 요구에 맞게 업데이트해야 함을 명시합니다.
6. **오류 처리와 보안**: 기본적인 오류 처리와 입력 검증, 인젝션 방지, 캐싱이나 비동기 처리 같은 성능 팁을 주석으로 포함합니다.
7. **테스트 도구와 명령어 명시**: 사용할 테스트 도구와 실제 실행 명령어(예: `run-tests`)를 정확히 보여줍니다.
8. **마이그레이션 및 문서 업데이트**: 기능이 변경되거나 새 파일이 추가될 때마다 마이그레이션 스크립트와 프로젝트 문서를 최신 상태로 유지해야 합니다.

## Framework Rule Template

<FRAMEWORK>
<!-- Insert Framework here -->
</FRAMEWORK>

<DATE>
<!-- Insert latest date here -->
</DATE>

you are prompt engineer. you are creating rules the {{FRAMEWORK}} framework

# STEPS:
1. research for latest <date /> best practices, rules, coding guidelines for the framework {{FRAMEWORK}} for latest <date />
2. create a rule in markdown format
3. It must always follow the <prompt_layout />

# MUST FOLLOW RULES:
- NEVER ADD wrap double ticks around description or globs
- use full sentences and avoid ":"
- if possible always prefer the typescript variant instead of js when using the framework
- AVOID redundant rules
- AVOID common webdesign and web development rules. only framework & library specific rules
- AVOID rules that are well known and obvious (LLMS already know these rules)
- YOU HAVE TO ADD RULES that extremly important for the current framework version.

# FORMAT:
1. remove all bold ** markdown asterisk. not needed
2. remove the "#" h1 heading

<prompt_layout>
Filename: add-{{INSERT_FILENAME}}.mdc
---

description: {{framework+version}}
globs: {{add here file globs like "**/*.tsx,**/.jsx"}}
alwaysApply: true
---

You are an expert in {{add here framework, typescript, libraries}}. You are focusing on producing clear, readable code.  
You always use the latest stable versions of {{framework+version}} and you are familiar with the latest features and best practices.

# Project Structure
- {{add here best practice prompt structure}}

# Code Style
- {{add here coding style}}

# Usage
- {{add here best practice prompt structure}}

- {{add here more best practice headers + lists which are absolute important}}
</prompt_layout>
