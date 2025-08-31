---
name: workflow
description: "Generate comprehensive implementation workflows from requirements with task dependency mapping"
agents: [system-architect]
---

# /workflow - Implementation Workflow Generator

**Purpose**: 요구사항을 받아서 종합적인 구현 워크플로우를 생성합니다. 단순한 Phase별 계획을 넘어 태스크 의존성, 리스크 분석, 다중 도메인 조정을 포함합니다.

## Usage

```bash
/workflow "user authentication system"
/workflow "database performance optimization"  
/workflow "deploy microservices to k8s"
```

## Core Features

**종합적 분석**:
- 요구사항 분해 및 도메인별 분류
- 태스크 간 의존성 매핑
- 리스크 식별 및 완화 전략
- 리소스 요구사항 추정

**다중 페르소나 조정**:
- system-architect가 전체 설계 주도
- 필요시 다른 전문가 에이전트들과 협업
- 도메인별 최적 접근법 적용

**구조화된 출력**:
- 명확한 단계별 실행 계획
- 각 단계별 완료 조건과 검증 방법
- 병렬 실행 가능한 태스크 식별
- 예상 소요 시간과 복잡도 평가

## MCP Integration

- **Sequential**: 체계적 워크플로우 계획 수립
- **Context7**: 기술 스택별 best practices 적용
- **Serena**: 프로젝트 컨텍스트와 과거 경험 활용

## Example Output

```
## Implementation Workflow: User Authentication System

### Phase 1: Foundation Setup
**Dependencies**: None | **Duration**: 2-3 hours
- [ ] Install auth dependencies (bcrypt, JWT, session store)
- [ ] Database schema design and migration
- [ ] Environment configuration setup

### Phase 2: Core Implementation  
**Dependencies**: Phase 1 complete | **Duration**: 1-2 days
- [ ] User registration endpoint with validation
- [ ] Login/logout functionality with session management
- [ ] Password hashing and verification
- [ ] JWT token generation and validation

### Phase 3: Security & Integration
**Dependencies**: Phase 2 complete | **Duration**: 4-6 hours
- [ ] Auth middleware implementation
- [ ] Route protection setup
- [ ] Security headers and CSRF protection
- [ ] Rate limiting for auth endpoints

### Phase 4: Testing & Validation
**Dependencies**: Phase 3 complete | **Duration**: 3-4 hours
- [ ] Unit tests for auth functions
- [ ] Integration tests for auth flows
- [ ] Security testing and validation
- [ ] Performance testing under load

**Risk Factors**:
- Session store configuration complexity
- JWT secret management
- Rate limiting calibration

**Success Criteria**:
- All auth flows working end-to-end
- Security tests passing
- Performance within acceptable limits
```

## Key Differences from /plan

- **Scope**: 전체 구현 여정 vs 단계별 태스크 생성
- **Depth**: 의존성, 리스크, 검증 포함 vs 기본 태스크만
- **Coordination**: 다중 에이전트 활용 vs 단일 관점
- **Context**: 프로젝트 전체 맥락 고려 vs 개별 요구사항만

**Next Steps**: 생성된 워크플로우를 `/implement` 또는 `/do-plan`으로 실행
