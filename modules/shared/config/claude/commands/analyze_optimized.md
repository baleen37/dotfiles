# /analyze - 지능형 분석

자동 감지 기반 포괄적 분석

## 사용법
```bash
/analyze [target] [--think|--ultrathink]
```

## 자동 시스템
- **MCP 라우팅**: Frontend → Magic, Backend → Context7, 복잡 → Sequential
- **깊이 선택**: 복잡도 감지로 자동 --think 활성화
- **전문가 연계**: security-auditor, performance-engineer 자동 호출

## 분석 영역
- **품질**: 복잡도, 유지보수성, 기술 부채, 테스트 품질
- **보안**: 취약점, 위협 모델링, 보안 모범 사례  
- **성능**: 병목점, 확장성, 리소스 최적화
- **아키텍처**: 패턴 평가, 결합도, 응집도

## 예시
```bash
/analyze                      # 전체 프로젝트 자동 분석
/analyze src/components      # React 컴포넌트 분석 (Magic MCP)
/analyze api/ --think        # API 깊이 분석 (Context7 MCP)
```
