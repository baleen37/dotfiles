---
name: research
description: Use when conducting web research - enforces evidence-based analysis with citations, systematic investigation workflow, and comprehensive documentation
---

# Research Skill

Research the given topic using web search and provide a comprehensive analysis with citations.

## 1. Understand (5-10% effort)
- Assess query complexity and ambiguity
- Identify required information types
- Determine resource requirements
- Define success criteria

## 2. Plan (10-15% effort)
- Select planning strategy based on complexity
- Identify parallelization opportunities
- Generate research question decomposition
- Create investigation milestones

## 3. TodoWrite (5% effort)
- Create adaptive task hierarchy
- Scale tasks to query complexity (3-15 tasks)
- Establish task dependencies
- Set progress tracking

## 4. Execute (50-60% effort)
- **Parallel-first searches**: Always batch similar queries
- **Smart extraction**: Route by content complexity
- **Multi-hop exploration**: Follow entity and concept chains
- **Evidence collection**: Track sources and confidence
- **MCP integration**: Use context7 if available for documentation research
- **Context management**: Use Task tool with subagents to preserve main session context

## 5. Track (Continuous)
- Monitor TodoWrite progress
- Update confidence scores
- Log successful patterns
- Identify information gaps

## 6. Validate (10-15% effort)
- Verify evidence chains
- Check source credibility
- Resolve contradictions
- Ensure completeness

## Output Requirements

Save detailed report to `docs/research/[timestamp]_[topic].md` (timestamp format: YYYYMMDD-HHMM).
Focus on evidence-based analysis. Never make claims without sources.
