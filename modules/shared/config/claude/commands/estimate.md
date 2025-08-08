---
name: estimate
description: "Generate development estimates with intelligent complexity analysis"
mcp-servers: [sequential-thinking, context7, serena]
agents: [system-architect]
---

# /estimate - Development Estimation

**Purpose**: Generate accurate development estimates for tasks, features, or projects based on intelligent complexity analysis and historical patterns

## Usage

```bash
/estimate <target>           # Time and effort estimation
/estimate time <task>        # Time-focused estimation
/estimate complexity <task>  # Complexity analysis
/estimate project <scope>    # -> system-architect agent
```

## Execution Strategy

- **Basic**: Scope analysis with time and effort breakdown
- **Complexity**: Multi-factor complexity assessment with dependencies
- **Time**: Detailed time estimation with confidence intervals
- **Project**: Comprehensive project estimation with risk factors
- **Validation**: Historical data comparison and accuracy checks

## MCP Integration

- **Sequential**: Multi-step analysis and systematic breakdown
- **Context7**: Framework-specific patterns and complexity benchmarks

## Examples

```bash
/estimate user authentication      # Basic feature estimation
/estimate time API development     # Time-focused estimation
/estimate complexity distributed-system # Complexity analysis
/estimate project mobile-app      # Full project estimation
```

## Agent Routing

- **system-architect**: Complex project estimations, architectural complexity assessment, multi-component analysis
