# Task Tool and Subagent Utilization Guidelines

Professional subagent utilization strategies and collaboration patterns through Claude Code's Task tool.

## Task Tool Core Concepts

### Automatic Subagent Selection
Claude Code automatically selects appropriate professional subagents based on task context:
- **Upon code completion**: `code-reviewer` automatically executes
- **When errors occur**: `debugger` automatically activates  
- **For performance issues**: `performance-engineer` automatically delegates
- **For security review**: `security-auditor` automatically invokes

### Explicit Subagent Invocation
Direct specification when specific expertise is needed:
```
"Review this code with code-reviewer"
"Check authentication logic with security-auditor"  
"Optimize this query with performance-engineer"
```

### Context-Based Intelligent Auto-Selection
Automatic selection of optimal subagents by analyzing keywords and situations:

#### Keyword Matching Automation
**Security-related keywords**:
- "security", "vulnerability", "authentication", "authorization", "encryption" → security-auditor auto-invoked
- "SQL injection", "XSS", "CSRF" → security-auditor priority activation

**Performance-related keywords**:
- "performance", "slow", "optimization", "bottleneck", "speed" → performance-engineer auto-invoked
- "memory", "CPU", "query optimization" → performance-engineer priority activation

**Error/Debugging keywords**:
- "error", "bug", "failure", "issue", "problem" → debugger auto-invoked
- "exception", "crash", "timeout" → debugger priority activation

**Code quality keywords**:
- "review", "improvement", "refactoring", "cleanup" → code-reviewer auto-invoked
- "readability", "maintainability", "structure" → code-reviewer priority activation

#### Context-Based Auto-Activation
**Code completion detection**:
- New function/component implementation complete → code-reviewer auto-execution
- After complex logic implementation → performance-engineer auto-review suggestion

**Test-related tasks**:
- "test", "E2E", "unit test" → test-automator auto-invoked
- Test failure detection → debugger + test-automator chain execution

## Task Decomposition and Parallel Processing

### Step-by-Step Decomposition of Complex Tasks
1. **Prioritize TodoWrite tool**: Systematically track tasks
2. **Single task in_progress**: Maintain only one task in progress at a time
3. **Immediate completion marking**: Update status immediately upon task completion

### Intelligent Task Complexity Detection
Analyze task requests to automatically determine complexity and apply appropriate decomposition strategies:

#### Automatic Complexity Detection Criteria
**Simple tasks (1-2 steps)**:
- Single file modification, clear single purpose
- Example: "Add comments to this function"
- → Direct processing, TodoWrite unnecessary

**Medium complexity tasks (3-5 steps)**:
- Multiple files involved, multi-step logic required
- Example: "Implement user login functionality"
- → TodoWrite auto-generated, decomposed into 3-5 subtasks

**High complexity tasks (6+ steps)**:
- System-wide, architecture changes, diverse technology stacks
- Example: "Redesign the entire authentication system"
- → TodoWrite + Task tool combination, parallel multi-subagent utilization

#### Automatic Decomposition Strategies
- **High complexity (6+ steps)**: TodoWrite + Task tool + parallel multi-subagent
- **Medium complexity (3-5 steps)**: TodoWrite + sequential subagent  
- **Simple (1-2 steps)**: Direct processing, no tool overhead

*Refer to @ORCHESTRATION.md for detailed complexity detection algorithms*

### Parallel Task Strategies
- **Independent analysis**: Delegate multiple files to different subagents simultaneously
- **Domain separation**: Assign Frontend/Backend tasks to respective specialized subagents
- **Validation phase**: Automatically execute quality verification subagents after implementation completion

## Subagent Collaboration Patterns

### Sequential Collaboration
```
1. backend-architect: API design
2. database-optimizer: Schema optimization  
3. security-auditor: Security verification
4. test-automator: Test writing
5. code-reviewer: Final review
```

### Parallel Collaboration
```
Concurrent execution:
- frontend-developer: UI component implementation
- backend-architect: API endpoint design
- database-optimizer: Data modeling
```

### Expertise Chain
```
debugger → performance-engineer → code-reviewer
(Error detection) → (Performance optimization) → (Quality verification)
```

## Practical Application Guide

### New Feature Development
1. **Planning phase**: Task decomposition using Task tool
2. **Implementation phase**: Utilize domain-specific professional subagents
3. **Validation phase**: Execute automatic quality verification chain

### Bug Fixing
1. **debugger**: Problem root cause analysis
2. **Related experts**: Domain-specific solution proposals
3. **test-automator**: Write regression prevention tests
4. **code-reviewer**: Review modifications

### Code Review
1. **code-reviewer**: Overall quality assessment
2. **security-auditor**: Security vulnerability check
3. **performance-engineer**: Performance optimization opportunity identification

## Efficiency Maximization

### Context Maintenance
- **State continuity**: Automatic transfer of work results between subagents
- **Memory utilization**: Leverage previous subagent results for next tasks
- **Error recovery**: Automatic alternative suggestions for failed subagent tasks

### Learning and Improvement
- **Pattern recognition**: Learn frequently used subagent combinations
- **Efficiency tracking**: Analyze optimal subagent selection patterns by task
- **Automatic optimization**: Auto-adjustment based on user preferences

## Quality Assurance

### Automatic Verification Chain
Automatic execution for all code changes:
1. **code-reviewer**: Code quality verification
2. **security-auditor**: Security vulnerability check  
3. **test-automator**: Test coverage confirmation
4. **performance-engineer**: Performance impact analysis

### Error Prevention
- **Pre-verification**: Expert review at design phase before implementation
- **Step-by-step confirmation**: Result verification upon each subagent task completion
- **Rollback preparation**: Immediate restoration to previous state when problems occur
