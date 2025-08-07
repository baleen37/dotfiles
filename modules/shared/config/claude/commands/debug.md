# /debug - 체계적 문제 해결

근본 원인 분석 및 해결 (증상 수정 금지)

## 사용법
```bash
/debug "문제 설명" [--category type] [--severity level]
```

## 자동 시스템
- **debugger 전문가** 자동 활성화
- **증거 수집**: 로그, 메트릭, 스택 트레이스 자동 분석
- **패턴 인식**: 유사 문제 및 해결책 검색
- **근본 원인**: 5-Why 기법으로 진짜 원인 식별

## 문제 카테고리
- `--category runtime` - 런타임 오류, 크래시, 예외
- `--category build` - 빌드 실패, 컴파일 오류
- `--category performance` - 성능 저하, 병목점
- `--category integration` - API 실패, 서비스 통신

## 심각도
- `--severity critical` - 시스템 다운, 보안 침해
- `--severity high` - 주요 기능 중단
- `--severity medium` - 부분 기능 영향

## 진단 프로세스
1. **재현**: 일관된 문제 재현
2. **증거 수집**: 로그, 메트릭, 환경 정보
3. **가설 수립**: 근본 원인 가설
4. **검증**: 가설 테스트 및 해결책 구현
5. **예방**: 재발 방지 조치

## 예시
```bash
/debug "빌드가 갑자기 실패해" --category build
/debug "API 응답 시간이 너무 느려" --category performance --think
/debug "인증이 간헐적으로 실패해" --severity high --ultrathink
```
