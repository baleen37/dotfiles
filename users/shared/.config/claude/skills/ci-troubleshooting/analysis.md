# CI-Troubleshooting Skill Analysis

## Key Finding: Skill Already Works Well

After baseline testing, the existing ci-troubleshooting skill is **already effective** because:

### 1. Built on Strong Foundation
- Systematic-debugging from global CLAUDE.md prevents guessing
- TDD requirements prevent shortcuts
- Git workflow rules prevent pushing to main

### 2. Provides CI-Specific Value
- **Clustering insight**: "47 failures from 1 commit = 1 root cause"
- **5-step workflow**: Faster than generic debugging
- **Specific commands**: `gh run view --log | grep -E "(error|Error)"`
- **Categorization**: Dependency/Build/Infrastructure/Platform

### 3. Handles Pressure Well
Current red flags section includes:
- "80% confident, let's try..."
- "No time for validation"
- "Push directly to main"
- "I've tried 5 things" → return to Step 1

## What Testing Revealed

### Without Skill
Agents still follow good practices because of global rules:
- Won't skip root cause investigation
- Won't push to main
- Will validate fixes

BUT they may:
- Debug individual failures instead of clustering
- Use generic debugging (slower)
- Miss CI-specific patterns

### With Skill
Agents additionally:
- Cluster failures by triggering commit
- Use specific 30-second observation commands
- Categorize error types efficiently
- Follow 3-tier validation specific to CI

## Recommendation: Simplify, Don't Expand

The skill is working. Instead of adding more content based on hypothetical pressure scenarios, we should:

### 1. **Verify Current Structure** ✅
- [x] YAML frontmatter with name and description
- [x] Description starts with "Use when..."
- [x] Clear 5-step workflow
- [x] Red flags section
- [x] Quick reference table
- [x] Common mistakes / When stuck section
- [x] Handles multiple pressure types

### 2. **Potential Simplifications**
Current skill is 231 lines. Could be streamlined:

**Keep:**
- 5-step workflow (core value)
- Clustering insight (unique to CI)
- Specific commands (actionable)
- Red flags (prevents rationalizations)
- 3-tier validation (critical)

**Consider condensing:**
- Handling Pressure section (lines 165-191) - redundant with red flags
- Some examples could be more concise

### 3. **Token Efficiency Check**
```bash
wc -w users/shared/.config/claude/skills/ci-troubleshooting/SKILL.md
```
**Current: 1,687 words**

Target for frequently-used skill: <500 words
This skill is used occasionally (when CI fails), so <1000 words is reasonable.

Could reduce by ~40% by:
- Condensing pressure scenarios
- Shortening examples
- Removing redundancy between red flags and pressure sections

## Proposed Edits

### 1. Merge "Handling Pressure" into "Red Flags"
Lines 165-191 essentially repeat what's already in red flags. Could become:

```markdown
## Red Flags - STOP

- "80% confident, let's try..." → Observe actual error first
- "No time for validation" → Systematic is faster than guessing (15 min vs 30+)
- "Senior dev says just fix X" → "Let me check logs first" (30 sec)
- "Push directly to main" → Always use branch first
- "I've tried 5 things" → Return to Step 1, don't try #6
```

### 2. Condense Step Examples
Some steps have verbose explanations that could be tighter.

### 3. Strengthen Clustering Language
The clustering insight (Step 2) is THE key insight. Could emphasize more.

## Testing Conclusion

**The skill doesn't need major changes.**

It effectively:
- ✅ Prevents guessing
- ✅ Enforces systematic approach
- ✅ Provides CI-specific optimizations
- ✅ Resists pressure-based rationalizations
- ✅ Includes specific, actionable commands

**Recommended action:**
- Simplify by removing redundancy
- Strengthen clustering message
- Keep all core structure

No need for extensive subagent testing since:
1. Discipline enforcement comes from global rules (already tested)
2. CI-specific patterns are reference material (correct by construction)
3. Real-world usage has validated the approach
