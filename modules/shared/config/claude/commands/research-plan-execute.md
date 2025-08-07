# research-plan-execute: Systematic Execution of Complex Multi-Step Tasks

ABOUTME: Structures complex development/analysis tasks into Research-Plan-Execute 3-phase workflow
ABOUTME: Automates parallel processing and quality assurance using Task tool and sub-agents

## Core Principles

**YAGNI First**: Eliminate excessive complexity, maintain only practical automation
**Parallel Optimization**: Execute independent tasks in batches
**Clear Gates**: Explicit completion criteria for each phase
**Fallback Chain**: Simple rule-based agent selection

## 3-Phase Workflow

### 1. Research (Investigation)
**Purpose**: Assess current state, analyze requirements, identify constraints

**Auto-execution Triggers**:
- File count > 10 or keyword detection (analyze, investigate, audit)
- New technology stack/library mentions
- Legacy system modernization requests

**Batch Execution**:
```bash
# Execute independent research tasks in parallel
Task: "Codebase status analysis" + "Dependency analysis" + "Performance baseline measurement"
```

**Deliverables**: Status summary, constraint list, risk factors

### 2. Plan (Planning)
**Purpose**: Establish execution strategy, divide tasks, set quality standards

**Sub-agent Selection Rules**:
- Frontend keywords → Magic priority
- Backend/API keywords → Context7 priority  
- Complex analysis → Sequential priority
- Testing → Playwright priority

**Deliverables**: Concrete work plan, priorities, completion criteria

### 3. Execute (Implementation)
**Purpose**: Execute planned tasks, validate quality, integrate results

**Parallel Execution Pattern**:
```bash
# Independent implementation tasks
Task: "Backend implementation" + "Frontend implementation" + "Test creation"
```

**Quality Gates**:
- Code functionality verification
- Test passage
- Existing pattern compliance

## Sub-agent Utilization Strategy

### Agent Matching (Simple Rule-based)

**Analyzer Agent** (`--think` auto-activation):
- Triggers: debug, analyze, investigate, audit
- Tools: Grep + Read + Sequential
- Output: Structured analysis reports

**Builder Agent**:
- Triggers: implement, create, build, develop  
- Tools: Read + Write + Edit + Context7
- Output: Working code, implementation documentation

**Tester Agent**:
- Triggers: test, validate, verify, quality
- Tools: Bash + Playwright (when needed)
- Output: Test code, validation results

### Fallback Chain
1. Attempt specialized agent
2. Fall back to Sequential for general analysis on failure
3. Finally resort to manual step-by-step execution

## Usage Examples

### Example 1: Performance Optimization
```
Input: "React app performance optimization"

Research Task:
- Measure current performance metrics
- Analyze bundle size  
- Identify rendering bottlenecks

Plan:
- Priority: Bundle size > Rendering > Network
- Task division: Code splitting, memoization, image optimization

Execute Tasks (parallel):
- Bundle analysis and optimization
- Component memoization
- Performance test creation
```

### Example 2: New Feature Development
```
Input: "User authentication system implementation"

Research Task:
- Investigate existing authentication patterns
- Analyze security requirements
- Review available libraries

Plan:
- Architecture: JWT + Refresh Token
- Implementation order: Backend API → Frontend UI → Testing

Execute Tasks (parallel):
- Authentication API implementation (Backend Agent)
- Login UI implementation (Frontend Agent)  
- E2E test creation (Tester Agent)
```

## Quality Assurance

### Completion Criteria by Phase

**Research Complete**:
- Core constraints identified
- Risk factors documented
- Required information gathered

**Plan Complete**:
- Concrete task list created
- Priorities established
- Success criteria defined

**Execute Complete**:
- All tests passing
- Code review standards met
- Documentation completed

### Automated Validation
```bash
# Auto-execute upon phase completion
make test && make lint && make build
```

## Failure Handling

### Phase-specific Failure Response
- **Research Failure**: Switch to manual information gathering
- **Plan Failure**: Re-plan with simpler approach
- **Execute Failure**: Debug step-by-step, then partial re-execution

### Quality Degradation Tolerance
- Secure minimum functionality even if imperfect
- Maintain structure allowing incremental improvement
- Document technical debt clearly

## Performance Optimization

### Token Efficiency
- Transmit only essential information
- Remove unnecessary context
- Enhance reusability with structured deliverables

### Parallel Processing
- Maximize batch execution of independent tasks
- Distribute heavy workloads via Task tool
- Optimize through automatic MCP server selection

### Caching Utilization
- Reuse analysis results within session
- Leverage pattern learning outcomes
- Prevent duplicate work

## Usage

```bash
/research-plan-execute [project or task description]
```

**Examples**:
- `/research-plan-execute "React dashboard performance optimization"`
- `/research-plan-execute "Microservices architecture design"`
