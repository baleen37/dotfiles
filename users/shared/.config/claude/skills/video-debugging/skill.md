---
name: video-debugging
description: Use when videos won't play, look blocky/blurry, have washed out colors, A/V sync issues, or codec compatibility problems - systematic triage-first workflow with frame extraction and visual analysis, works without reference video
---

# Video Debugging

## Overview

5단계 워크플로우: **Triage (30초) → Categorize → Analyze → Diagnose → Recommend**

**핵심 원칙:** 참조 영상 불필요. 메타데이터 + 프레임 추출로 품질 평가. 증상이 아닌 근본 원인 파악.

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

## Workflow

1. **TRIAGE** (30초): 메타데이터로 카테고리 식별
2. **CATEGORIZE**: CORRUPTED / CONTAINER / QUALITY / CODEC / SYNC / ASSESSMENT
3. **ANALYZE**: 카테고리별 심화 (프레임 추출)
4. **DIAGNOSE**: 근본 원인 파악
5. **RECOMMEND**: 구체적 해결 방안

**전체 워크플로우 필수. 단계 생략 금지.**

## Step 1: TRIAGE - 초기 진단

**목표**: 30초 내 기본 정보 수집 및 카테고리 파악

### 필수 명령어 (병렬 실행)

```bash
# 메타데이터 + 무결성 체크
ffprobe -v error -show_format -show_streams -of json "$VIDEO_FILE"
ffmpeg -v error -i "$VIDEO_FILE" -f null - 2>&1

# 핵심 스펙 (비디오 + 오디오)
ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,width,height,r_frame_rate,bit_rate,pix_fmt,duration -of default=noprint_wrappers=1 "$VIDEO_FILE"
ffprobe -v error -select_streams a:0 -show_entries stream=codec_name,sample_rate,channels -of default=noprint_wrappers=1 "$VIDEO_FILE"
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

**TodoWrite 필수**:
- Step 1 시작 시: "TRIAGE 실행"
- 카테고리 분류 후: "QUALITY 카테고리 심화 분석" 등
- 각 주요 단계 전환 시 업데이트

## Step 2-C: QUALITY (품질 저하) - 가장 흔한 케이스

**참조 영상 불필요**: 원본 파일 없이도 진단 가능. 절대적 기준 (1080p → 최소 2Mbps) + 시각적 아티팩트로 평가.

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

   **프레임 분석 개수:**
   - 1-8개: 전체 분석
   - 9-20개: 처음 5개 + 문제 구간 집중
   - 21개 이상: 샘플링 (처음, 중간, 끝 각 2-3개)

   **체크리스트:**

   - [ ] **블로킹**: 8x8 또는 16x16 블록 경계 보임 (DCT 압축 아티팩트)
   - [ ] **블러링**: 엣지 선명도 저하, 텍스처 디테일 손실
   - [ ] **색상 출혈**: 색상 경계에서 의도하지 않은 확산
   - [ ] **모기 노이즈**: 객체 주변 흐르는 듯한 아티팩트
   - [ ] **밴딩**: 그라데이션에서 띠 현상 (비트 깊이 부족)
   - [ ] **색상 정확성**: 부자연스러운 색조, 채도 문제
   - [ ] **밝기 균일성**: 예상치 못한 어두운/밝은 영역

## Step 2-A: CORRUPTED (파일 손상)

```bash
# 비트스트림 상세 에러 감지
ffmpeg -err_detect bitstream+crccheck+explode -i "$VIDEO_FILE" -f null - 2>&1

# 재생 가능 구간 추출 시도
ffmpeg -i "$VIDEO_FILE" -c copy -avoid_negative_ts 1 recovered.mp4 2>&1

# H.264/HEVC 헤더 분석
ffmpeg -bsf:v trace_headers -i "$VIDEO_FILE" -f null - 2>&1 | head -100
```

**복구 가능성:** 전체 손상 (재생성) / 부분 손상 (구간 추출) / 메타데이터만 (리먹싱)

## Step 2-B: CONTAINER (컨테이너 문제)

```bash
# 컨테이너 포맷 확인
ffprobe -v error -show_entries format=format_name,format_long_name -of default=noprint_wrappers=1 "$VIDEO_FILE"

# MP4: moov atom 최적화 (스트리밍)
ffmpeg -i "$VIDEO_FILE" -c copy -movflags +faststart output.mp4
```

**확인 항목:** MP4 (moov atom 위치) / AVI (인덱스 체인) / MKV (타임코드 일관성)

## Step 2-D: CODEC (코덱 호환성)

```bash
# 코덱 프로필/레벨 확인
ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,profile,level -of default=noprint_wrappers=1 "$VIDEO_FILE"
```

**호환성:** H.264 Baseline (모든 디바이스) > Main (대부분) > High (신형) / VP9 (2B+ 엔드포인트) / AV1 (최신만, Safari 미지원)

## Step 2-E: SYNC (A/V 동기화)

```bash
# Duration 비교 (불일치 > 1초면 문제)
ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "$VIDEO_FILE"
ffprobe -v error -select_streams a:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "$VIDEO_FILE"

