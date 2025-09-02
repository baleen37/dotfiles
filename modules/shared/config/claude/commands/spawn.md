---
name: spawn
description: "Task orchestration and breakdown for complex multi-step operations"
---

# /spawn - Task Orchestration

**Purpose**: Decompose complex multi-domain operations into coordinated task hierarchies with intelligent execution strategies

## Usage

```bash
/spawn <complex-task>        # Task breakdown and orchestration
/spawn parallel <task>       # Parallel execution strategy
/spawn sequential <task>     # Sequential execution strategy
/spawn preview <task>        # Preview breakdown without execution
```

## Execution Strategy

- **Basic**: Intelligent task decomposition with Epic → Story → Task hierarchy
- **Parallel**: Independent task execution with resource optimization
- **Sequential**: Dependency-ordered execution with optimal chaining
- **Preview**: Task breakdown analysis without execution
- **Coordination**: Multi-domain operation management

## MCP Integration

- **Sequential**: Multi-step task planning and systematic breakdown

## Examples

```bash
/spawn "implement user authentication system"    # Multi-domain task breakdown
/spawn parallel "migrate to microservices"      # Parallel execution strategy
/spawn sequential "setup CI/CD pipeline"        # Sequential execution
/spawn preview "refactor codebase"              # Task breakdown preview
```

## Agent Routing

- No specialized agents required - uses Task tool for agent coordination when needed
