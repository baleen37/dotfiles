---
name: build
description: "Build, compile, and package projects with intelligent error handling and optimization"
agents: [devops-engineer]
---

# /build - Project Building

Execute project builds with comprehensive error analysis and optimization support.

## Usage

```bash
/build [target]              # Build entire project or specific target
/build clean                 # Clean build artifacts first
/build prod                  # Production build with optimizations
```

## Process

1. **Detection**: Identify build system (Nix, npm, make, etc.)
2. **Execution**: Run build commands with proper error handling
3. **Analysis**: Parse build errors and suggest solutions
4. **Optimization**: Apply performance and size optimizations

## Features

- **Multi-Platform**: Supports Nix, Node.js, Make, and custom build systems
- **Error Analysis**: Intelligent parsing of build failures with actionable fixes
- **Clean Builds**: Automated artifact cleanup and cache management
- **Production Mode**: Optimizations for deployment and distribution

## Examples

```bash
/build                       # Full project build
/build frontend              # Build specific module  
/build clean prod           # Clean production build
/build test                 # Build for testing
```
