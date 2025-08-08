# Claude Code 단순 가이드

## 🎯 핵심 원칙: Zero Configuration Intelligence

사용자는 단순히 요청하고, 시스템이 모든 것을 자동으로 처리합니다.

## 기본 사용법

### 분석
```bash
/analyze [target]              # 자동 분석 (기본)
/analyze [target] --think      # 깊은 분석
/analyze [target] --deep       # 최대 깊이 분석
```

### 구현
```bash
/implement "기능 설명"          # 자동 구현 (기본)
/implement "기능 설명" --think  # 깊은 사고로 구현
/implement "기능 설명" --deep   # 최대 깊이로 구현
```

### 개선
```bash
/improve [target]              # 자동 개선 (기본)
/improve [target] --think      # 깊은 사고로 개선
/improve [target] --deep       # 최대 깊이로 개선
```

## 🤖 자동화 시스템

### 시스템이 자동으로 처리하는 것들
- **복잡도 감지**: 작업의 복잡도를 자동으로 판단
- **기술 스택 감지**: React, Python, Nix 등을 자동으로 인식
- **MCP 서버 선택**: Context7, Sequential, Magic 등을 자동으로 활용
- **전문가 호출**: Task 도구의 내장 subagent 자동 활용
- **품질 검증**: 자동으로 lint, test, 보안 검토 실행

### 키워드 기반 자동 활성화
- **UI 관련**: "컴포넌트", "버튼", "폼" → Magic 서버 자동 활성화
- **문서 검색**: "라이브러리", "API", "프레임워크" → Context7 서버 자동 활성화
- **분석 필요**: "분석", "계획", "전략" → Sequential 서버 자동 활성화
- **테스트**: "테스트", "E2E", "자동화" → Playwright 서버 자동 활성화

## 🎯 실제 사용 예시

### 일반적인 요청
```bash
/analyze src/components
# 자동으로 UI 컴포넌트 분석, Magic 서버 활성화, 품질 검토

/implement "로그인 폼"
# 자동으로 React 패턴 감지, Context7에서 모범 사례 검색, UI 생성

/improve api/auth.py
# 자동으로 Python 코드 개선, 보안 검토, 테스트 확인
```

### 복잡한 요청
```bash
/analyze . --think
# 전체 코드베이스 깊은 분석, 아키텍처 검토

/implement "결제 시스템" --deep
# 최대 깊이로 보안, 성능, 테스트까지 완벽 구현

/improve legacy/ --think
# 레거시 코드 깊은 분석 후 현대화 방안 제시
```

## 💡 핵심 철학

**"설명하지 말고 실행하라"**
- 사용자는 무엇을 원하는지만 말하면 됨
- 시스템이 어떻게 할지는 자동으로 결정
- 복잡한 설정이나 플래그는 필요 없음

**"지능적이지만 단순하게"**
<<<<<<< HEAD
**"지능적이지만 단순하게"**  
=======
>>>>>>> 7a7c22d (refactor: 코드베이스 정리 및 Claude 설정 시스템 구성)
- 내부적으로는 복잡한 자동화
- 사용자에게는 단순한 인터페이스
- 필요할 때만 --think, --deep 사용
