---
name: analyze
description: "Comprehensive codebase analysis with automated quality reports and improvement suggestions"
agents: [performance-optimizer, root-cause-analyzer]
---

# /analyze - Comprehensive Codebase Analysis

**Purpose**: Deliver thorough analysis of your codebase with actionable insights for improvement. Goes beyond simple code review to provide strategic recommendations for architecture, performance, and maintainability.

## Usage

```bash
/analyze                    # Full codebase analysis
/analyze [path]             # Targeted analysis
/analyze troubleshoot       # Deep-dive problem diagnosis
/analyze [error/issue]      # Root cause analysis
```

## Analysis Coverage

**Multi-Dimensional Analysis**:
- **Architecture**: Module dependencies, coupling analysis, design patterns usage
- **Performance**: Bottlenecks, resource usage patterns, optimization opportunities  
- **Quality**: Code complexity, maintainability metrics, technical debt assessment
- **Best Practices**: Framework conventions, industry standards compliance
- **Documentation**: Code coverage, inline documentation quality

**Contextual Intelligence**:
- **Framework-Aware**: Recognizes React, Vue, Node.js, Python, Go patterns and applies relevant best practices
- **Project-Specific**: Analyzes actual dependencies, build configuration, and project structure
- **Integration-Ready**: Respects `.gitignore` and leverages latest best practices relevant to your stack

**Advanced Troubleshooting**:
- **Root Cause Analysis**: Systematic investigation from symptoms to underlying causes
- **Dependency Mapping**: Trace issues through interconnected systems and modules
- **Pattern Recognition**: Identify recurring problems and systemic issues
- **Multi-Layer Investigation**: Analyze problems across code, configuration, environment, and architecture

**Actionable Output**:
- **Priority Scoring**: Issues ranked by impact and effort required
- **Code Examples**: Before/after snippets showing specific improvements
- **Implementation Guidance**: Step-by-step instructions for applying recommendations

## MCP Integration

- **Sequential**: Multi-step analysis planning and systematic evaluation
- **Context7**: Framework-specific best practices and current industry standards
- **Serena**: Code pattern analysis for existing projects

## Examples

```bash
/analyze                    # Complete codebase analysis
/analyze src/components     # Focus on specific directory
/analyze package.json       # Dependency and configuration analysis
/analyze troubleshoot       # Deep-dive system diagnosis
/analyze "TypeError: Cannot read property 'id' of undefined"  # Error investigation
/analyze "slow database queries"  # Performance issue analysis
/analyze "tests failing intermittently"  # Flaky test root cause analysis
```

The analysis produces a comprehensive report with prioritized recommendations and specific implementation guidance.
