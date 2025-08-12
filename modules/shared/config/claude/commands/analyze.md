---
name: analyze
description: "Comprehensive codebase analysis with automated quality reports and improvement suggestions"
mcp-servers: [sequential, context7]
agents: [performance-optimizer, root-cause-analyzer]
tools: [Read, Grep, Glob, TodoWrite, Task]
---

# /analyze - Comprehensive Codebase Analysis

**Purpose**: Deliver a thorough analysis of your codebase with actionable insights for improvement. This goes beyond simple code review to provide strategic recommendations for architecture, performance, security, and maintainability.

## Usage

```bash
/analyze                    # Full codebase analysis
/analyze [path]             # Targeted analysis
```

## What It Does

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
<summary><strong>Smart Agent Routing & Parallelism</strong></summary>

To deliver results quickly, the tool uses an intelligent, multi-agent approach:

-   **Agents**: Performance-optimizer and root-cause-analyzer agents work in parallel
-   **Efficiency**: This parallel process is up to 50% faster than sequential analysis by sharing file reads and context
-   **Resource Management**: The tool monitors system resources and falls back to sequential process on memory-constrained environments to ensure stability

</details>

<details>
<summary><strong>Actionable Output</strong></summary>

The analysis produces concrete, prioritized recommendations:

-   **Priority Scoring**: Issues ranked by impact and effort required
-   **Code Examples**: Before/after snippets showing specific improvements
-   **Implementation Guidance**: Step-by-step instructions for applying recommendations
-   **Resource Links**: Documentation and tutorials relevant to your stack

</details>

## MCP Integration

- **Sequential**: Multi-step analysis planning and systematic evaluation
- **Context7**: Framework-specific best practices and current industry standards

## Agent Routing

- **performance-optimizer**: Performance bottlenecks, memory usage, optimization opportunities
- **root-cause-analyzer**: Complex issue investigation, dependency analysis, architectural concerns

## Examples

```bash
/analyze                    # Complete codebase analysis
/analyze src/components     # Focus on specific directory
/analyze package.json       # Dependency and configuration analysis
```

The analysis will produce a comprehensive report with prioritized recommendations and specific implementation guidance.
