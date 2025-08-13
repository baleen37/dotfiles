---
name: save
description: "Save current TodoWrite state and work context to restore later"
---

# /save - Save Work State

현재 TodoWrite 상태와 작업 컨텍스트를 저장하여 나중에 복원

## Usage

```bash
/save <name>    # Save with specific identifier
/save           # Auto-generate name from main todo
```

## Saved Data

**Location**: `.claude/plans/plan_{name}_{timestamp}.md`

**Contents**:
- TodoWrite 전체 상태 (메타데이터 포함)
- 문제 분석 및 기술적 세부사항  
- 실행 명령어와 예상 시간
- 결정 사항과 학습 포인트
- 블로커/리스크 평가

## Features

- **Context Preservation**: Current work state and decisions
- **Progress Tracking**: Completed vs pending tasks
- **Technical Details**: Commands, timeframes, and reasoning
- **Auto-naming**: Intelligent naming from current tasks

## Integration

- Works with `/restore` command for session recovery
- Stores in project-local `.claude/plans/` directory
- Markdown format for human readability
