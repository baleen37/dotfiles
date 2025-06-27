# YouTube Shorts 자동 생성 시스템 구현 계획

## 프로젝트 개요

YouTube Shorts 자동 생성 시스템을 완성하기 위한 단계별 구현 계획입니다.
현재 Phase 0-4가 완료되었으며, 동영상 합성, YouTube 업로드, CLI, 스케줄러를 구현해야 합니다.

## 현재 상태 (완료된 기능)

- ✅ **Phase 0-2**: Hexagonal Architecture 기반 구조, Story/Channel 도메인
- ✅ **Phase 3**: Image 생성 시스템 (Stable Diffusion)
- ✅ **Phase 4**: TTS 나레이션 생성 시스템 (Google Cloud TTS)
- ✅ **Phase 5**: Video 도메인 완성 (동영상 합성) - **2024년 6월 완료**
- ✅ **Phase 6.1-6.3**: YouTube 도메인 부분 완성 (OAuth2, Core Service, API Adapter) - **2024년 6월 완료**

## 남은 구현 과제

### 🔄 Phase 6: YouTube 도메인 완성 (업로드 자동화) - **진행 중**
- ✅ Phase 6.1: OAuth2 의존성 설정
- ✅ Phase 6.2: YouTube Core Service TDD 구현  
- ✅ Phase 6.3: YouTube API Adapter TDD 구현
- 🔄 Phase 6.4: 메타데이터 생성기 TDD 구현 **← 현재 위치**
- ⏳ Phase 6.5: YouTube 도메인 통합 테스트

### Phase 7: CLI 명령어 구현
### Phase 8: 스케줄러 시스템
### Phase 9: 작업 큐 시스템
### Phase 10: 통합 테스트 및 최적화

---

## ✅ Phase 5: Video 도메인 완성 (동영상 합성) - **완료**

### 목표
ffmpeg를 활용하여 이미지, TTS 음성, 배경음악을 결합한 YouTube Shorts 동영상을 생성

### 기술 스택
- **ffmpeg-go**: ffmpeg Go 바인딩
- **기존 구조**: `internal/video/core/`, `internal/video/ports/`, `internal/video/adapters/`

### 5.1 의존성 추가 ✅
- ✅ `go.mod`에 `github.com/u2takey/ffmpeg-go` 추가
- ✅ ffmpeg 바이너리 설치 확인 (로컬/Docker)
- ✅ 테스트용 배경음악 파일 준비 (`assets/audio/background/`)

### 5.2 Video Core 서비스 구현 ✅
- ✅ `internal/video/core/service.go` 완성
  - ✅ `ComposeVideo()` 메서드 구현
  - ✅ 동영상 길이 계산 (TTS 길이 기반)
  - ✅ 장면별 이미지 표시 시간 계산
  - ✅ Ken Burns 효과 설정 정의

### 5.3 FFmpeg Adapter 구현 ✅
- ✅ `internal/video/adapters/ffmpeg_adapter.go` 생성
  - ✅ 이미지 시퀀스를 동영상으로 변환
  - ✅ Ken Burns 효과 적용 (zoom/pan)
  - ✅ TTS 오디오 오버레이
  - ✅ 배경음악 믹싱 (볼륨 조절)
  - ✅ 1080x1920 세로 포맷 출력
  - ✅ 장면 간 크로스페이드 전환

### 5.4 Video Validator 구현 ✅
- ✅ `internal/video/adapters/validator.go` 생성
  - ✅ 출력 파일 형식 검증 (MP4)
  - ✅ 해상도 검증 (1080x1920)
  - ✅ 길이 검증 (30-60초)
  - ✅ 오디오 품질 검증

### 5.5 테스트 구현 ✅
- ✅ `internal/video/core/service_test.go`
  - ✅ 동영상 합성 단위 테스트
  - ✅ 에러 처리 테스트
- ✅ `internal/video/adapters/ffmpeg_adapter_test.go`
  - ✅ ffmpeg 명령어 생성 테스트
  - ✅ 실제 파일 합성 통합 테스트

### 5.6 통합 테스트 구현 ✅
- ✅ `internal/video/integration_test.go`
  - ✅ 전체 비디오 파이프라인 통합 테스트
  - ✅ 실제 서비스와 동일한 인터페이스 구현

---

## 🔄 Phase 6: YouTube 도메인 완성 (업로드 자동화) - **진행 중**

### 목표
OAuth2 인증을 통해 생성된 동영상을 YouTube에 자동 업로드

### 기술 스택
- **google.golang.org/api/youtube/v3**: YouTube Data API v3
- **golang.org/x/oauth2**: OAuth2 인증

