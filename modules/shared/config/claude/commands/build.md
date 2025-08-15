---
name: build
description: "Build, compile, and package projects with intelligent error handling and optimization"
agents: [devops-engineer]
---

<command>
/build - Project Building

<purpose>
Execute project builds with comprehensive error analysis and optimization support.
</purpose>

<usage>
```bash
/build [target]              # Build entire project or specific target
/build clean                 # Clean build artifacts first
/build prod                  # Production build with optimizations
```
</usage>

<process>
1. **Detection**: Identify build system (Nix, npm, make, etc.)
2. **Execution**: Run build commands with proper error handling
3. **Analysis**: Parse build errors and suggest solutions
4. **Optimization**: Apply performance and size optimizations
</process>

<features>
- **Multi-Platform**: Supports Nix, Node.js, Make, and custom build systems
- **Error Analysis**: Intelligent parsing of build failures with actionable fixes
- **Clean Builds**: Automated artifact cleanup and cache management
- **Production Mode**: Optimizations for deployment and distribution
</features>

<examples>
```bash
/build                       # Full project build
/build frontend              # Build specific module  
/build clean prod           # Clean production build
/build test                 # Build for testing
```
</examples>
</command>
