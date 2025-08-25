---
name: plan
description: "Smart task planning with structured breakdown and execution preparation"
agents: [system-architect, project-manager]
tools: [TodoWrite, Task, ExitPlanMode]
---

# /plan - Smart Task Planning

**Purpose**: Analyze requirements and create actionable step-by-step plans

## Planning Process

### 1. Requirements Analysis
- Understand current situation and goals
- Identify technical constraints
- Assess required resources

### 2. Task Breakdown
- Break large tasks into smaller units
- Define dependencies for each step
- Estimate time requirements

### 3. Execution Sequencing
- Order tasks considering dependencies
- Identify tasks that can run in parallel
- Risk assessment and contingency planning

## Usage Examples

### Basic Usage
```bash
/plan "Implement new login system"
```

**Example Output**:
```
## Login System Implementation Plan

### Phase 1: Analysis & Design (2-3 hours)
- [ ] Analyze current authentication system
- [ ] Define security requirements
- [ ] Design database schema

### Phase 2: Backend Implementation (1-2 days)
- [ ] Develop authentication API
- [ ] Implement password hashing
- [ ] JWT token management

### Phase 3: Frontend Integration (1 day)
- [ ] Implement login form
- [ ] Token storage and management
- [ ] Error handling and validation

### Phase 4: Testing & Deployment (half day)
- [ ] Write unit tests
- [ ] Run integration tests
- [ ] Deploy and monitor
```

### API Development Planning
```bash
/plan "Build RESTful API server"
```

### Refactoring Planning
```bash
/plan "Migrate existing codebase to TypeScript"
```

## Useful Features

### Risk Identification
Includes potential issues and solutions for each phase

### Dependency Management
Clearly shows task order and bottlenecks

### Time Estimation
Realistic work time predictions for schedule management

## do-plan Integration

Generated plans can be executed directly with `/do-plan`:

```bash
# After plan generation
/do-plan
```

Each phase is executed as a checklist with real-time progress tracking.
