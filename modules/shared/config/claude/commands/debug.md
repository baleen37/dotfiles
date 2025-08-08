---
name: debug
description: "Diagnose and resolve issues with systematic debugging and root cause analysis"
mcp-servers: [sequential, datadog]
agents: [debugger]
tools: [Read, Bash, Grep, Glob, Write]
---

# /debug - Issue Diagnosis and Resolution

**Purpose**: Execute systematic debugging workflows for code defects, build failures, and system issues with root cause analysis

## Usage

```bash
/debug <issue>               # General issue debugging
/debug build                 # Build failure diagnosis
/debug performance           # Performance issue analysis
/debug error <message>       # Specific error investigation
```

## Execution Strategy

- **Basic**: Systematic root cause analysis with hypothesis testing
- **Build Issues**: Compilation errors, dependency conflicts, configuration problems
- **Performance**: Bottleneck identification and optimization recommendations
- **Error Analysis**: Log analysis and error pattern detection
- **Resolution**: Safe fix application with verification

## MCP Integration

- **Sequential**: Multi-step debugging workflows and systematic analysis
- **Datadog**: Log analysis, metrics investigation, performance monitoring

## Examples

```bash
/debug "TypeScript compilation errors"     # Build issue debugging
/debug performance api                     # API performance analysis
/debug error "Cannot read property"        # Specific error investigation
/debug tests failing                       # Test failure diagnosis
```

## Agent Routing

- **debugger**: Complex debugging scenarios, systematic root cause analysis, multi-step investigations
