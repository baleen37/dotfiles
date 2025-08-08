---
name: build
description: "Build, compile, and package projects with intelligent error handling and optimization"
mcp-servers: [playwright]
agents: [devops-engineer]
tools: [Read, Bash, Grep, Glob, Write]
---

# /build - Project Building

**Purpose**: Build and compile projects with comprehensive error handling and deployment preparation

## Usage

```bash
/build [target]              # Build entire project or specific target
/build clean                 # Clean build artifacts first
/build prod                  # Production build with optimizations
```

## Execution Strategy

- **Basic**: Execute build system using existing configuration
- **Clean**: Remove artifacts and caches before building
- **Production**: Apply optimizations and generate deployment packages
- **Error Handling**: Analyze build failures with actionable solutions

## MCP Integration

- **Playwright**: Build validation and automated testing of build artifacts

## Examples

```bash
/build                       # Full project build
/build frontend              # Build specific module
/build clean prod           # Clean production build
/build test                 # Build for testing
```

## Agent Routing

- **devops-engineer**: Complex build configurations, deployment preparation, CI/CD integration
