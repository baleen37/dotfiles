# TODO 목록

## ⏳ 대기 중 (예정된 작업)

### Phase 7: CLI 시스템 TDD 구현
- [ ] **고우선순위** - CLI Upload Command TDD 구현 (Phase 7.3)
- [ ] **중우선순위** - CLI 기타 Commands TDD 구현 (Phase 7.4)

### Phase 8: 스케줄러 시스템 TDD 구현
- [ ] **중우선순위** - 스케줄러 시스템 설계 및 구현

### Phase 9: 작업 큐 시스템 TDD 구현
- [ ] **저우선순위** - 작업 큐 시스템 설계 및 구현

### Phase 10: 통합 테스트 및 최적화
- [ ] **저우선순위** - 전체 시스템 통합 테스트
- [ ] **저우선순위** - 성능 최적화 및 튜닝

## ✅ 완료된 작업 (최근 완료)

### Phase 7.2: CLI Generate Command TDD 구현 ✅ (2025-06-28)
- ✅ `cmd/cli/generate.go` - CLI Generate Command 구현 완료
- ✅ `cmd/cli/generate_test.go` - 포괄적인 테스트 스위트 작성
- ✅ Cobra CLI 프레임워크 기반 구현
- ✅ 채널별 스토리 생성 기능 (`--channel` 플래그)
- ✅ 출력 디렉토리 지정 기능 (`--output` 플래그)
- ✅ Verbose 로깅 지원 (`--verbose` 플래그)
- ✅ 기존 Story 서비스와의 완전한 통합
- ✅ JSON 출력 형식으로 메타데이터 포함 저장
- ✅ 타임스탬프 기반 파일명 생성
- ✅ Mock 서비스를 통한 테스트 환경 지원
- ✅ 100% 테스트 커버리지 달성

### Phase 7.1: CLI Root Command TDD 구현 ✅ (2025-06-28)
- ✅ Cobra CLI 프레임워크 기반 루트 명령어 구현
- ✅ 글로벌 플래그 설정 (--config, --env, --verbose, --log-level)
- ✅ Version Command 구현 (--short, --json 플래그 지원)
- ✅ Config Command 구현 (--paths, --output 플래그 지원)
- ✅ 81.2% 테스트 커버리지 달성
- ✅ 기존 설정 시스템과의 완전한 통합

### Phase 6.5: YouTube 도메인 통합 테스트 ✅ (2025-06-28)
- ✅ YouTube 도메인 전체 통합 테스트 구현
- ✅ Video → YouTube 전체 플로우 테스트 구현
- ✅ 에러 복구 시나리오 테스트 구현
- ✅ Mock과 실제 API 연동 테스트 구현
- ✅ `internal/youtube/video_integration_test.go` - Video 도메인 통합
- ✅ `internal/youtube/error_recovery_test.go` - 에러 복구 시나리오
- ✅ `internal/youtube/mock_vs_real_test.go` - Mock vs Real API 동작
- ✅ 모든 테스트 SKIP_YOUTUBE_API 환경변수 지원
- ✅ 포괄적인 테스트 커버리지 달성

### Phase 6.4: 메타데이터 생성기 TDD 구현 ✅ (2025-06-28)
- ✅ `internal/youtube/adapters/enhanced_metadata_generator.go` 구현 완료
- ✅ `internal/youtube/adapters/enhanced_metadata_generator_test.go` 테스트 작성
- ✅ OpenAI API 활용한 지능형 메타데이터 생성
- ✅ 채널별 맞춤형 템플릿 시스템 (YAML 기반)
- ✅ SEO 최적화된 제목 생성 로직
- ✅ 스토리 내용 기반 설명 생성
- ✅ AI 기반 관련성 높은 태그 자동 추천
- ✅ 특수문자 및 이모지 처리 검증
- ✅ 길이 제한 검증 (제목 100자, 설명 5000자)
- ✅ Mock 지원 (SKIP_OPENAI_API 환경변수)
- ✅ 후방 호환성 유지 (기존 metadata_generator와 공존)

### Phase 6.3: YouTube API Adapter TDD 구현 ✅ (2024-06-27)
- ✅ `internal/youtube/adapters/youtube_adapter.go` 구현 완료
- ✅ `internal/youtube/adapters/youtube_adapter_test.go` 테스트 작성
- ✅ 실제 YouTube Data API v3 통합
- ✅ 청크 기반 비디오 업로드 구현
- ✅ OAuth2 토큰 기반 인증 플로우
- ✅ 비디오 업로드/수정/삭제/조회 기능
- ✅ 썸네일 업로드 및 URL 추출
- ✅ 진행률 콜백 및 ETA 계산
- ✅ 비디오 검증 로직 (제목, 태그, 프라이버시)
- ✅ ISO 8601 duration 파싱
- ✅ 테스트 환경 지원 (SKIP_YOUTUBE_API)
- ✅ 포괄적인 단위 테스트

