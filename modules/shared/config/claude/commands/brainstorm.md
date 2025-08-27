---
name: brainstorm
description: "Transform vague ideas into concrete requirements through codebase analysis"
agents: [system-architect, frontend-developer, backend-engineer]
---

# /brainstorm - Interactive Specification Development

**Purpose**: Ask me one question at a time so we can develop a thorough, step-by-step spec for this idea. Each question builds on my previous answers, and our end goal is to have a detailed specification I can hand off to a developer.

## Usage

```bash
/brainstorm <idea>    # Interactive Q&A to develop detailed specification
```

## How It Works

1. You give me an idea
2. I ask **one question at a time in Korean**
3. Each question includes **numbered options** for easy selection
4. Each question builds on your previous answers
5. We continue until we have a complete spec
6. I ask if you want me to save everything as `spec.md`

## Question Format

Questions will be asked in Korean with numbered options:

```
질문: 이 앱을 주로 사용할 대상은 누구인가요?

1. 일반 소비자
2. 기업 직원
3. 개발자/기술자
4. 학생
5. 기타 (직접 입력)

번호를 선택하거나 직접 답변해주세요.
```

## Examples

```bash
/brainstorm "team task tracker"
# → "팀 업무 추적 시스템을 사용할 팀 규모는 어느 정도인가요?
#    1. 소규모 팀 (3-10명)
#    2. 중간 규모 팀 (10-50명)
#    3. 대규모 팀 (50명 이상)"

/brainstorm "user login system"  
# → "로그인 시스템이 필요한 애플리케이션 유형은 무엇인가요?
#    1. 웹 애플리케이션
#    2. 모바일 앱
#    3. 데스크톱 애플리케이션
#    4. API 서비스"

/brainstorm "mobile shopping app"
# → "모바일 쇼핑 앱의 주요 목표는 무엇인가요?
#    1. B2C 일반 소매
#    2. B2B 기업간 거래
#    3. C2C 중고거래
#    4. 특정 카테고리 전문"
```
