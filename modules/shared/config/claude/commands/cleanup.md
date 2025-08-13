---
name: cleanup
description: "Clean up code, remove dead code, and optimize project structure with safety validation"
agents: [system-architect]
---

# /cleanup - Code and Project Cleanup

**Purpose**: Systematically clean up code, remove dead code, and optimize project structure through intelligent analysis with safety validation

## Usage

```bash
/cleanup [target]            # Safe code cleanup
/cleanup dead-code [path]    # Dead code detection and removal
/cleanup imports [path]      # Import optimization
/cleanup structure [path]    # -> system-architect agent
```

## Execution Strategy

- **Basic**: Safe cleanup with dead code detection and import optimization
- **Dead Code**: Intelligent unused code identification and removal
- **Imports**: Organize and optimize import statements
- **Structure**: Architectural cleanup and dependency optimization
- **Safety**: Comprehensive validation with backup capabilities

## MCP Integration

- **Sequential**: Multi-step cleanup planning and systematic analysis
- **Context7**: Framework-specific cleanup patterns and best practices

## Examples

```bash
/cleanup src/                # General code cleanup
/cleanup dead-code legacy/   # Remove unused code
/cleanup imports components/ # Optimize import statements
/cleanup structure core/     # Architectural cleanup
```

## Agent Routing

- **system-architect**: Complex structural cleanup, architectural optimization, dependency management