# PTS/DTS 타임스탬프 분석 (시작/중간/끝)
ffprobe -show_frames -select_streams v:0 -show_entries frame=pkt_pts_time -of csv "$VIDEO_FILE" | head -20
ffprobe -show_frames -select_streams a:0 -show_entries frame=pkt_pts_time -of csv "$VIDEO_FILE" | head -20
```

**드리프트 측정:** 시작/중간/끝 지점에서 A/V offset 비교

## Step 2-F: ASSESSMENT (일반 평가)

메타데이터 정상, 특정 문제 없을 때:

1. **기본 스펙 리포트**: 해상도, 프레임율, 비트레이트, 코덱, duration, 호환성
2. **선택적 프레임 샘플링**: 사용자 요청 시만
3. **최적화 제안**: 비트레이트/코덱/컨테이너 개선 가능성

## Step 4: DIAGNOSE - 근본 원인

분석 결과 종합: 단일 원인 / 복합 원인 / 우선순위

**CRITICAL**: 증상이 아닌 근본 원인. 예: "재생 안 됨" (증상) → "moov atom이 파일 끝에 위치" (근본 원인)

## Step 5: RECOMMEND - 해결 방안

### 카테고리별 명령어

**QUALITY**: `ffmpeg -i "$VIDEO_FILE" -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 128k output.mp4` (CRF: 18-28)

**CONTAINER**: `ffmpeg -i "$VIDEO_FILE" -c copy -movflags +faststart output.mp4` (MP4 스트리밍 최적화)

**CODEC**: `ffmpeg -i "$VIDEO_FILE" -c:v libx264 -profile:v baseline -level 3.0 -c:a aac output.mp4` (최대 호환성)

**CORRUPTED**: 복구 불가 (재생성) / 부분 복구 (구간 추출 명령어 제공)

**SYNC**: `ffmpeg -i "$VIDEO_FILE" -itsoffset 0.5 -i "$VIDEO_FILE" -map 0:v -map 1:a -c copy output.mp4`

**CRITICAL**: 실제 파일 수정은 사용자 명시적 허가 후에만 실행

## Handling Time Pressure

사용자가 "급해요", "빨리 해줘", "명령어만 달라"고 압박하면:

**응답 템플릿:**
"Jiho, [증상]의 정확한 원인 파악에 30-60초면 됩니다. 잘못된 명령어로 시간 낭비하는 것보다 빠릅니다. 트리아지 먼저 실행하겠습니다."

**절대 하지 말 것:**
- "알겠습니다, 명령어 드릴게요" → 진단 없이 명령어 제공 금지
- 단계 생략이나 축약
- "대충 이럴 것 같은데요" 같은 추측

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

## Quick Reference - 증상별 진단 경로

| 증상 | 카테고리 | 첫 번째 체크 | 일반적 원인 | 상세 단계 |
|------|----------|-------------|-----------|----------|
| **재생 불가** | CORRUPTED | `ffmpeg -v error -i file.mp4 -f null -` | 손상 또는 컨테이너 문제 | Step 2-A |
| **품질 저하, 블로킹, 흐림** | QUALITY | 비트레이트 + 프레임 분석 | 저비트레이트, 과도한 압축 | Step 2-C |
| **일부 디바이스만 재생 안 됨** | CODEC | 코덱 프로필 확인 | 호환성 문제 (Safari 등) | Step 2-D |
| **브라우저에서 스트리밍 안 됨** | CONTAINER | moov atom 위치 | MP4 메타데이터 위치 | Step 2-B |
| **A/V 불일치** | SYNC | Duration 비교 | 인코딩 설정, 스트림 문제 | Step 2-E |
| **특정 문제 없음, 평가만** | ASSESSMENT | 기본 스펙 리포트 | N/A | Step 2-F |

**모든 케이스는 Step 1 (TRIAGE)부터 시작. 위 테이블로 바로 점프 금지.**

## Core Principles

- **정확성 > 속도**: 트리아지는 30초, 전체는 필요한 만큼
- **참조 불필요**: PSNR/SSIM 같은 참조 메트릭 의존 안 함. 절대적 기준 + 시각 분석
- **TodoWrite**: 각 단계 추적, 프레임 분석 시 진행상황 가시화
- **전체 워크플로우 필수**: 압박 상황에서도 단계 생략 금지