### Phase 6.2: YouTube Core Service TDD 구현 ✅ (2024-06-27)
- ✅ `internal/youtube/core/service.go` 구현 완료
- ✅ `internal/youtube/core/service_test.go` 테스트 작성
- ✅ YouTube 서비스 인터페이스 정의
- ✅ 스토리 비디오 업로드 오케스트레이션
- ✅ 메타데이터 자동 생성 통합
- ✅ 접근 토큰 검증 및 에러 처리
- ✅ 요청 검증 로직 구현
- ✅ Mock 객체 활용한 단위 테스트

### Phase 6.1: YouTube OAuth2 의존성 설정 ✅ (2024-06-27)
- ✅ YouTube Data API v3 및 OAuth2 의존성 추가
- ✅ YouTube 도메인 디렉토리 구조 생성
- ✅ YouTube 포트 인터페이스 정의
- ✅ OAuth 서비스 구현 (토큰 관리)
- ✅ OAuth 설정 파일 생성 (`configs/oauth.yaml`)
- ✅ YouTube 관련 에러 코드 추가

### Phase 5: Video 도메인 TDD 구현 ✅ (2024-06-27)
- ✅ **Phase 5.1**: ffmpeg 의존성 및 환경 설정
- ✅ **Phase 5.2**: Video Core Service TDD 구현
- ✅ **Phase 5.3**: FFmpeg Adapter TDD 구현
- ✅ **Phase 5.4**: Video Validator TDD 구현
- ✅ **Phase 5.5**: Video 도메인 통합 테스트

## 📋 기술적 고려사항

### 우선순위 정의
- **고우선순위**: 핵심 기능, 사용자 대면 기능
- **중우선순위**: 자동화, 최적화 기능
- **저우선순위**: 부가 기능, 고도화 기능

### 다음 단계 상세 계획 (Phase 7)

#### 메타데이터 생성기 요구사항
1. **OpenAI API 통합**
   - 스토리 내용 분석 및 요약
   - 채널 타입에 맞는 톤앤매너 적용
   - 키워드 추출 및 SEO 최적화

2. **채널별 맞춤 설정**
   ```yaml
   # configs/channels/fairy_tale.yaml 확장
   youtube:
     metadata:
       title_templates:
         - "✨ {title} | 동화 이야기 #Shorts"
         - "🧚‍♀️ {title} | 마법같은 이야기"
       description_template: |
         {summary}
         
         📱 더 많은 동화를 보고 싶다면 구독해주세요!
         
         #동화 #이야기 #Shorts #감동 #교훈
       tags:
         base: ["동화", "이야기", "Shorts"]
         auto_generate: true
       category_id: "22"
   ```

3. **검증 규칙**
   - 제목: 100자 이내, 특수문자 제한
   - 설명: 5000자 이내, 적절한 해시태그 포함
   - 태그: 총 500자 이내, 관련성 검증

4. **테스트 커버리지**
   - 각 채널 타입별 메타데이터 생성
   - 길이 제한 및 형식 검증
   - OpenAI API 에러 처리
   - 특수문자 및 이모지 처리
   - 템플릿 변수 치환

### 아키텍처 준수사항
- Hexagonal Architecture 패턴 유지
- TDD 방법론 엄격 적용
- 의존성 주입을 통한 테스트 가능성 확보
- 기존 설정 시스템과의 일관성 유지
- 포괄적인 에러 처리 및 로깅

### 성능 고려사항
- OpenAI API 호출 최적화 (캐싱 고려)
- 메타데이터 생성 속도 최적화
- 네트워크 에러 시 재시도 로직
- API 요청 제한(rate limiting) 고려

## 🎯 최종 목표

**YouTube Shorts 자동 생성 시스템 완성**
- Story → Image → TTS → Video → YouTube 전체 파이프라인
- 사용자 친화적인 CLI 인터페이스
- 자동화된 스케줄링 시스템
- 안정적인 에러 처리 및 복구
- 확장 가능한 아키텍처

**예상 완료 시점**: 2024년 8월 (약 8주 소요 예상)