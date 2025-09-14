---
name: audit-plan
description: "AI agent audits implementation plan for missing task sequences and gaps"
---

Critical review of implementation plan and detail files to identify missing task sequences and ensure comprehensive coverage before implementation begins.

**Usage**: `/audit-plan [feature-path]`

## GitHub Spec Kit Step 4: Plan Auditing

AI agent performs thorough review of implementation plan with critical focus on identifying gaps in task sequences and implementation details.

## Core Audit Questions

### Missing Task Sequences
- Are there sequences of tasks needed that aren't documented?
- What steps might be missing between documented phases?
- Are there hidden dependencies not explicitly called out?
- Do implementation details match the high-level plan?

### Implementation Detail Cross-Reference
- When looking at core implementation, are there appropriate references to implementation details for each step?
- Are the implementation detail files complete and actionable?
- Do detail files provide sufficient guidance for actual coding?

### Gap Identification
- What could go wrong during implementation?
- Are there assumptions that need validation?
- What external dependencies might cause issues?
- Are there edge cases not addressed in the plan?

## Audit Process

1. **Read Implementation Plan**: Thoroughly review plan.md and all referenced detail files
2. **Sequence Analysis**: Identify potential missing task sequences with critical eye
3. **Cross-Reference Check**: Verify implementation details exist for each plan step
4. **Gap Detection**: Look for areas requiring further clarification
5. **Constitution Compliance**: Check for over-engineered components and constitutional adherence

## Sample Audit Prompt

> "Read through the implementation plan with an eye on determining whether there is a sequence of tasks that you need to be doing that isn't currently documented. Look for missing implementation steps, unclear dependencies, and areas where the plan jumps between concepts without sufficient detail."

## Key Behaviors

- Focus specifically on missing task sequences and gaps
- Cross-reference plan steps with implementation details
- Identify potential blockers before implementation starts
- Ensure plan provides sufficient guidance for coding phase
- Check adherence to project constitution and avoid over-engineering

## Deliverables

- Critical gap analysis with specific missing sequences identified
- Cross-reference validation report between plan and implementation details
- Recommended additions to plan before proceeding to implementation
- Constitution compliance assessment
