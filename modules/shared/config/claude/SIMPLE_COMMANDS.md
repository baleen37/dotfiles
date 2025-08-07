# Claude 핵심 명령어 (5개)

## /analyze [target]
**목적**: 코드/시스템 분석
- 자동 MCP: Context7, Sequential 활용
- 출력: 품질, 보안, 성능 종합 분석

```bash
/analyze                    # 전체 프로젝트
/analyze src/components     # 특정 디렉토리
```

## /implement "기능 설명"
**목적**: 새 기능 구현
- 자동 패턴 인식 및 최적 도구 선택
- 타입 안전성, 에러 처리, 테스트 포함

```bash
/implement "사용자 로그인"
/implement "API 엔드포인트"
```

## /improve [target]
**목적**: 기존 코드 개선
**목적**: 기존 코드 개선  
- 성능, 보안, 품질 자동 감지 개선
- 안전한 리팩토링

```bash
/improve auth.js
/improve database/
```

## /debug "문제 설명"
**목적**: 버그 해결
- debugger 전문가 자동 활성화
- 근본 원인 분석 (증상 수정 금지)

```bash
/debug "빌드가 실패해"
/debug "API 응답이 느려"
```

## /test [target]
**목적**: 테스트 작성/실행
- TDD 워크플로우 지원
- unit + integration + e2e

```bash
/test login.js
/test --e2e
```

## 자동화 기능
- **MCP 서버**: 키워드 기반 자동 선택
- **Think 플래그**: 복잡도 감지로 자동 활성화
- **Think 플래그**: 복잡도 감지로 자동 활성화  
- **전문가 Agent**: 필요시 자동 호출
- **Rule #1 보장**: 위험 작업은 승인 요청
