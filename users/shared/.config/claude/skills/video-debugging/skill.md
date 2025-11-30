---
name: video-debugging
description: 비디오 파일 품질 평가 및 문제 진단 - FFprobe 메타데이터 분석, 자동 프레임 추출, Claude 시각 분석을 통한 체계적 워크플로우 (user)
---

# Video Debugging

## Overview

비디오 파일의 품질 평가와 문제를 체계적으로 진단: **Triage → Categorize → Analyze → Diagnose → Recommend**.

**핵심 원칙:** 참조 영상 없이 작동. 트리아지 우선으로 30초 내 문제 카테고리 파악.

## When to Use

**사용 대상:**
- 비디오 파일 재생 문제 (깨짐, 재생 불가)
- 품질 저하 진단 (블로킹, 블러링, 압축 아티팩트)
- 인코딩 후 품질 평가
- A/V 동기화 문제
- 코덱/컨테이너 호환성 검증

**사용 안 함:**
- 실시간 스트리밍 문제 (네트워크 이슈는 범위 외)
- 비디오 편집 작업 (자르기, 합치기 등)

## Core Workflow

```
1. TRIAGE: 빠른 메타데이터 분석으로 문제 카테고리 식별 (30초)
2. CATEGORIZE: 문제 유형 분류 (코덱/컨테이너/품질/손상/동기화/평가)
3. ANALYZE: 카테고리별 심화 분석 (프레임 추출 포함)
4. DIAGNOSE: 근본 원인 파악
5. RECOMMEND: 해결 방안 제시
```

**모든 단계 필수. 건너뛰기 금지.**

## Step 1: TRIAGE - 초기 진단

**목표**: 30초 내 기본 정보 수집 및 카테고리 파악

### 필수 명령어 실행

```bash
# 1. 기본 메타데이터 추출
ffprobe -v error -show_format -show_streams -of json "$VIDEO_FILE"

# 2. 파일 무결성 빠른 체크
ffmpeg -v error -i "$VIDEO_FILE" -f null - 2>&1

# 3. 비디오 스트림 핵심 정보
ffprobe -v error -select_streams v:0 \
  -show_entries stream=codec_name,width,height,r_frame_rate,bit_rate,pix_fmt,duration \
  -of default=noprint_wrappers=1 "$VIDEO_FILE"

# 4. 오디오 스트림 확인
ffprobe -v error -select_streams a:0 \
  -show_entries stream=codec_name,sample_rate,channels \
  -of default=noprint_wrappers=1 "$VIDEO_FILE"
```

### 자동 카테고리 분류

| 증상 | 카테고리 | 다음 단계 |
|------|----------|-----------|
| ffmpeg 에러 발생 | **CORRUPTED** (손상) | Step 2-A |
| 재생 불가 메타데이터 | **CONTAINER** (컨테이너) | Step 2-B |
| 비트레이트 < 500kbps 또는 품질 의심 | **QUALITY** (품질 저하) | Step 2-C |
| 코덱 호환성 의심 | **CODEC** (코덱) | Step 2-D |
| A/V duration 불일치 > 1초 | **SYNC** (동기화) | Step 2-E |
| 정상 메타데이터, 특정 문제 없음 | **ASSESSMENT** (평가) | Step 2-F |

**TodoWrite 필수**: 분류된 카테고리를 todo 항목으로 추가 (예: "QUALITY 카테고리 심화 분석")

## Step 2-C: QUALITY (품질 저하) - 가장 흔한 케이스

### 진단 순서

1. **비트레이트 분석**
   ```bash
   # 평균 비트레이트
   ffprobe -v error -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1 "$VIDEO_FILE"

   # 프레임별 패킷 크기 (변동성 확인)
   ffprobe -v error -select_streams v:0 -show_entries frame=pkt_size -of csv "$VIDEO_FILE" | head -100
   ```

2. **프레임 자동 추출** (영상 길이 기반)

   **길이 확인:**
   ```bash
   DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$VIDEO_FILE")
   ```

   **전략 선택:**

   - **짧은 영상 (< 60초)**: 모든 I-프레임
     ```bash
     ffmpeg -skip_frame nokey -i "$VIDEO_FILE" -vsync vfr -frame_pts true frames/frame-%d.jpg
     ```

   - **중간 영상 (60-600초)**: I-프레임 + 장면 변화
     ```bash
     ffmpeg -i "$VIDEO_FILE" -vf "select='eq(pict_type,I)+gt(scene,0.4)'" -vsync vfr frames/frame-%d.jpg
     ```

   - **긴 영상 (> 600초)**: I-프레임 + 5초 간격
     ```bash
     ffmpeg -i "$VIDEO_FILE" -vf "select='eq(pict_type,I)',fps=1/5" -vsync vfr frames/frame-%d.jpg
     ```

