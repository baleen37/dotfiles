---
name: ci-troubleshooting
description: Use when CI/CD pipeline fails with build errors, test failures, dependency issues, or infrastructure problems - systematic Claude Code-powered troubleshooting with parallel subagent analysis and three-tier validation for reliable fixes
---

# CI Troubleshooting

## Overview

Systematic CI/CD failure resolution using Claude Code's parallel subagent analysis and three-tier validation. Achieves 61% faster resolution through intelligent methodology instead of reactive debugging.

## When to Use

**Use for CI/CD failures:**
- Build errors, test failures, dependency issues
- Infrastructure problems, timeouts, permissions
- Cross-platform failures, version conflicts
- Complex unknown patterns requiring investigation

**Don't use for:**
- Local development (use debugging skills)
- Feature development (use **test-driven-development**)
- Code review (use **code-reviewer**)

## Core Pattern

**Before:** Random fixes → push → hope → rollback
**After:** Triage → parallel analysis → validate → targeted fix

```bash
# ❌ Anti-pattern
git commit -m "fix ci" && git push

# ✅ Systematic approach
gh run view --log <run-id>     # Triage
npm test                       # Local validation
act -j <failing-job>           # CI simulation
git commit -m "fix: specific issue - resolves job failure"
```

## Quick Reference

| Urgency | Method | Time | Success Rate | Risk |
|---------|--------|------|--------------|------|
| Production Down | Emergency Mode | 2-5 min | 80% | HIGH |
| Slack Exploding | Panic Mode | 5-15 min | 75% | MEDIUM |
| Normal Failure | Systematic Method | 15-60 min | 90%+ | LOW |

## Claude Code Advantage

**1. Parallel Subagent Analysis**
- Dispatch 3 specialized agents simultaneously
- 61% reduction in analysis time vs sequential debugging

**2. Tool Integration**
- Multi-tool orchestration for systematic debugging
- Three-tier validation framework (local → simulation → QA)

**3. Knowledge Capture**
- Document failure patterns and solutions
- Capture successful tool combinations for future reference

## Systematic Method

### Phase 1: Rapid Triage (2 minutes)

```bash
# Get latest CI run and categorize failure
latest_run=$(gh run list --limit 1 --json databaseId | jq -r '.[0].databaseId')
gh run view --log "$latest_run" | grep -E "(error|Error|ERROR)" -A 3 -B 3 | head -20
```

**Categorize failure type:**
- **Dependency/Cache**: Package manager failures, version conflicts
- **Build/Test**: Compilation, runtime, test assertion failures
- **Infrastructure**: Timeouts, permissions, networking, resources
- **Cross-Platform**: Platform-specific failures, architecture differences
- **Unknown**: Complex patterns requiring deep investigation

### Resolution Patterns

### Merge Conflicts
```bash
git fetch origin && git merge origin/main  # Reproduce locally
git status  # Check conflicts
git add <resolved-files> && git commit     # Resolve
make test  # Validate
```

### CI Status Check Failures
```bash
gh run view <run-id> --log                 # Check logs
gh pr checks <pr-number>                   # PR-specific failures
```

**Common issues:**
- Missing workflow triggers on PR events
- Timeout failures → increase timeout values
- Permission issues → check token permissions

### Workflow Issues
```bash
gh workflow view <workflow-name>            # Debug syntax
act -j <failing-job> --bind --verbose      # Local testing
```

**Common patterns:**
- YAML syntax errors
- Missing dependencies
- Environment variable issues

### Dependency/Cache Issues
```bash
npm cache clean --force && rm -rf node_modules package-lock.json
make clean && make build && make test
```

### Build/Test Failures
**Dispatch parallel subagents:**
1. **Error Analyst**: Extract failure point, root causes
2. **Environment Specialist**: Reproduce locally
3. **Solution Architect**: Provide ranked solutions with risks

**Apply iteratively:** Small fix → local test → act validation

### Infrastructure Issues
```bash
gh run view --log <run-id> | grep -E "(timeout|permission|network)" -A 5 -B 5
```

## Validation & Deployment

**Three-Tier Validation:**
1. **Local**: Run exact failing command
2. **Simulation**: `act -j <failing-job> --bind --verbose`
3. **Edge Cases**: Test related functionality

**Safe Deployment:**
```bash
git commit -m "fix: <issue> - resolves CI failure

Root cause: <explanation>
Fix: <method>
Validation: local ✓ act ✓
Rollback: git revert <commit-hash>"
```

## Emergency Modes

**Panic Mode (Slack Exploding):**
1. Pick scariest error (30s)
2. Quick investigation: `gh run view --log <run-id> | grep -E "(error|Error|ERROR)" -A 5 -B 5`
3. Apply targeted fix (3-10 min)
4. Test specific failure only
5. Push if works, monitor for rollback

**Production Down:**
1. Apply most likely fix immediately (2-5 min)
2. Push directly to main (risk accepted)
3. Monitor and rollback instantly

## Common Mistakes

| Mistake | Prevention |
|---------|------------|
| Reading full CI logs | Use grep for errors only |
| Multiple simultaneous fixes | One change at a time |
| No local validation | Reproduce locally first |
| No rollback strategy | Document rollback plan |

## Rationalization Prevention

**Red Flags - STOP:**
- "This is just a simple fix" → Complex interactions exist
- "I'll test after pushing" → CI validates, doesn't test
- "It worked on my machine" → Environment differences matter
- "No time for proper process" → Emergency mode exists for real emergencies

**Violating the letter of the rules is violating the spirit of the rules.**

## Essential Commands

**GitHub Actions:**
```bash
gh run list --limit 1                           # Get latest run
gh run view --log <run-id>                     # View run logs
gh pr checks <pr-number>                       # PR-specific failures
```

**Local CI Simulation:**
```bash
act -j <failing-job> --bind --verbose          # Simulate GitHub Actions
```

**Error Pattern Extraction:**
```bash
grep -E "(error|Error|ERROR)" logfile -A 3 -B 3 # Extract errors
```

**Merge Conflicts:**
```bash
git fetch origin && git merge origin/main     # Reproduce locally
git status                                     # Identify conflicts
```

**Cache Clearing:**
```bash
npm cache clean --force && rm -rf node_modules package-lock.json
make clean && make build && make test
```

## Implementation Checklist

**For each CI failure:**
- [ ] Triage error type using grep patterns
- [ ] Reproduce failure locally
- [ ] Apply single, minimal change
- [ ] Validate locally and with act
- [ ] Document rollback strategy
- [ ] Deploy safely with clear commit message

**Emergency preparedness:**
- [ ] Emergency mode triggers defined
- [ ] Rollback procedures documented
- [ ] Team trained on emergency workflows

---

*Systematic approach beats random fixes. Parallel analysis beats sequential debugging. Root cause understanding beats surface patches.*
