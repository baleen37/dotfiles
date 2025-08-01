# jito Work Intelligence System

An integrated management system that learns jito's work patterns and automatically optimizes them.

## Automatic Complexity Detection

An intelligent system that analyzes work requests and automatically selects appropriate tools and strategies.

### Complexity Detection Algorithm

#### Simple Tasks (Complexity 1-2)
**Detection Criteria**:
- Single file modification
- Clear single purpose
- 1 keyword or fewer

**Automatic Execution**:
- Direct processing
- Use only 1 MCP server
- Skip TodoWrite

**Examples**:
```
"Add comments to this function" → Direct processing
"Find GitHub logo" → Use Magic server only
```

#### Medium-Complex Tasks (Complexity 3-5)
**Detection Criteria**:
- Involves multiple files
- Requires multi-step logic
- 2-3 keywords

**Automatic Execution**:
- Auto-generate TodoWrite (3-5 subtasks)
- Combine 2 MCP servers
- Sequential subagent utilization

**Examples**:
```
"Implement user login functionality"
→ TodoWrite + Context7 + Sequential
→ Automatic code-reviewer invocation
```

#### High-Complex Tasks (Complexity 6+)
**Detection Criteria**:
- System-wide impact
- Architecture changes
- Keywords: "entire", "system", "architecture"

**Automatic Execution**:
- TodoWrite + Task tool combination
- Multiple MCP server chains
- Parallel subagent utilization

**Examples**:
```
"Redesign the entire authentication system"
→ TodoWrite + Task + All MCP servers
→ backend-architect + security-auditor + test-automator parallel execution
```

## Quality Gate Automation

A system that automatically verifies quality at each stage of work.

### Stage-wise Automatic Verification

#### Stage 1: Pre-Work Verification
**Automatic Checklist**:
- [ ] Git status check (uncommitted changes)
- [ ] Required tools and permissions verification
- [ ] Complexity-based strategy selection
- [ ] Estimated time calculation

#### Stage 2: In-Progress Verification  
**Automatic Monitoring**:
- Quality check upon completion of each subtask
- Automatic debugger invocation on error occurrence
- Automatic performance-engineer activation when performance issues detected

#### Stage 3: Pre-Completion Verification
**Mandatory Verification Items**:
- [ ] Automatic lint/typecheck execution
- [ ] Related test execution confirmation
- [ ] Automatic code-reviewer execution
- [ ] Security issue check (security-auditor)

### Automatic Quality Improvement Suggestions
After work completion, automatically analyze 4 areas (performance/security/maintainability/testing) and suggest improvements.

## jito Pattern Learning System

An adaptive system that learns jito's work patterns and provides more efficient suggestions.

### Success Pattern Learning

#### jito Preference Pattern Learning
- **MCP Servers**: Sequential(highest) > Context7(high) > Magic(medium) > Playwright(low)
- **Thinking Modes**: Prefers --ultrathink, --analyze  
- **Subagents**: code-reviewer(essential), debugger(frequent), security-auditor(medium)

#### Success Rate Based Auto-Adjustment
- **High Success Rate Patterns**: Increase automatic suggestion priority
- **Low Success Rate Patterns**: Suggest alternative patterns
- **New Patterns**: Classify as experimental suggestions

### Efficiency Optimization

#### Automatic Work Order Optimization
Analyze jito's past work patterns to suggest optimal order:

```
Learned Optimal Order (Example):
1. Security Review → 2. Implementation → 3. Testing → 4. Performance Optimization
(Learned from jito's preferred order)
```

#### Resource Efficiency Monitoring
- **Token Usage Tracking**: Analyze token efficiency by strategy
- **Time Efficiency**: Compare work completion time vs quality
- **User Satisfaction**: Improve based on jito's feedback

## Automatic Workflow Generation

Automatically generate workflows from frequently repeated work patterns.

### Smart Workflow Patterns

#### Feature Development Workflow
```
Detection: "Develop new [feature name]"
↓
Auto-generated Workflow:
1. Context7: Research related library patterns
2. Sequential: Establish implementation strategy
3. Implementation phase (detailed based on complexity)
4. code-reviewer: Code quality review
5. security-auditor: Security review
6. test-automator: Test writing
7. Final integration testing
```

#### Bug Fix Workflow
```
Detection: "bug", "error", "issue" keywords
↓  
Auto-generated Workflow:
1. debugger: Root cause analysis --debug
2. Issue reproduction and test case creation
3. Fix with minimal changes
4. Add regression tests
5. code-reviewer: Review changes
```

#### Refactoring Workflow
```
Detection: "refactoring", "improve", "cleanup" keywords
↓
Auto-generated Workflow:
1. Current code analysis --analyze
2. Improvement plan establishment --architect
3. Step-by-step refactoring execution
4. Run tests at each step
5. Performance comparison analysis --optimize
6. Final quality verification
```

## Learning-Based Automatic Suggestions

### Context-Aware Suggestions
- **Feature Implementation Complete**: Automatically suggest code-reviewer, test-automator, security-auditor
- **Performance Issue Detected**: Automatically suggest performance-engineer, --optimize mode

### Preventive Quality Management
A system that detects and prevents issues before they occur:

- **Technical Debt Detection**: Monitor code complexity increase trends
- **Early Security Risk Warning**: Assess security risk levels of new dependencies or patterns  
- **Performance Degradation Prediction**: Pre-analyze the impact of code changes on performance
- **Test Coverage Monitoring**: Automatic alerts when coverage decreases

## Rule #1 Compliance System

All automation operates safely while adhering to jito's Rule #1:

### Automatic Execution vs Suggestions
- **Automatic Execution**: Only clearly safe operations (e.g., lint execution, performance metric collection)
- **Suggestions**: Always provide only suggestions to jito for code changes or important decisions
- **Explicit Permission**: Always request permission for new patterns or experimental features

### Safety Mechanisms
- **Pre-Execution Confirmation**: Request confirmation before execution for risky operations
- **Rollback Preparation**: Maintain rollback plans for all changes
- **Gradual Application**: Apply new automation incrementally step by step

## Performance Monitoring

### System Efficiency Tracking
- **Response Time**: Monitor average processing time for each task
- **Accuracy**: Accuracy of automatic selections and user satisfaction
- **Resource Usage**: Track token usage and efficiency

### Continuous Improvement
- **A/B Testing**: Verify effectiveness of new strategies
- **Feedback Loop**: Continuous learning through jito's feedback
- **Performance Benchmarks**: Regular performance evaluation and improvement

This system serves as an intelligent assistant that maximizes efficiency while respecting jito's work patterns.
