---
name: analyze
description: "Comprehensive codebase analysis with automated quality reports and improvement suggestions"
agents: [system-architect, code-reviewer, debugger]
---

<command>
/analyze - Comprehensive Codebase Analysis

<purpose>
Deliver a thorough analysis of your codebase with actionable insights for improvement. This goes beyond simple code review to provide strategic recommendations for architecture, performance, security, and maintainability.
</purpose>

<usage>
```bash
/analyze                    # Full codebase analysis with parallel processing
/analyze [path]             # Targeted analysis of specific directory or file
```
</usage>

<what-it-does>

<details>
<summary><strong>Multi-Dimensional Analysis</strong></summary>

The analysis covers multiple aspects of your codebase:

-   **Architecture**: Module dependencies, coupling analysis, design patterns usage
-   **Performance**: Bottlenecks, resource usage patterns, optimization opportunities  
-   **Quality**: Code complexity, maintainability metrics, technical debt assessment
-   **Best Practices**: Framework conventions, industry standards compliance
-   **Documentation**: Code coverage, inline documentation quality

</details>

<details>
<summary><strong>Contextual Intelligence</strong></summary>

Unlike generic analysis tools, this command understands your specific technology stack:

-   **Framework-Aware**: Recognizes React, Vue, Node.js, Python, Go, etc. patterns and applies relevant best practices
-   **Project-Specific**: Analyzes your actual dependencies, build configuration, and project structure
-   **Integration**: It respects `.gitignore` and leverages `Context7` to fetch the latest best practices and migration guides relevant to your specific stack

</details>

<details>
<summary><strong>Intelligent Processing</strong></summary>

Optimized analysis approach:

-   **Parallel Processing**: Multiple analysis dimensions run simultaneously  
-   **Adaptive Complexity**: Simple analysis for small changes, comprehensive for major refactors
-   **Smart Context**: Minimize redundant operations and focus on relevant code areas

</details>

<details>
<summary><strong>Actionable Output</strong></summary>

The analysis produces concrete, prioritized recommendations:

-   **Priority Scoring**: Issues ranked by impact and effort required
-   **Code Examples**: Before/after snippets showing specific improvements
-   **Implementation Guidance**: Step-by-step instructions for applying recommendations
-   **Resource Links**: Documentation and tutorials relevant to your stack

</details>

</what-it-does>

<token-optimization>
- **Brief Mode**: Essential issues only (top 3 priorities)
- **Standard Mode**: Comprehensive analysis with moderate detail
- **Detailed Mode**: Full analysis for complex codebases
- **Progressive Output**: Incremental results for large repositories
</token-optimization>

<dynamic-research-process>
Analysis adapts to task complexity:

- **Simple**: Direct code analysis with existing patterns
- **Complex**: Task agent coordination for parallel research
- **Framework-Specific**: Context7 integration for best practices
- **Legacy/Migration**: WebSearch for latest patterns and migration guides
</dynamic-research-process>

<mcp-integration>
- **Sequential**: Multi-step analysis planning and systematic evaluation
- **Context7**: Framework-specific best practices and current industry standards
- **Task**: Parallel research for complex analysis scenarios
</mcp-integration>

<process>
1. **Discovery**: File structure, tech stack, patterns (parallel)
2. **Research**: Framework best practices and current standards (Context7/WebSearch)
3. **Analysis**: Architecture, quality, performance analysis run simultaneously
4. **Report**: Prioritized issues with actionable recommendations
</process>

<output-example>

```
## Code Analysis Report

### Priority 1: Critical Issues
- **Performance**: Database N+1 queries in UserService.ts:45
  - Impact: 300ms+ response time
  - Fix: Implement eager loading with joins

- **Security**: Exposed API keys in config/app.js:12
  - Impact: Production credentials leak
  - Fix: Move to environment variables

### Priority 2: Architecture Improvements  
- **Coupling**: Tight dependency between auth and user modules
  - Impact: Hard to test and maintain
  - Fix: Implement dependency injection pattern

### Priority 3: Code Quality
- **Complexity**: UserController.validateInput() has 15+ conditions
  - Impact: Hard to understand and debug
  - Fix: Extract validation rules to separate functions
```

The analysis produces a comprehensive report with prioritized recommendations and implementation guidance.
</output-example>
</command>