### 6.1 의존성 추가 ✅
- ✅ YouTube API 관련 패키지 설치
- ✅ OAuth2 패키지 설치
- ✅ Google Cloud Console에서 YouTube API 활성화 준비
- ✅ OAuth2 클라이언트 자격증명 설정 구조 생성

### 6.2 YouTube Core 서비스 구현 ✅
- ✅ `internal/youtube/core/service.go` 완성
  - ✅ `UploadStory()` 메서드 구현
  - ✅ 메타데이터 생성 로직 통합
  - ✅ 업로드 진행률 추적
  - ✅ 업로드 후 비디오 ID 반환
  - ✅ 채널 정보 조회, 비디오 업데이트/삭제 기능

### 6.3 YouTube API Adapter 구현 ✅
- ✅ `internal/youtube/adapters/youtube_adapter.go` 생성
  - ✅ OAuth2 인증 플로우 구현
  - ✅ 토큰 저장/갱신 관리
  - ✅ 동영상 업로드 API 호출 (청크 기반)
  - ✅ 썸네일 업로드 구현
  - ✅ API 할당량 관리 고려
  - ✅ 진행률 콜백 및 ETA 계산

### 6.4 메타데이터 생성기 구현 🔄 **← 현재 위치**
- 🔄 `internal/youtube/adapters/metadata_generator.go` 생성 예정
  - [ ] 채널별 제목 템플릿
  - [ ] 설명 자동 생성 (스토리 요약)
  - [ ] 태그 생성 (#Shorts, 채널별 태그)
  - [ ] 카테고리 설정

### 6.5 OAuth2 설정 및 인증 ✅
- ✅ `configs/oauth.yaml` 생성
  - ✅ 클라이언트 ID/Secret 환경변수 설정
  - ✅ Redirect URL 설정
  - ✅ 스코프 정의 (youtube.upload)
- ✅ OAuth 서비스 구현 (`internal/youtube/adapters/oauth_service.go`)

### 6.6 테스트 구현 ✅
- ✅ `internal/youtube/core/service_test.go`
  - ✅ 메타데이터 생성 테스트
  - ✅ 에러 처리 테스트
- ✅ `internal/youtube/adapters/youtube_adapter_test.go`
  - ✅ OAuth2 플로우 테스트 (Mock)
  - ✅ API 호출 테스트

### 6.7 통합 테스트 ⏳
- ⏳ YouTube 도메인 통합 테스트 예정
  - ⏳ 전체 업로드 플로우 테스트
  - ⏳ 에러 복구 시나리오 테스트

---

## Phase 7: CLI 명령어 구현

### 목표
사용자 친화적인 CLI 인터페이스로 전체 파이프라인 실행

### 기술 스택
- **spf13/cobra**: CLI 프레임워크
- **spf13/viper**: 설정 관리 (기존과 통합)

### 7.1 의존성 추가
- [ ] Cobra 및 Viper 패키지 설치
- [ ] CLI 구조 설계

### 7.2 Root Command 구현
- [ ] `cmd/cli/main.go` 업데이트
  - [ ] Cobra 앱 초기화
  - [ ] 글로벌 플래그 정의 (--env, --config, --verbose)
  - [ ] 설정 로딩 로직

### 7.3 Generate Command 구현
- [ ] `cmd/cli/commands/generate.go` 생성
  - [ ] `generate` 서브커맨드
  - [ ] 채널 지정 플래그 (`--channel`)
  - [ ] 출력 디렉토리 플래그 (`--output`)
  - [ ] 전체 파이프라인 실행 (Story → Image → TTS → Video)
  - [ ] 진행률 표시

### 7.4 Upload Command 구현
- [ ] `cmd/cli/commands/upload.go` 생성
  - [ ] `upload` 서브커맨드
  - [ ] 로컬 동영상 파일 업로드
  - [ ] YouTube 인증 처리
  - [ ] 업로드 진행률 표시

### 7.5 List Command 구현
- [ ] `cmd/cli/commands/list.go` 생성
  - [ ] `list channels` - 사용 가능한 채널 목록
  - [ ] `list videos` - 생성된 동영상 목록
  - [ ] `list uploads` - 업로드된 동영상 목록

### 7.6 Config Command 구현
- [ ] `cmd/cli/commands/config.go` 생성
  - [ ] `config init` - 초기 설정 생성
  - [ ] `config show` - 현재 설정 표시
  - [ ] `config set` - 설정 값 변경

### 7.7 Pipeline Command 구현 (All-in-One)
- [ ] `cmd/cli/commands/pipeline.go` 생성
  - [ ] `pipeline run` - 전체 파이프라인 실행 (생성+업로드)
  - [ ] 배치 처리 지원 (여러 채널)
  - [ ] 에러 발생 시 재시도 옵션

### 7.8 CLI 테스트
- [ ] 각 명령어별 단위 테스트
- [ ] E2E 테스트 (실제 CLI 실행)
- [ ] 도움말 메시지 검증

---

## Phase 8: 스케줄러 시스템

### 목표
정기적으로 동영상을 자동 생성하고 업로드하는 스케줄러

### 기술 스택
- **robfig/cron**: 크론 스케줄러
- **PostgreSQL**: 작업 이력 저장
- **Redis**: 분산 잠금

### 8.1 의존성 추가
- [ ] `github.com/robfig/cron/v3` 설치
- [ ] 스케줄러 관련 테이블 마이그레이션

### 8.2 Scheduler Core 서비스 생성
- [ ] `internal/scheduler/core/` 패키지 생성
- [ ] `internal/scheduler/core/service.go`
  - [ ] 크론 작업 등록/해제
  - [ ] 작업 실행 이력 관리
  - [ ] 중복 실행 방지

### 8.3 Job 정의 및 구현
- [ ] `internal/scheduler/core/jobs.go`
  - [ ] `GenerateVideoJob` - 동영상 생성 작업
  - [ ] `UploadVideoJob` - 업로드 작업
  - [ ] `CleanupJob` - 임시 파일 정리
  - [ ] 작업별 설정 (채널, 빈도)

### 8.4 스케줄 설정
- [ ] `configs/schedule.yaml` 생성
  - [ ] 채널별 생성 스케줄
  - [ ] 업로드 시간대 설정
  - [ ] 정리 작업 스케줄

### 8.5 분산 잠금 구현
- [ ] `internal/scheduler/adapters/redis_locker.go`
  - [ ] Redis SETNX를 활용한 분산 잠금
  - [ ] 잠금 만료 시간 관리
  - [ ] 데드락 방지

### 8.6 작업 이력 관리
- [ ] `internal/scheduler/adapters/postgres_repository.go`
  - [ ] 작업 실행 이력 저장
  - [ ] 성공/실패 통계
  - [ ] 작업 상태 추적

### 8.7 Scheduler API 생성
- [ ] `cmd/scheduler/main.go` 생성
  - [ ] 스케줄러 데몬 실행
  - [ ] 우아한 종료 처리
  - [ ] 설정 재로딩

### 8.8 스케줄러 테스트
- [ ] Mock 시간을 활용한 단위 테스트
- [ ] 분산 잠금 테스트
- [ ] 작업 재시도 테스트

---

## Phase 9: 작업 큐 시스템

### 목표
비동기 작업 처리 및 백그라운드 작업 관리

### 기술 스택
- **hibiken/asynq**: Redis 기반 작업 큐
- **Asynqmon**: 웹 UI 대시보드

### 9.1 의존성 추가
- [ ] `github.com/hibiken/asynq` 설치
- [ ] `github.com/hibiken/asynqmon` 설치

### 9.2 Queue Core 서비스 생성
- [ ] `internal/queue/core/` 패키지 생성
- [ ] `internal/queue/core/service.go`
  - [ ] 작업 등록 (Enqueue)
  - [ ] 작업 처리 (Process)
  - [ ] 우선순위 관리

### 9.3 작업 타입 정의
- [ ] `internal/queue/core/tasks.go`
  - [ ] `GenerateStoryTask`
  - [ ] `GenerateImageTask`
  - [ ] `GenerateTTSTask`
  - [ ] `ComposeVideoTask`
  - [ ] `UploadVideoTask`

### 9.4 작업 핸들러 구현
- [ ] `internal/queue/adapters/task_handlers.go`
  - [ ] 각 작업 타입별 핸들러
  - [ ] 에러 처리 및 재시도 로직
  - [ ] 진행률 업데이트

### 9.5 Queue Worker 구현
- [ ] `cmd/worker/main.go` 생성
  - [ ] 워커 프로세스 실행
  - [ ] 동시성 설정
  - [ ] 우아한 종료

### 9.6 Queue Dashboard 구현
- [ ] `cmd/dashboard/main.go` 생성
  - [ ] Asynqmon 웹 UI 실행
  - [ ] 작업 모니터링
  - [ ] 수동 작업 관리

### 9.7 CLI와 큐 통합
- [ ] CLI 명령어에 큐 옵션 추가
  - [ ] `--async` 플래그로 백그라운드 실행
  - [ ] 작업 상태 조회 명령어

### 9.8 스케줄러와 큐 통합
- [ ] 스케줄러에서 큐에 작업 등록
- [ ] 작업 완료 시 다음 단계 자동 실행

---

## Phase 10: 통합 테스트 및 최적화

### 목표
전체 시스템의 통합 테스트 및 성능 최적화

### 10.1 E2E 테스트 구현
- [ ] `tests/e2e/` 디렉토리 생성
- [ ] 전체 파이프라인 E2E 테스트
  - [ ] Story → Image → TTS → Video → Upload
  - [ ] 다양한 채널 타입 테스트
  - [ ] 에러 시나리오 테스트

### 10.2 성능 테스트
- [ ] 동시 처리 성능 테스트
- [ ] 메모리 사용량 프로파일링
- [ ] 병목 지점 식별 및 최적화

### 10.3 Docker 환경 구성
- [ ] `Dockerfile` 최적화
- [ ] `docker-compose.prod.yml` 생성
- [ ] 멀티 스테이지 빌드 적용

### 10.4 CI/CD 파이프라인 업데이트
- [ ] 새로운 테스트 단계 추가
- [ ] Docker 이미지 빌드 및 배포
- [ ] 환경별 배포 설정

### 10.5 문서화
- [ ] API 문서 업데이트
- [ ] CLI 사용법 가이드
- [ ] 배포 가이드
- [ ] 트러블슈팅 가이드

### 10.6 모니터링 준비
- [ ] 로그 구조 표준화
- [ ] 핵심 메트릭 정의
- [ ] 알림 규칙 설정

---

## 우선순위 및 일정

### 높은 우선순위 (핵심 기능)
1. **Phase 5**: Video 도메인 (동영상 합성) - 2주
2. **Phase 6**: YouTube 도메인 (업로드) - 2주
3. **Phase 7**: CLI 명령어 - 1주

### 중간 우선순위 (자동화)
4. **Phase 8**: 스케줄러 시스템 - 1주
5. **Phase 9**: 작업 큐 시스템 - 1주

### 낮은 우선순위 (최적화)
6. **Phase 10**: 통합 테스트 및 최적화 - 1주

**총 예상 기간**: 8주

---

---

# TDD 구현 가이드 (코드 생성 LLM용 프롬프트)

## Phase 5: Video 도메인 TDD 구현

### Step 5.1: 환경 설정 및 의존성 추가

```
YouTube Shorts 자동 생성 시스템의 Video 도메인 구현을 시작합니다.

**요구사항:**
- ffmpeg-go 패키지를 사용하여 동영상 합성 기능 구현
- Hexagonal Architecture 패턴 유지
- TDD 방식으로 테스트 먼저 작성

**작업 내용:**
1. go.mod에 github.com/u2takey/ffmpeg-go 의존성 추가
2. assets/audio/background/ 디렉토리 생성
3. 테스트용 배경음악 파일 준비 (또는 더미 파일)
4. ffmpeg 바이너리 설치 확인을 위한 헬퍼 함수 구현

**구현 가이드:**
- 기존 internal/video/ 구조 활용
- pkg/config/ 시스템과 통합하여 ffmpeg 경로 설정 가능하게 구현
- 에러 처리는 pkg/errors/ 패키지 사용

**검증 방법:**
- go mod tidy 실행 후 빌드 성공 확인
- ffmpeg 바이너리 존재 여부 확인하는 테스트 작성
```

### Step 5.2: Video Core Service TDD 구현

```
Video 도메인의 핵심 비즈니스 로직을 TDD로 구현합니다.

**요구사항:**
1. internal/video/core/service.go 완성
2. ComposeVideo 메서드 구현
3. 동영상 길이 계산 로직
4. Ken Burns 효과 설정 정의

**TDD 순서:**
1. 테스트 작성: internal/video/core/service_test.go
   - ComposeVideo 성공 케이스
   - 잘못된 입력 처리
   - 동영상 길이 계산 테스트
2. 실패하는 테스트 확인
3. 최소한의 구현으로 테스트 통과
4. 리팩토링

**인터페이스 설계:**
```go
type Service struct {
    composer ports.Composer
    validator ports.Validator
    logger *slog.Logger
}

func (s *Service) ComposeVideo(ctx context.Context, req *ComposeVideoRequest) (*ComposeVideoResponse, error)
```

**ComposeVideoRequest 구조:**
- Images []ImageFrame (경로, 표시시간)
- AudioPath string (TTS 파일 경로)
- BackgroundMusicPath string
- OutputPath string
- Settings VideoSettings (해상도, 품질 등)

**검증 기준:**
- 모든 테스트 통과
- 100% 코드 커버리지
- 기존 아키텍처 테스트 통과
```

### Step 5.3: FFmpeg Adapter TDD 구현

```
FFmpeg를 활용한 실제 동영상 합성 어댑터를 TDD로 구현합니다.

**요구사항:**
1. internal/video/adapters/ffmpeg_composer.go 생성
2. ports.Composer 인터페이스 구현
3. 이미지 시퀀스를 동영상으로 변환
4. Ken Burns 효과 적용
5. 오디오 믹싱 (TTS + 배경음악)

**TDD 순서:**
1. 테스트 작성: internal/video/adapters/ffmpeg_composer_test.go
   - FFmpeg 명령어 생성 테스트
   - 파일 입출력 테스트
   - 에러 처리 테스트
2. Mock 구현으로 인터페이스 검증
3. 실제 FFmpeg 호출 구현
4. 통합 테스트 (실제 파일 생성)

**핵심 기능:**
- 1080x1920 세로 포맷 출력
- Ken Burns 효과 (zoom, pan)
- 크로스페이드 전환
- 오디오 볼륨 조절 및 믹싱
- 출력 파일 형식: MP4

**FFmpeg 명령어 예시:**
```bash
ffmpeg -i image%d.jpg -i audio.wav -i bg_music.mp3 \
  -filter_complex "[0]scale=1080:1920,zoompan=z='zoom+0.001':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=25*3[v]; \
  [1][2]amix=inputs=2:duration=longest:dropout_transition=2[a]" \
  -map "[v]" -map "[a]" -c:v libx264 -c:a aac output.mp4
```

**검증 기준:**
- FFmpeg 명령어 생성 테스트 통과
- 실제 동영상 파일 생성 확인
- 해상도, 길이, 오디오 품질 검증
```

### Step 5.4: Video Validator TDD 구현

```
생성된 동영상 파일의 품질과 규격을 검증하는 Validator를 TDD로 구현합니다.

**요구사항:**
1. internal/video/core/validator.go 생성
2. ports.Validator 인터페이스 구현
3. 출력 파일 검증 로직

**검증 항목:**
- 파일 형식: MP4
- 해상도: 1080x1920
- 길이: 30-60초 범위
- 오디오 품질: 44.1kHz, 128kbps 이상
- 파일 크기: 적정 범위 내

**TDD 순서:**
1. 테스트 작성: internal/video/core/validator_test.go
   - 올바른 동영상 파일 검증 통과
   - 잘못된 해상도 검증 실패
   - 너무 짧거나 긴 동영상 검증 실패
   - 손상된 파일 검증 실패
2. 실패하는 테스트 확인
3. ffprobe를 활용한 검증 로직 구현
4. 에러 메시지 개선

**구현 방법:**
- ffprobe 명령어로 동영상 메타데이터 추출
- JSON 출력 파싱하여 규격 확인
- 커스텀 에러 타입으로 상세한 검증 실패 원인 제공

**검증 기준:**
- 모든 검증 테스트 통과
- 실제 동영상 파일로 통합 테스트
- 명확한 에러 메시지 제공
```

### Step 5.5: Video 도메인 통합 및 Mock 업데이트

```
Video 도메인의 모든 컴포넌트를 통합하고 Mock 구현을 완성합니다.

**요구사항:**
1. internal/video/adapters/mock_composer.go 완성
2. 전체 Video 도메인 통합 테스트
3. Container에 Video 서비스 등록

**Mock 구현:**
- 실제 동영상 파일 생성 대신 더미 파일 생성
- 모든 검증 로직은 실제와 동일하게 구현
- 테스트 속도 최적화를 위한 빠른 응답

**통합 테스트:**
1. Story → Image → TTS → Video 전체 파이프라인
2. 다양한 채널 타입별 동영상 생성
3. 에러 시나리오 테스트

**Container 통합:**
- internal/container/container.go에 Video 서비스 추가
- 의존성 주입 설정
- 설정 파일과 연동

**검증 기준:**
- 전체 아키텍처 테스트 통과
- Mock과 실제 구현 모두 동일한 인터페이스 구현
- CI/CD 파이프라인에서 모든 테스트 통과
```

## Phase 6: YouTube 도메인 TDD 구현

### Step 6.1: OAuth2 환경 설정

```
YouTube API 연동을 위한 OAuth2 인증 환경을 설정합니다.

**요구사항:**
1. Google Cloud Console YouTube API 활성화 가이드
2. OAuth2 관련 의존성 추가
3. 설정 파일 구조 설계

**의존성 추가:**
- google.golang.org/api/youtube/v3
- golang.org/x/oauth2

**설정 파일:**
configs/youtube_oauth.yaml 생성
```yaml
youtube:
  oauth2:
    client_id: ${YOUTUBE_CLIENT_ID}
    client_secret: ${YOUTUBE_CLIENT_SECRET}
    redirect_url: "http://localhost:8080/oauth2callback"
    scopes:
      - "https://www.googleapis.com/auth/youtube.upload"
  upload:
    privacy_status: "private"  # private, public, unlisted
    category_id: "22"  # People & Blogs
```

**환경변수:**
- YOUTUBE_CLIENT_ID
- YOUTUBE_CLIENT_SECRET

**검증 방법:**
- 설정 로딩 테스트
- OAuth2 설정 검증 테스트
```

### Step 6.2: YouTube Core Service TDD 구현

```
YouTube 업로드의 핵심 비즈니스 로직을 TDD로 구현합니다.

**요구사항:**
1. internal/youtube/core/service.go 완성
2. UploadVideo 메서드 구현
3. 메타데이터 생성 로직
4. 업로드 진행률 추적

**TDD 순서:**
1. 테스트 작성: internal/youtube/core/service_test.go
   - UploadVideo 성공 케이스
   - 메타데이터 생성 테스트
   - 진행률 콜백 테스트
   - 에러 처리 테스트
2. 실패하는 테스트 확인
3. 최소한의 구현으로 테스트 통과
4. 리팩토링

**인터페이스 설계:**
```go
type Service struct {
    uploader ports.Uploader
    metadataGen ports.MetadataGenerator
    logger *slog.Logger
}

func (s *Service) UploadVideo(ctx context.Context, req *UploadVideoRequest) (*UploadVideoResponse, error)
```

**UploadVideoRequest 구조:**
- VideoPath string
- ThumbnailPath string
- ChannelType string
- StoryContent string
- ProgressCallback func(percentage int)

**UploadVideoResponse 구조:**
- VideoID string
- VideoURL string
- UploadedAt time.Time

**검증 기준:**
- 모든 테스트 통과
- 메타데이터 생성 로직 검증
- 진행률 추적 기능 동작
```

### Step 6.3: YouTube API Adapter TDD 구현

```
실제 YouTube API를 호출하는 어댑터를 TDD로 구현합니다.

**요구사항:**
1. internal/youtube/adapters/youtube_client.go 생성
2. OAuth2 인증 플로우 구현
3. 동영상 업로드 API 호출
4. 토큰 저장 및 갱신 관리

**TDD 순서:**
1. 테스트 작성: internal/youtube/adapters/youtube_client_test.go
   - OAuth2 URL 생성 테스트
   - 토큰 교환 테스트 (Mock)
   - 동영상 업로드 테스트 (Mock)
   - 토큰 갱신 테스트
2. Mock HTTP 클라이언트로 API 응답 시뮬레이션
3. 실제 OAuth2 플로우 구현
4. YouTube API 호출 구현

**OAuth2 플로우:**
1. 인증 URL 생성
2. 사용자 브라우저에서 인증
3. 콜백으로 인증 코드 수신
4. 액세스 토큰 교환
5. 토큰 저장 (파일 또는 DB)

**API 호출:**
- videos.insert 메서드 사용
- 썸네일 업로드 (thumbnails.set)
- 재시도 로직 (API 할당량 초과 시)

**토큰 관리:**
- 액세스 토큰 만료 시 자동 갱신
- 리프레시 토큰 안전 저장
- 토큰 저장소 인터페이스 설계

**검증 기준:**
- Mock을 사용한 모든 API 호출 테스트 통과
- OAuth2 플로우 각 단계 검증
- 에러 처리 및 재시도 로직 테스트
```

### Step 6.4: 메타데이터 생성기 TDD 구현

```
채널별 맞춤형 메타데이터를 자동 생성하는 컴포넌트를 TDD로 구현합니다.

**요구사항:**
1. internal/youtube/core/metadata_generator.go 생성
2. 채널별 제목 템플릿
3. 설명 자동 생성
4. 태그 및 카테고리 설정

**TDD 순서:**
1. 테스트 작성: internal/youtube/core/metadata_generator_test.go
   - 채널별 제목 생성 테스트
   - 설명 자동 생성 테스트
   - 태그 생성 테스트
   - 특수문자 처리 테스트
2. 템플릿 엔진 구현
3. 채널별 설정 로딩
4. 텍스트 처리 및 검증

**메타데이터 생성 규칙:**
```yaml
# configs/channels/fairy_tale.yaml에 추가
youtube:
  title_templates:
    - "✨ {story_title} | 동화 이야기 #Shorts"
    - "🧚‍♀️ {story_title} | 마법같은 이야기"
  description_template: |
    {story_summary}
    
    📱 더 많은 동화 이야기를 보고 싶다면 구독해주세요!
    
    #동화 #이야기 #Shorts #감동 #교훈
  tags:
    - "동화"
    - "이야기" 
    - "Shorts"
    - "감동"
    - "교훈"
  category_id: "22"  # People & Blogs
```

**구현 기능:**
- 템플릿 변수 치환 ({story_title}, {story_summary})
- 제목 길이 제한 (100자)
- 설명 길이 제한 (5000자)
- 태그 개수 제한 (500자 총합)
- HTML 엔티티 인코딩

**검증 기준:**
- 모든 채널 타입별 메타데이터 생성 테스트
- 길이 제한 검증
- 특수문자 및 이모지 처리 확인
```

### Step 6.5: YouTube 도메인 통합 및 Mock 완성

```
YouTube 도메인의 모든 컴포넌트를 통합하고 테스트를 완성합니다.

**요구사항:**
1. internal/youtube/adapters/mock_uploader.go 완성
2. OAuth2 Mock 구현
3. 통합 테스트 작성

**Mock 구현:**
- 가짜 비디오 ID 생성 (UUID 사용)
- 업로드 진행률 시뮬레이션
- OAuth2 토큰 Mock 구현
- API 에러 시나리오 시뮬레이션

**통합 테스트:**
1. Video → YouTube 전체 플로우
2. 다양한 채널별 업로드 테스트
3. 에러 복구 시나리오
4. 메타데이터 생성 → 업로드 연동

**Container 통합:**
- YouTube 서비스를 DI 컨테이너에 등록
- 설정 파일과 연동
- Mock/실제 구현 전환 가능하게 설정

**검증 기준:**
- 전체 아키텍처 테스트 통과
- Mock과 실제 구현 모두 테스트
- OAuth2 플로우 시뮬레이션 완료
```

## Phase 7: CLI TDD 구현

### Step 7.1: CLI Root Command TDD 구현

```
Cobra 기반의 CLI 루트 명령어를 TDD로 구현합니다.

**요구사항:**
1. cmd/cli/main.go를 Cobra 기반으로 전환
2. 글로벌 플래그 설정
3. 설정 로딩 및 DI 컨테이너 초기화

**의존성 추가:**
- github.com/spf13/cobra
- github.com/spf13/viper (기존 설정 시스템 확장)

**TDD 순서:**
1. 테스트 작성: cmd/cli/main_test.go
   - CLI 앱 초기화 테스트
   - 글로벌 플래그 파싱 테스트
   - 설정 로딩 테스트
   - 도움말 메시지 테스트
2. 기본 Cobra 앱 구조 구현
3. 글로벌 플래그 추가
4. 설정 통합

**글로벌 플래그:**
- --env, -e: 환경 설정 (local, dev, prod)
- --config, -c: 설정 파일 경로
- --verbose, -v: 상세 로그 출력
- --dry-run: 실제 실행 없이 미리보기

**CLI 구조:**
```
ssulmeta-go [global flags] <command> [command flags] [arguments]

Commands:
  generate    Generate video content
  upload      Upload video to YouTube  
  list        List channels, videos, uploads
  config      Manage configuration
  pipeline    Run full pipeline (generate + upload)
```

**검증 기준:**
- CLI 앱 빌드 및 실행 성공
- 모든 글로벌 플래그 동작 확인
- 도움말 메시지 출력 확인
- 설정 로딩 및 검증 테스트 통과
```

### Step 7.2: CLI Generate Command TDD 구현

```
동영상 생성을 위한 generate 명령어를 TDD로 구현합니다.

**요구사항:**
1. cmd/cli/commands/generate.go 생성
2. 전체 파이프라인 실행 (Story → Image → TTS → Video)
3. 진행률 표시 및 에러 처리

**TDD 순서:**
1. 테스트 작성: cmd/cli/commands/generate_test.go
   - 채널 지정 파라미터 테스트
   - 출력 디렉토리 설정 테스트
   - 진행률 콜백 테스트
   - 에러 처리 테스트
2. 기본 명령어 구조 구현
3. 파이프라인 오케스트레이션 로직
4. 진행률 표시 UI 구현

**명령어 구조:**
```bash
ssulmeta-go generate --channel fairy_tale [--output ./output] [--dry-run]
```

**플래그:**
- --channel, -c: 채널 타입 (필수)
- --output, -o: 출력 디렉토리 (기본값: ./output)
- --dry-run: 실제 생성 없이 미리보기

**파이프라인 단계:**
1. 채널 설정 로딩 및 검증
2. Story 생성 (진행률 25%)
3. Image 생성 (진행률 50%)
4. TTS 생성 (진행률 75%)
5. Video 합성 (진행률 100%)

**진행률 표시:**
- 단계별 진행 상황 표시
- 현재 작업 내용 표시
- 예상 완료 시간 표시
- 에러 발생 시 상세 정보 출력

**에러 처리:**
- 각 단계별 에러 캐치 및 복구
- 부분 완료 상태 정보 제공
- 재시도 옵션 제공

**검증 기준:**
- Mock 환경에서 전체 파이프라인 실행 성공
- 진행률 표시 정확성 확인
- 에러 시나리오별 적절한 메시지 출력
- 출력 파일 생성 확인
```

### Step 7.3: CLI Upload Command TDD 구현

```
YouTube 업로드를 위한 upload 명령어를 TDD로 구현합니다.

**요구사항:**
1. cmd/cli/commands/upload.go 생성
2. OAuth2 인증 처리
3. 업로드 진행률 표시

**TDD 순서:**
1. 테스트 작성: cmd/cli/commands/upload_test.go
   - 파일 경로 검증 테스트
   - OAuth2 인증 플로우 테스트
   - 업로드 진행률 테스트
   - 메타데이터 설정 테스트
2. 기본 명령어 구조 구현
3. OAuth2 인증 UI 플로우
4. 업로드 진행률 표시

**명령어 구조:**
```bash
ssulmeta-go upload <video-file> --channel fairy_tale [--title "Custom Title"] [--private]
```

**플래그:**
- --channel, -c: 채널 타입 (필수, 메타데이터 생성용)
- --title, -t: 커스텀 제목 (옵션)
- --description, -d: 커스텀 설명 (옵션)
- --private: 비공개 업로드 (기본값: false)
- --auth: 새로운 인증 실행 (기존 토큰 무시)

**OAuth2 인증 플로우:**
1. 기존 토큰 확인
2. 토큰 없거나 만료 시 브라우저 열기
3. 사용자 인증 완료 대기
4. 토큰 저장 및 확인

**업로드 과정:**
1. 파일 존재 및 형식 검증
2. OAuth2 인증 확인/실행
3. 메타데이터 생성
4. 업로드 시작 (진행률 표시)
5. 썸네일 업로드 (있는 경우)
6. 완료 정보 출력 (Video ID, URL)

**검증 기준:**
- Mock YouTube API로 업로드 플로우 테스트
- OAuth2 인증 시나리오 테스트
- 파일 검증 및 에러 처리 확인
- 업로드 완료 후 정보 출력 확인
```

### Step 7.4: CLI 기타 Commands TDD 구현

```
List, Config, Pipeline 명령어를 TDD로 구현하고 CLI를 완성합니다.

**요구사항:**
1. List Command: 채널, 동영상, 업로드 목록 조회
2. Config Command: 설정 관리
3. Pipeline Command: 생성+업로드 통합 실행

**List Command (cmd/cli/commands/list.go):**
```bash
ssulmeta-go list channels          # 사용 가능한 채널 목록
ssulmeta-go list videos [path]     # 생성된 동영상 목록
ssulmeta-go list uploads           # 업로드된 동영상 목록 (YouTube API)
```

**Config Command (cmd/cli/commands/config.go):**
```bash
ssulmeta-go config init            # 초기 설정 파일 생성
ssulmeta-go config show [key]      # 현재 설정 표시
ssulmeta-go config set key=value   # 설정 값 변경
ssulmeta-go config validate        # 설정 검증
```

**Pipeline Command (cmd/cli/commands/pipeline.go):**
```bash
ssulmeta-go pipeline run --channel fairy_tale [--upload] [--schedule]
```

**TDD 구현 순서:**
1. 각 명령어별 테스트 작성
2. 기본 구조 구현
3. 비즈니스 로직 연동
4. 출력 포맷팅 및 UI 개선

**통합 테스트:**
- E2E CLI 테스트 실행
- 모든 명령어 조합 테스트
- 에러 시나리오 검증
- 도움말 및 사용법 검증

**검증 기준:**
- 모든 CLI 명령어 정상 동작
- 사용자 친화적인 출력 형식
- 에러 메시지 명확성
- CLI 테스트 100% 커버리지
```

---

## 주의사항

### 개발 가이드라인
- Hexagonal Architecture 원칙 준수
- TDD 사이클 엄격히 준수: Red → Green → Refactor
- 모든 새 기능에 대한 단위 테스트 작성
- Mock 구현을 통한 테스트 가능성 확보
- 기존 설정 시스템과의 일관성 유지

### TDD 원칙
1. **Red**: 실패하는 테스트 먼저 작성
2. **Green**: 테스트를 통과하는 최소한의 코드 작성
3. **Refactor**: 코드 품질 개선 (테스트는 유지)
4. **Integration**: 다른 컴포넌트와 통합
5. **Documentation**: 코드 문서화 및 사용법 작성

### API 키 관리
- YouTube API 키는 환경변수로 관리
- OAuth2 토큰은 안전한 저장소에 보관
- 프로덕션 환경에서는 시크릿 관리 도구 사용

### 리소스 관리
- 임시 파일은 작업 완료 후 정리
- 메모리 사용량 모니터링
- API 할당량 관리 (YouTube, OpenAI 등)

### 에러 처리
- 외부 API 실패 시 재시도 메커니즘
- 부분 실패 시 복구 가능한 상태 유지
- 명확한 에러 메시지 및 로깅

### 테스트 전략
- **단위 테스트**: 각 함수/메서드의 로직 검증
- **통합 테스트**: 컴포넌트 간 연동 검증
- **E2E 테스트**: 전체 파이프라인 검증
- **Mock 테스트**: 외부 의존성 격리 테스트