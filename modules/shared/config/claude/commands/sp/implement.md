---
name: implement
category: dev
description: "체계적인 구현 - 단계별 실행"
---

체계적인 단계를 따라 구현. 작은 기능, 버그수정, 간단한 개선사항용.

## Usage
/sp:implement [target] [description]

## Systematic Workflow (TDD 기반)
1. **분석**: 문제 파악 및 요구사항 정의
2. **설계**: 최소한의 구현 방안 설계
3. **구현**: TDD 사이클 (RED → GREEN → REFACTOR)
   - 실패하는 테스트 작성 (RED)
   - 테스트 통과 최소 코드 작성 (GREEN)
   - 코드 개선 및 리팩토링 (REFACTOR)
4. **검증**: 테스트 및 품질 확인
5. **완료**: 결과 확인 및 정리

## Quality Gates
- [ ] 요구사항 충족 확인
- [ ] 모든 테스트 통과 (unit, integration, e2e)
- [ ] 코드 스타일 준수 (lint, format)
- [ ] 기존 기능 영향도 검토
- [ ] 근본 원인 해결 확인 (증상 수정 금지)
- [ ] 코드 중복 제거 (DRY 원칙)
- [ ] 불필요한 코드 삭제 (YAGNI 원칙)

## Best For
- 버그 수정
- UI 조정
- 설정 변경
- 작은 기능 추가

## Core Principles (YAGNI • DRY • KISS)
- **YAGNI**: 현재 요구사항만 구현, 미래 가능성 배제
- **DRY**: 중복 로직 즉시 제거, Rule of Three 적용
- **KISS**: 가장 간단한 해결책 선택, 최소 변경으로 목표 달성

## Strict Rules
- **근본 원인 해결**: 증상이 아닌 원인 수정 필수
- **Pre-commit Hook**: 절대 우회 금지 (`--no-verify` 사용 금지)
- **테스트 우선**: 실패 테스트 → 최소 코드 → 리팩토링
- **코드 정리**: 사용하지 않는 코드, import, 주석 즉시 삭제
