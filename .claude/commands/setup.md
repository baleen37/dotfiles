---
description: Interactive project setup wizard for language-specific best practices, architecture patterns, pre-commit hooks, CI/CD pipelines, and comprehensive testing strategies.
---

User input:

$ARGUMENTS

Goal: 언어별 베스트 프랙티스를 체크리스트로 확인하며 단계별로 프로젝트를 설정합니다.

## Setup Checklist

### 1. 프로젝트 감지 및 템플릿 선택

- [ ] 현재 디렉토리 확인: `ls -la`
- [ ] 언어 자동 감지 (package.json, pyproject.toml, Cargo.toml, go.mod)
- [ ] 감지 실패 시 사용자에게 언어 질문
- [ ] 해당 언어 템플릿 로드:
  - TypeScript: `.claude/templates/setup/typescript.md`
  - Python: `.claude/templates/setup/python.md`
  - Go: `.claude/templates/setup/go.md`
  - Rust: `.claude/templates/setup/rust.md`

### 2. 프로젝트 컨텍스트 수집

- [ ] 프로젝트 타입 질문 (Web App, CLI, Library, Microservice)
- [ ] 아키텍처 패턴 질문 (Clean/Hexagonal, Layered, Simple)

### 3. 디렉토리 구조 생성

- [ ] **선택한 언어 템플릿 읽기** (디렉토리 구조 섹션 참고)
- [ ] 사용자에게 구조 보여주고 확인 받기
- [ ] 템플릿에 정의된 디렉토리 생성

### 4. Pre-commit 훅 설정

- [ ] **템플릿의 Pre-commit Setup 섹션 참고**
- [ ] 언어별 프레임워크 설치 (husky/lint-staged, pre-commit 등)
- [ ] 템플릿에서 설정 파일 복사 (`.pre-commit-config.yaml`, `.husky/pre-commit` 등)
- [ ] **아키텍처 검증 테스트 추가** - 템플릿의 Architecture Validation Tests 섹션 참고
- [ ] Pre-commit hook 테스트

### 5. 테스트 프레임워크 구성

- [ ] **템플릿의 Test Configuration 섹션 참고**
- [ ] 언어별 테스트 프레임워크 설치 (Jest, pytest, Go testing 등)
- [ ] 템플릿에서 테스트 설정 파일 복사
- [ ] 템플릿의 Architecture Validation Tests 코드 추가
- [ ] 커버리지 임계값 설정 (80%)

### 6. CI/CD 파이프라인 생성

- [ ] CI 플랫폼 선택 (GitHub Actions 권장)
- [ ] **템플릿의 CI Configuration 섹션 참고**
- [ ] 템플릿에서 CI 설정 파일 복사 및 수정

### 7. 문서 및 빌드 스크립트 생성

- [ ] `README.md` 생성 (Quick start, 설치, 사용법)
- [ ] `docs/architecture.md` 생성 (아키텍처 결정 사항)
- [ ] **템플릿의 Makefile 섹션 참고**하여 빌드 스크립트 생성

### 8. 검증 및 완료

- [ ] 의존성 설치
- [ ] Linter 실행
- [ ] Formatter 실행
- [ ] 아키텍처 테스트 실행 (**중요**)
- [ ] Unit/Integration 테스트 실행
- [ ] 빌드 실행
- [ ] 설정 요약 생성

## 실행 방법

1. 위 체크리스트를 순서대로 진행
2. 각 단계마다 사용자에게 확인 받기
3. 템플릿에서 필요한 코드/설정 가져오기
4. 완료된 항목은 [X]로 표시
5. 최종 요약 리포트 생성

## 행동 규칙

- **대화형**: 각 단계에서 사용자 확인 필요
- **템플릿 우선**: 언어별 템플릿의 내용을 최대한 활용
- **최소주의**: YAGNI - 필요한 것만 설치
- **검증**: 각 단계 완료 후 테스트
- **문서화**: 모든 결정사항 문서화

## Context

사용자 제공 컨텍스트:

$ARGUMENTS
