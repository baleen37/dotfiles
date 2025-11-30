---
name: video-debugging
description: Use when videos won't play, look blocky/blurry, have washed out colors, A/V sync issues, or codec compatibility problems - systematic triage-first workflow with frame extraction and visual analysis, works without reference video
---

# Video Debugging

## Overview

5-step workflow: **Triage (30s) → Categorize → Analyze → Diagnose → Recommend**

**Core principle:** No reference video needed. Evaluate quality via metadata + frame extraction. Find root cause, not symptoms.

## When to Use

**Use for:**
- Video playback issues (corruption, won't play)
- Quality degradation diagnosis (blocking, blurring, compression artifacts)
- Post-encoding quality assessment
- A/V sync problems
- Codec/container compatibility verification

**Don't use for:**
- Live streaming issues (network problems out of scope)
- Video editing tasks (cutting, merging, etc.)

## Workflow

1. **TRIAGE** (30s): Identify category via metadata
2. **CATEGORIZE**: CORRUPTED / CONTAINER / QUALITY / CODEC / SYNC / ASSESSMENT
3. **ANALYZE**: Deep dive by category (frame extraction)
4. **DIAGNOSE**: Identify root cause
5. **RECOMMEND**: Specific solutions

**Complete workflow required. No skipping steps.**

## Step 1: TRIAGE - Initial Diagnosis

**Goal**: Gather basic info and categorize within 30 seconds

### Required Commands (run in parallel)

```bash
# Metadata + integrity check
ffprobe -v error -show_format -show_streams -of json "$VIDEO_FILE"
ffmpeg -v error -i "$VIDEO_FILE" -f null - 2>&1

# Core specs (video + audio)
ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,width,height,r_frame_rate,bit_rate,pix_fmt,duration -of default=noprint_wrappers=1 "$VIDEO_FILE"
ffprobe -v error -select_streams a:0 -show_entries stream=codec_name,sample_rate,channels -of default=noprint_wrappers=1 "$VIDEO_FILE"
```

### Auto-Categorization

| Symptom | Category | Next Step |
|---------|----------|-----------|
| ffmpeg errors | **CORRUPTED** (corruption) | Step 2-A |
| Unplayable metadata | **CONTAINER** (container) | Step 2-B |
| Bitrate < 500kbps or quality concerns | **QUALITY** (degradation) | Step 2-C |
| Codec compatibility issues | **CODEC** (codec) | Step 2-D |
| A/V duration mismatch > 1s | **SYNC** (synchronization) | Step 2-E |
| Normal metadata, no specific issues | **ASSESSMENT** (evaluation) | Step 2-F |

**TodoWrite required**:
- Step 1 start: "TRIAGE execution"
- After categorization: "QUALITY category deep analysis", etc.
- Update at each major step transition

## Step 2-C: QUALITY (Degradation) - Most Common Case

**No reference needed**: Can diagnose without original file. Use absolute standards (1080p → minimum 2Mbps) + visual artifact analysis.

### Diagnosis Steps

1. **Bitrate Analysis**
   ```bash
   # Average bitrate
   ffprobe -v error -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1 "$VIDEO_FILE"

   # Per-frame packet size (check variance)
   ffprobe -v error -select_streams v:0 -show_entries frame=pkt_size -of csv "$VIDEO_FILE" | head -100
   ```

2. **Auto Frame Extraction** (based on duration)

   **Check duration:**
   ```bash
   DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$VIDEO_FILE")
   ```

   **Strategy selection:**

   - **Short video (< 60s)**: All I-frames
     ```bash
     ffmpeg -skip_frame nokey -i "$VIDEO_FILE" -vsync vfr -frame_pts true frames/frame-%d.jpg
     ```

   - **Medium video (60-600s)**: I-frames + scene changes
     ```bash
     ffmpeg -i "$VIDEO_FILE" -vf "select='eq(pict_type,I)+gt(scene,0.4)'" -vsync vfr frames/frame-%d.jpg
     ```

   - **Long video (> 600s)**: I-frames + 5s intervals
     ```bash
     ffmpeg -i "$VIDEO_FILE" -vf "select='eq(pict_type,I)',fps=1/5" -vsync vfr frames/frame-%d.jpg
     ```

3. **Claude Visual Analysis**

   Load extracted frames with Read tool and check:

   **Frame analysis count:**
   - 1-8 frames: Analyze all
   - 9-20 frames: First 5 + problem areas
   - 21+ frames: Sample (first, middle, end - 2-3 each)

   **Checklist:**

   - [ ] **Blocking**: 8x8 or 16x16 block boundaries visible (DCT compression artifacts)
   - [ ] **Blurring**: Edge sharpness degraded, texture detail lost
   - [ ] **Color bleeding**: Unintended color spread at boundaries
   - [ ] **Mosquito noise**: Flowing artifacts around objects
   - [ ] **Banding**: Striping in gradients (insufficient bit depth)
   - [ ] **Color accuracy**: Unnatural hue, saturation issues
   - [ ] **Brightness uniformity**: Unexpected dark/bright areas

## Step 2-A: CORRUPTED (File Corruption)

```bash
# Detailed bitstream error detection
ffmpeg -err_detect bitstream+crccheck+explode -i "$VIDEO_FILE" -f null - 2>&1

# Extract playable segments
ffmpeg -i "$VIDEO_FILE" -c copy -avoid_negative_ts 1 recovered.mp4 2>&1

# H.264/HEVC header analysis
ffmpeg -bsf:v trace_headers -i "$VIDEO_FILE" -f null - 2>&1 | head -100
```

**Recovery possibility:** Complete corruption (regenerate) / Partial corruption (extract segments) / Metadata only (remux)

## Step 2-B: CONTAINER (Container Issues)

```bash
# Container format check
ffprobe -v error -show_entries format=format_name,format_long_name -of default=noprint_wrappers=1 "$VIDEO_FILE"

# MP4: moov atom optimization (streaming)
ffmpeg -i "$VIDEO_FILE" -c copy -movflags +faststart output.mp4
```

**Check items:** MP4 (moov atom location) / AVI (index chain) / MKV (timecode consistency)

## Step 2-D: CODEC (Codec Compatibility)

```bash
# Codec profile/level check
ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,profile,level -of default=noprint_wrappers=1 "$VIDEO_FILE"
```

**Compatibility:** H.264 Baseline (all devices) > Main (most) > High (modern) / VP9 (2B+ endpoints) / AV1 (latest only, Safari unsupported)

## Step 2-E: SYNC (A/V Synchronization)

```bash
# Duration comparison (mismatch > 1s = problem)
ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "$VIDEO_FILE"
ffprobe -v error -select_streams a:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "$VIDEO_FILE"

# PTS/DTS timestamp analysis (start/middle/end)
ffprobe -show_frames -select_streams v:0 -show_entries frame=pkt_pts_time -of csv "$VIDEO_FILE" | head -20
ffprobe -show_frames -select_streams a:0 -show_entries frame=pkt_pts_time -of csv "$VIDEO_FILE" | head -20
```

**Drift measurement:** Compare A/V offset at start/middle/end points

## Step 2-F: ASSESSMENT (General Evaluation)

When metadata is normal with no specific issues:

1. **Basic spec report**: Resolution, framerate, bitrate, codec, duration, compatibility
2. **Optional frame sampling**: Only when user requests visual quality check
3. **Optimization suggestions**: Potential bitrate/codec/container improvements

## Step 4: DIAGNOSE - Root Cause

Synthesize analysis results: Single cause / Multiple causes / Priority

**CRITICAL**: Find root cause, not symptoms. Example: "won't play" (symptom) → "moov atom at end of file" (root cause)

## Step 5: RECOMMEND - Solutions

### Commands by Category

**QUALITY**: `ffmpeg -i "$VIDEO_FILE" -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 128k output.mp4` (CRF: 18-28)

**CONTAINER**: `ffmpeg -i "$VIDEO_FILE" -c copy -movflags +faststart output.mp4` (MP4 streaming optimization)

**CODEC**: `ffmpeg -i "$VIDEO_FILE" -c:v libx264 -profile:v baseline -level 3.0 -c:a aac output.mp4` (maximum compatibility)

**CORRUPTED**: Unrecoverable (regenerate) / Partial recovery (provide segment extraction command)

**SYNC**: `ffmpeg -i "$VIDEO_FILE" -itsoffset 0.5 -i "$VIDEO_FILE" -map 0:v -map 1:a -c copy output.mp4`

**CRITICAL**: Execute file modifications only after explicit user permission

## Handling Time Pressure

When user pressures with "hurry", "quick", "just give me the command":

**Response template:**
"Identifying the exact cause of [symptom] takes 30-60 seconds. Faster than wasting time with wrong commands. Running triage first."

**Never do:**
- "Okay, here's the command" → No commands without diagnosis
- Skip or abbreviate steps
- Speculation like "probably this..."

## Red Flags - STOP

Forbidden actions:

- "Skip frame extraction and guess" → Step 3 frame analysis required (QUALITY category)
- "Conclude from metadata only" → Visual quality must be verified with frames
- "Fix multiple issues at once" → One at a time, verify after each
- "Modify file without user confirmation" → Read-only analysis, modification requires explicit permission
- "Skip entire video because it's long" → Apply sampling strategy, never skip completely
- "Ignore and proceed past FFmpeg errors" → Errors always contain important information
- "Skip Step 1 triage" → Always start with triage for all cases
- "Request reference video" → This skill designed to work without reference

## Quick Reference - Diagnostic Paths by Symptom

| Symptom | Category | First Check | Common Cause | Detail Step |
|---------|----------|-------------|--------------|-------------|
| **Won't play** | CORRUPTED | `ffmpeg -v error -i file.mp4 -f null -` | Corruption or container issue | Step 2-A |
| **Quality degradation, blocking, blur** | QUALITY | Bitrate + frame analysis | Low bitrate, excessive compression | Step 2-C |
| **Only some devices won't play** | CODEC | Codec profile check | Compatibility issue (Safari, etc.) | Step 2-D |
| **Browser won't stream** | CONTAINER | moov atom location | MP4 metadata location | Step 2-B |
| **A/V mismatch** | SYNC | Duration comparison | Encoding settings, stream issue | Step 2-E |
| **No specific issue, just evaluate** | ASSESSMENT | Basic spec report | N/A | Step 2-F |

**All cases start with Step 1 (TRIAGE). Don't jump directly to table.**

## Core Principles

- **Accuracy > Speed**: Triage is 30s, overall takes as long as needed
- **No reference needed**: Don't rely on reference metrics like PSNR/SSIM. Use absolute standards + visual analysis
- **TodoWrite**: Track each step, visualize progress when analyzing frames
- **Complete workflow required**: No skipping steps even under pressure