3. **Claude 시각 분석**

   추출된 프레임을 Read 도구로 로드하여 다음 항목 체크:

   - [ ] **블로킹**: 8x8 또는 16x16 블록 경계 보임 (DCT 압축 아티팩트)
   - [ ] **블러링**: 엣지 선명도 저하, 텍스처 디테일 손실
   - [ ] **색상 출혈**: 색상 경계에서 의도하지 않은 확산
   - [ ] **모기 노이즈**: 객체 주변 흐르는 듯한 아티팩트
   - [ ] **밴딩**: 그라데이션에서 띠 현상 (비트 깊이 부족)
   - [ ] **색상 정확성**: 부자연스러운 색조, 채도 문제
   - [ ] **밝기 균일성**: 예상치 못한 어두운/밝은 영역

## Step 2-A: CORRUPTED (파일 손상)

### 진단 순서

1. **비트스트림 상세 에러 감지**
   ```bash
   ffmpeg -err_detect bitstream+crccheck+explode -i "$VIDEO_FILE" -f null - 2>&1
   ```

2. **재생 가능 구간 식별**
   ```bash
   # 손상된 부분 스킵 시도
   ffmpeg -i "$VIDEO_FILE" -c copy -avoid_negative_ts 1 recovered.mp4 2>&1
   ```

3. **트레이스 헤더 분석** (H.264/HEVC)
   ```bash
   ffmpeg -bsf:v trace_headers -i "$VIDEO_FILE" -f null - 2>&1 | head -100
   ```

### 복구 가능성 평가

- **전체 손상**: 재생성 권고
- **부분 손상**: 재생 가능 구간 추출 제안
- **메타데이터만 손상**: 리먹싱으로 복구 가능

## Step 2-B: CONTAINER (컨테이너 문제)

### 진단 순서

1. **컨테이너 포맷 확인**
   ```bash
   ffprobe -v error -show_entries format=format_name,format_long_name -of default=noprint_wrappers=1 "$VIDEO_FILE"
   ```

2. **호환성 검증**

   **MP4**: moov atom 위치 확인 (스트리밍은 파일 앞에 필요)
   ```bash
   # moov atom이 파일 끝에 있으면 스트리밍 불가
   ffmpeg -i "$VIDEO_FILE" -c copy -movflags +faststart output.mp4
   ```

   **AVI**: 인덱스 체인 존재 여부

   **MKV/WebM**: 클러스터 타임코드 일관성

3. **리먹싱 필요 여부 판단**

## Step 2-D: CODEC (코덱 호환성)

### 진단 순서

1. **코덱 프로필/레벨 확인**
   ```bash
   ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,profile,level -of default=noprint_wrappers=1 "$VIDEO_FILE"
   ```

2. **플랫폼별 호환성 평가**

   | 코덱 | 호환성 | 비고 |
   |------|--------|------|
   | H.264 Baseline | 모든 디바이스 | 가장 안전 |
   | H.264 Main | 대부분 디바이스 | 일반적 선택 |
   | H.264 High | 신형 디바이스 | 압축 효율 높음 |
   | H.264 High 10-bit | 최신만 | 10-bit 색심도 |
   | VP9 | 2B+ 엔드포인트 | 무료, H.264 대비 50% 향상 |
   | AV1 | 최신만 (Safari 미지원) | VP9 대비 30-50% 향상 |

3. **대안 코덱/설정 제안**

## Step 2-E: SYNC (A/V 동기화)

### 진단 순서

1. **Duration 비교**
   ```bash
   # 비디오 duration
   ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "$VIDEO_FILE"

   # 오디오 duration
   ffprobe -v error -select_streams a:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "$VIDEO_FILE"
   ```

2. **PTS/DTS 타임스탬프 분석**
   ```bash
   # 비디오 타임스탬프 샘플
   ffprobe -show_frames -select_streams v:0 -show_entries frame=pkt_pts_time -of csv "$VIDEO_FILE" | head -20

   # 오디오 타임스탬프 샘플
   ffprobe -show_frames -select_streams a:0 -show_entries frame=pkt_pts_time -of csv "$VIDEO_FILE" | head -20
   ```

3. **드리프트 측정**

   시작/중간/끝 지점의 A/V offset 비교

## Step 2-F: ASSESSMENT (일반 평가)

메타데이터 정상, 특정 문제 없을 때:

1. **기본 스펙 리포트**
   - 해상도, 프레임율, 비트레이트
   - 코덱 프로필
   - Duration, 파일 크기
   - 예상 호환성

2. **선택적 프레임 샘플링**

   사용자가 시각적 품질 확인 요청 시만 프레임 추출

