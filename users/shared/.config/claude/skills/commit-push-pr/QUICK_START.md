# Quick Start Checklist

Use this checklist for fast reference when running the committing-and-pushing-pr skill.

---

## Pre-Flight Check

- [ ] `gh auth status` - GitHub CLI authenticated?
- [ ] `git remote -v` - Remote configured?
- [ ] `git branch --show-current` - On correct branch?

---

## 5-Step Workflow

### 1. Gather Context
```bash
bash {baseDir}/scripts/pr-check.sh
```
- [ ] Review BASE branch
- [ ] Review PR state (OPEN/NO_PR/MERGED/CLOSED)
- [ ] Review changed files

### 1.5. Check Conflicts
```bash
git fetch origin $BASE
git merge-tree $(git merge-base HEAD origin/$BASE) HEAD origin/$BASE
```
- [ ] No conflicts? → Proceed to Step 5
- [ ] Conflicts? → Resolve first (see CONFLICT_RESOLUTION.md)

### 2. Create WIP Branch (if on main/master)
```bash
git checkout -b wip/<description>
```
- [ ] Only if on main or master

### 3. Commit
```bash
git status
git add <files>
git commit -m "feat: description"
```
- [ ] Used specific files (not `git add -A` unless verified)
- [ ] Conventional Commits format

### 5. Push & PR
```bash
git push -u origin HEAD
```

| PR State | Command |
|----------|---------|
| OPEN | `gh pr edit --title "$TITLE" --body "$BODY"` |
| NO_PR/MERGED | `gh pr create --base $BASE --title "$TITLE" --body "$BODY"` |
| CLOSED | Ask user first |

- [ ] Used `--base $BASE`
- [ ] PR body includes Summary + Test plan

---

## Red Flags (Never Do These)

- ❌ Omit `--base` flag
- ❌ Use `git add -A` without `git status`
- ❌ Skip conflict check before push
- ❌ Assume no existing PR
- ❌ Gather context sequentially

---

## PR Body Template

```markdown
## Summary
- Change 1
- Change 2

## Test plan
- [x] Test 1
- [x] Test 2

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```
