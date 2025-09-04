---
name: delete-worktrees
description: "Git worktree 삭제 및 정리를 위한 안전한 관리 도구"
---

Git worktree를 안전하게 삭제하고 정리하는 도구.

**Usage**: `/delete-worktrees [options]`

## Git Worktree 삭제 전략

### 벌크 워크트리 정리

병합된 브랜치의 워크트리를 일괄 정리합니다.

```bash
#!/bin/bash

# 병합된 브랜치 확인 후 워크트리 삭제
git branch --merged main | grep -v main | while read -r branch; do
    worktree_path="./worktrees/${branch// /}"

    if [ -d "$worktree_path" ]; then
        echo "병합된 브랜치 워크트리 삭제: $branch"
        git worktree remove "$worktree_path" --force
    fi
done

# 고아 워크트리 정리
git worktree prune
echo "워크트리 정리 완료"
```

### 선택적 워크트리 삭제

대화식으로 특정 워크트리를 선택하여 삭제합니다.

```bash
#!/bin/bash

echo "현재 워크트리 목록:"
git worktree list

echo ""
read -p "삭제할 워크트리 경로: " worktree_path

# 안전성 확인
if [ -d "$worktree_path" ]; then
    read -p "정말로 '$worktree_path'를 삭제하시겠습니까? (y/N): " confirm

    if [[ $confirm == [yY] ]]; then
        git worktree remove "$worktree_path"
        echo "워크트리 삭제 완료: $worktree_path"
    else
        echo "삭제 취소됨"
    fi
else
    echo "워크트리를 찾을 수 없습니다: $worktree_path"
fi
```

## 고급 정리 패턴

### 오래된 워크트리 자동 정리

```bash
# 30일 이상 미사용 워크트리 찾기
find ./worktrees -type d -atime +30 -name "*.git" | while read -r git_dir; do
    worktree_path=$(dirname "$git_dir")
    echo "오래된 워크트리 발견: $worktree_path"
    # 추가 확인 로직 필요
done
```

### 브랜치 상태별 정리

```bash
# 원격에서 삭제된 브랜치의 워크트리 정리
git remote prune origin
git worktree list | grep -v "bare\|main" | while read -r worktree_info; do
    worktree_path=$(echo "$worktree_info" | awk '{print $1}')
    branch_name=$(echo "$worktree_info" | awk '{print $3}' | sed 's/\[//;s/\]//')

    if ! git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
        echo "원격에서 삭제된 브랜치 워크트리: $worktree_path"
        git worktree remove "$worktree_path" --force
    fi
done
```

## 안전장치

### 변경사항 확인

```bash
# 삭제 전 미커밋 변경사항 확인
if [ -n "$(git -C "$worktree_path" status --porcelain)" ]; then
    echo "경고: 커밋되지 않은 변경사항이 있습니다"
    git -C "$worktree_path" status --short
    read -p "그래도 삭제하시겠습니까? (y/N): " force_confirm
    [[ $force_confirm != [yY] ]] && exit 1
fi
```

### 백업 생성

```bash
# 중요한 워크트리 삭제 전 백업
backup_path="./backups/$(basename "$worktree_path")-$(date +%Y%m%d)"
cp -r "$worktree_path" "$backup_path"
echo "백업 생성: $backup_path"
```

## 정리 규칙

- **병합된 브랜치**: 자동 정리 대상
- **스태시 있는 워크트리**: 수동 확인 필요
- **미커밋 변경사항**: 경고 후 사용자 확인
- **메인 브랜치**: 삭제 금지

What worktrees would you like me to help you clean up?