3. **최적화 제안** (있다면)
   - 비트레이트 조정 권고
   - 코덱 업그레이드 제안
   - 컨테이너 최적화

## Step 4: DIAGNOSE - 근본 원인

각 카테고리별 분석 결과를 종합하여 근본 원인 파악:

- **단일 원인**: 명확한 문제점 식별
- **복합 원인**: 여러 문제의 연관성 분석
- **우선순위**: 가장 영향이 큰 문제부터 정렬

**CRITICAL**: 증상이 아닌 근본 원인을 찾아야 함. "재생이 안 됨"이 증상이라면, "moov atom이 파일 끝에 위치"가 근본 원인.

## Step 5: RECOMMEND - 해결 방안

### 카테고리별 구체적 권고

**QUALITY (품질 저하)**
```bash
# 재인코딩 파라미터 예시
ffmpeg -i "$VIDEO_FILE" -c:v libx264 -crf 23 -preset medium \
  -c:a aac -b:a 128k output.mp4

# CRF 값: 18-28 (낮을수록 고품질, 23 권장)
```

**CONTAINER (컨테이너 문제)**
```bash
# MP4 스트리밍 최적화
ffmpeg -i "$VIDEO_FILE" -c copy -movflags +faststart output.mp4

# 리먹싱 (코덱 변경 없이)
ffmpeg -i input.avi -c copy output.mp4
```

**CODEC (코덱 호환성)**
```bash
# H.264 Baseline으로 트랜스코딩 (최대 호환성)
ffmpeg -i "$VIDEO_FILE" -c:v libx264 -profile:v baseline -level 3.0 \
  -c:a aac output.mp4
```

**CORRUPTED (손상)**
- 복구 불가능: 원본 재생성 권고
- 부분 복구: 재생 가능 구간 추출 명령어 제공

**SYNC (동기화)**
```bash
# 오디오 오프셋 조정 (0.5초 지연 예시)
ffmpeg -i "$VIDEO_FILE" -itsoffset 0.5 -i "$VIDEO_FILE" -map 0:v -map 1:a -c copy output.mp4
```

### 실행 전 확인사항

**CRITICAL**: 실제 파일 수정은 사용자 확인 후에만 실행

1. 명령어 제시 및 설명
2. 예상 결과 안내
3. 사용자 명시적 허가 대기
4. 실행 후 검증

## Red Flags - STOP

다음 행동은 금지:

- "프레임 추출 건너뛰고 추측" → Step 3 프레임 분석 필수 (QUALITY 카테고리)
- "메타데이터만 보고 결론" → 시각적 품질은 반드시 프레임으로 확인
- "여러 문제 동시 수정" → 한 번에 하나씩, 검증 후 다음
- "사용자 확인 없이 파일 수정" → 읽기 전용 분석, 수정은 명시적 허가 후
- "긴 영상이라 전체 스킵" → 샘플링 전략 적용, 완전 스킵 금지
- "FFmpeg 에러 무시하고 진행" → 에러는 항상 중요한 정보 포함
- "Step 1 트리아지 생략" → 모든 케이스에서 트리아지부터 시작
- "참조 영상 요구" → 이 스킬은 참조 없이 작동하도록 설계됨

## Quick Reference

| 증상 | 첫 번째 체크 | 일반적 원인 |
|------|-------------|-----------|
| **재생 불가** | ffmpeg 무결성 체크 | 손상 또는 컨테이너 문제 |
| **품질 저하** | 비트레이트 + 프레임 분석 | 저비트레이트, 과도한 압축 |
| **블로킹 보임** | I-프레임 추출 | DCT 압축, 저비트레이트 |
| **A/V 불일치** | Duration 비교 | 인코딩 설정, 스트림 문제 |
| **일부 디바이스 재생 불가** | 코덱 프로필 확인 | 호환성 문제 |
| **스트리밍 안 됨** | moov atom 위치 | MP4 메타데이터 위치 |

## Core Principles

**속도보다 정확성**:
- 트리아지는 30초지만, 전체 워크플로우는 필요한 만큼
- 모든 단계 완료 필수

**자동화와 검증**:
- 프레임 추출, 메타데이터 분석 자동화
- Claude 분석 결과는 사용자에게 명확히 제시

**참조 없이 작동**:
- PSNR/SSIM 같은 참조 기반 메트릭 의존 안 함
- 절대적 품질 기준과 시각적 분석으로 평가

**TodoWrite 필수**:
- 각 단계를 todo 항목으로 추적
- 여러 프레임 분석 시 진행상황 가시화

**모든 단계 필수. 압박 상황에서도 단계 생략 금지. 규칙의 글자를 위반하면 정신도 위반하는 것.**
