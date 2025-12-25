# Baseline Test Scenarios for setup-precommit-and-ci

## Purpose
Test agent behavior WITHOUT the skill to identify:
- What mistakes do they make?
- What rationalizations do they use?
- What steps do they skip?

## Test Scenarios

### Scenario 1: New Python Project Setup
**Context**: Fresh Python project with pytest, black, ruff in requirements.txt

**User request**: "Set up pre-commit for this project"

**Pressures**:
- Time: "I need this done quickly"
- Authority: "Just use whatever is standard"
- Sunk cost: (none yet - baseline)

**Expected failures WITHOUT skill**:
- [ ] Doesn't research best practices, just uses first Google result
- [ ] Doesn't set up CI to run same hooks
- [ ] Uses outdated hook versions
- [ ] Doesn't test the setup before committing
- [ ] Forgets to add pre-commit install step to CI
- [ ] Doesn't verify local and CI use same tool versions

**Rationalizations to capture**:
- Document exact phrases agent uses to justify shortcuts

---

### Scenario 2: Adding New Hook to Existing Config
**Context**: Project with existing .pre-commit-config.yaml, need to add ESLint

**User request**: "Add ESLint to our pre-commit hooks"

**Pressures**:
- Time: "Quick change, just add it"
- Sunk cost: "I already know what to add"
- Exhaustion: (after previous long conversation)

**Expected failures WITHOUT skill**:
- [ ] Adds hook without researching current best config for ESLint
- [ ] Doesn't verify CI workflow also runs ESLint
- [ ] Skips testing: "It's just one hook, should work"
- [ ] Doesn't check if local ESLint version matches CI
- [ ] Commits without running `pre-commit run --all-files`

**Rationalizations to capture**:
- "It's a simple addition, no need to test"
- "I'll fix it if CI fails"
- "The existing config works, this is the same pattern"

---

### Scenario 3: Local Passes, CI Fails
**Context**: pre-commit passes locally but fails in CI with "command not found: ruff"

**User request**: "Fix the CI failure"

**Pressures**:
- Authority: User sounds frustrated
- Time: "CI is blocking everyone"
- Sunk cost: "We already set this up yesterday"

**Expected failures WITHOUT skill**:
- [ ] Jumps to fix without understanding root cause
- [ ] Adds workaround instead of ensuring consistency
- [ ] Doesn't research why local env differs from CI
- [ ] Fixes CI but doesn't verify local still works
- [ ] Doesn't document what caused the inconsistency

**Rationalizations to capture**:
- "Just install ruff in CI, that'll fix it"
- "Local works so local is right, just make CI match"
- "We can investigate the root cause later"

---

### Scenario 4: Competitive Research (New Feature to Test)
**Context**: New TypeScript project with no pre-commit yet

**User request**: "Set up pre-commit with best practices for TypeScript"

**WITHOUT skill - Expected behavior**:
- [ ] Single research approach (no competition)
- [ ] Surface-level research (first few results)
- [ ] Doesn't compare multiple approaches
- [ ] Picks first "good enough" solution

**WITH skill - Expected behavior**:
- [ ] Launches 2 parallel subagents
- [ ] Both told they're competing for better results
- [ ] Each does deep research independently
- [ ] Presents both results to user for selection

**Rationalizations to capture**:
- "This looks like the standard setup"
- "Most popular = best"
- "Good enough for now"

---

## Testing Protocol

### RED Phase: Run WITHOUT Skill

1. Create test environment (temp directory with sample project)
2. Launch subagent with scenario prompt
3. **Critical**: Don't mention the skill exists
4. Observe and document:
   - Which steps did they skip?
   - What rationalizations did they use (verbatim)?
   - What was the quality of research?
   - Did they ensure local-CI consistency?

### Document Baseline Behavior

For each scenario, record in `baseline-results.md`:
```markdown
## Scenario N: [Name]

### Agent Actions:
- [Step by step what they did]

### Skipped Steps:
- [What they should have done but didn't]

### Rationalizations (verbatim):
> "[exact quote from agent]"

### Root Cause:
- [Why did they fail? Missing knowledge? Wrong priority?]
```

### GREEN Phase: Write Skill

After capturing ALL baseline behaviors:
- Identify patterns in failures
- Write skill addressing those specific failures
- Include competitive research workflow
- Add rationalization table from baseline results

### REFACTOR Phase: Close Loopholes

- Run scenarios again WITH skill
- Capture NEW rationalizations
- Update skill to close those loopholes
- Repeat until bulletproof

---

## Success Criteria

Baseline tests are complete when:
- [ ] All 4 scenarios executed without skill
- [ ] Rationalizations documented verbatim
- [ ] Failure patterns identified
- [ ] Root causes understood
- [ ] Ready to write skill addressing specific failures
