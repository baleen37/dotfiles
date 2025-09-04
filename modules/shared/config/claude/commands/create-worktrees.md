---
name: create-worktrees
description: "Git worktree 관리를 위한 고급 기법 및 명령어 생성"
---

Git worktree를 효율적으로 관리하고 생성하는 고급 기법.

**Usage**: `/create-worktrees [options]`

## Git Worktree 관리 전략

### 벌크 워크트리 생성

여러 브랜치에 대해 동시에 워크트리를 생성합니다.

```bash
#!/bin/bash

# GitHub CLI 인증 확인
gh auth status || { echo "GitHub CLI 인증이 필요합니다"; exit 1; }

# 워크트리 기본 디렉토리 생성
mkdir -p ./worktrees

# 모든 브랜치 조회 후 처리
gh api repos/:owner/:repo/branches --jq '.[].name' | while read -r branch; do
    worktree_path="./worktrees/${branch}"

    # 기존 워크트리 건너뛰기
    if [ ! -d "$worktree_path" ]; then
        git worktree add "$worktree_path" "origin/$branch"
        echo "워크트리 생성: $branch"
    else
        echo "기존 워크트리 건너뛰기: $branch"
    fi
done
```

### 개별 워크트리 생성

특정 브랜치에 대한 대화식 워크트리 생성.

```bash
#!/bin/bash

# 브랜치 정보 입력 요청
read -p "브랜치 이름: " branch_name
read -p "기본 브랜치 (선택사항): " base_branch

# 워크트리 생성 (기본 브랜치 옵션 포함)
git worktree add -b "$branch_name" "./worktrees/$branch_name" "${base_branch:-HEAD}"
echo "워크트리 생성 완료: $branch_name"
```

## 고급 워크트리 패턴

### 네스티드 브랜치 구조 지원

```bash
# feature/ui/button → worktrees/feature-ui-button
sanitized_name=$(echo "$branch_name" | sed 's/\//-/g')
git worktree add "./worktrees/$sanitized_name" "$branch_name"
```

### 워크트리 정리 및 관리

```bash
# 삭제된 브랜치의 워크트리 정리
git worktree prune

# 모든 워크트리 상태 확인
git worktree list
```

## 프로젝트별 설정

- **큰 리포지터리**: 선택적 브랜치 워크트리 생성
- **팀 협업**: 공통 워크트리 네이밍 규칙 적용
- **CI/CD 통합**: 자동화된 워크트리 관리

## 보안 고려사항

- 민감한 브랜치 제외 로직
- 워크트리별 환경 변수 격리
- 임시 워크트리 자동 정리

What would you like me to help you create worktrees for?
