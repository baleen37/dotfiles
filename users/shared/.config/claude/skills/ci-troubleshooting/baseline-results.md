# Baseline Testing Results

## Discovery: Existing Protection from Global Rules

**Key finding:** Agents are already protected by systematic-debugging and TDD rules from global CLAUDE.md. This means:

1. They won't skip root cause investigation
2. They won't push directly to main
3. They won't skip validation

## Scenario 1: Time Pressure + Authority (WITHOUT ci-troubleshooting skill)

**Agent response:**
- ✅ Refused to push directly to main
- ✅ Insisted on investigating actual CI logs first
- ✅ Recognized "probably" is not a diagnosis
- ✅ Pushed back on authority pressure
- ✅ Cited systematic-debugging skill

**Rationalization attempted:** None - agent correctly applied existing rules

## Scenario 2: Simple Fix (WITHOUT ci-troubleshooting skill)

**Agent response:**
- ✅ Refused to add empty test script without investigation
- ✅ Required root cause investigation
- ✅ Refused to push to main
- ✅ Applied TDD requirements
- ✅ Cited foundational rules

**Rationalization attempted:** None - agent correctly applied existing rules

## Analysis: What Does ci-troubleshooting Skill Add?

Given that systematic-debugging already prevents bad practices, the ci-troubleshooting skill needs to provide:

### 1. **CI-Specific Workflow**
- Exact commands for checking CI logs
- How to cluster failures by commit (unique to CI context)
- Platform-specific debugging (works locally, fails in CI)

### 2. **Efficiency Optimizations**
- 30-second observation beats hours of hypothesis
- Clustering 47 failures → 1 root cause
- Three-tier validation workflow

### 3. **CI-Specific Patterns**
- Dependency caching issues
- Platform/architecture differences
- Transient vs persistent failures
- Flaky test identification

## Revised Testing Strategy

Since baseline behavior is already good due to global rules, test for:

1. **Speed of diagnosis** - Does skill make agent faster?
2. **CI-specific patterns** - Does agent recognize CI-unique issues?
3. **Clustering behavior** - Does agent group failures by commit?
4. **Workflow efficiency** - Does agent follow 5-step process vs. generic debugging?

## New Test Scenarios Needed

### Scenario A: Clustering Test
- 47 failures from one commit
- WITHOUT skill: Agent might debug individually OR use systematic-debugging (slow)
- WITH skill: Agent should cluster by commit immediately

### Scenario B: Platform Difference
- Works locally, fails in CI (architecture issue)
- WITHOUT skill: Might not recognize platform-specific issue quickly
- WITH skill: Should check for OS/arch differences in Step 1 categorization

### Scenario C: Efficiency Test
- Complex CI failure
- WITHOUT skill: Generic systematic-debugging (correct but slower)
- WITH skill: 30-second observation + immediate categorization

## Conclusion

The ci-troubleshooting skill is NOT about enforcing discipline (that's already handled).

It's about **CI-specific patterns and efficiency optimizations** on top of existing systematic approach.

Testing should focus on:
- **Recognizes CI-specific issue types** (dependency cache, platform diff, flaky tests)
- **Uses clustering** instead of individual investigation
- **Follows 5-step CI workflow** instead of generic debugging
- **Faster diagnosis** through specific commands
