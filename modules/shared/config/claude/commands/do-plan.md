---
name: do-plan
description: "Execute existing plan.md file with TodoWrite tracking and implementation"
tools: [TodoWrite, Task, Read]
---

# /do-plan - Plan Execution

**Purpose**: Execute an existing plan.md file with systematic TodoWrite tracking and implementation.

## Process

### 1. Plan File Detection
**Requires existing plan.md file in current directory**
- Read and parse plan.md contents
- Extract actionable steps and success criteria
- If no plan.md found: suggest using `/save-plan` first

### 2. TodoWrite Setup
Convert plan steps into TodoWrite tasks:
- Break down each step into trackable todos
- Set appropriate task priorities and dependencies  
- Begin execution with systematic progress tracking

### 3. Step-by-Step Execution
Execute plan with full implementation:
- Mark tasks in_progress before starting
- Complete actual coding, configuration, testing
- Mark tasks completed immediately after finishing
- Use appropriate tools and agents for each step

### 4. Progress Tracking
Maintain visibility throughout execution:
- Real-time TodoWrite status updates
- Implementation notes and discoveries
- Blockers and resolution strategies

## Usage Examples

### Basic Execution
```bash
/do-plan
# Reads plan.md and executes all steps with TodoWrite tracking
```

### Expected plan.md Format
```markdown
# Project Title

## Overview
Brief description and scope

## Steps
1. Setup project structure
2. Implement core functionality  
3. Add tests and validation
4. Deploy and configure

## Success Criteria
- All tests pass
- Feature works as expected
- Documentation updated
```

## Key Features

- **Full Implementation**: Actually executes code changes, not just planning
- **TodoWrite Integration**: Systematic progress tracking
- **Agent Coordination**: Uses appropriate specialized agents
- **Tool Utilization**: Leverages all available development tools
- **Error Handling**: Manages blockers and implementation challenges

## Integration

- **Prerequisites**: Existing plan.md file (use `/save-plan` to generate)
- **Output**: Fully implemented solution with tracked progress
- **Workflow**: `/save-plan` → `/do-plan` execution pipeline
- **Flexibility**: Can pause/resume execution as needed

## Execution Principles

- **Implementation First**: Focus on actual coding and changes
- **Systematic Progress**: TodoWrite tracking throughout
- **Quality Assurance**: Testing and validation at each step  
- **Documentation**: Update relevant docs during implementation
