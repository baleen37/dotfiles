# setup-precommit-and-ci Skill

## Summary

This skill enforces best practices for setting up pre-commit hooks with CI/CD integration.

## Core Principles

1. **Local-CI Consistency**: If it passes locally, it must pass in CI
2. **Competitive Research**: 2 parallel subagents research best practices
3. **Mandatory Testing**: Always test changes before claiming done
4. **CI is Not Optional**: Pre-commit without CI is half a solution

## Skill Development Process

This skill was created using Test-Driven Development (TDD) methodology adapted for documentation:

### RED Phase: Baseline Testing
- Created 4 test scenarios without skill
- Ran 2 scenarios to capture actual failures
- Documented verbatim rationalizations
- Identified failure patterns

**Key findings from baseline**:
- Agents NEVER created CI workflows
- Agents skipped testing "for speed"
- No research, just "standard" setup
- Used outdated versions without verification

### GREEN Phase: Minimal Skill
- Wrote skill addressing specific baseline failures
- Included competitive research workflow
- Made CI mandatory, not optional
- Added verification requirements

**Test results**:
- ✅ Agent read and followed skill
- ✅ Recognized all required steps
- ⚠️ Found loophole: Asked permission to skip research

### REFACTOR Phase: Close Loopholes
- Changed "Competitive Research (New Setups Only)" to "MANDATORY Competitive Research"
- Added red flags: "Let me ask if they want research"
- Clarified: User chooses WHICH result, not WHETHER to research
- Strengthened language throughout

## Files

- `SKILL.md` - Main skill document (deploy this)
- `baseline-tests.md` - Test scenarios used
- `baseline-results.md` - Failures observed without skill
- `green-phase-results.md` - Behavior with skill + loopholes found
- `README.md` - This file

## Testing Status

✅ Baseline tests completed (2/4 scenarios - sufficient patterns found)
✅ Skill written addressing baseline failures
✅ Green phase test revealed loophole
✅ Loophole closed in refactor
⏳ Final validation (requires new Claude session to load skill)

## Next Steps

1. Test skill in new Claude Code session
2. Run remaining baseline scenarios (3 & 4) if needed
3. Monitor real-world usage for new rationalizations
4. Update skill as new loopholes discovered

## Deployment

Skill is already in correct location:
```
~/.claude/skills/setup-precommit-and-ci/SKILL.md
```

To use in new session:
```
User: "Set up pre-commit for my Python project"
Claude: [Should automatically invoke setup-precommit-and-ci skill]
```

Or explicitly:
```
User: "Use setup-precommit-and-ci skill to configure this project"
```
