---
name: analyze_v2
description: "Comprehensive multi-domain code analysis with severity-based findings and actionable recommendations"
---

Perform comprehensive code analysis across quality, security, performance, and architecture domains with prioritized, actionable recommendations.

**Usage**: `/analyze_v2 [target]`

## Auto-Analysis

- **Comprehensive Coverage**: Automatically analyzes quality, security, performance, and architecture
- **Smart Depth**: Adjusts analysis depth based on codebase size and complexity
- **Prioritized Results**: Focus on highest-impact issues first


## Severity Classification

- **Critical**: Security vulnerabilities, memory leaks, blocking performance issues
- **High**: Significant quality issues, potential security concerns, performance degradation
- **Medium**: Code maintainability issues, minor performance optimizations
- **Low**: Style improvements, code quality enhancements

## Analysis Flow

1. **Discovery**: Categorize and map source files by language and purpose
2. **Domain Scanning**: Apply focused analysis techniques per domain
3. **Cross-Reference**: Identify relationships and dependencies between issues
4. **Prioritization**: Rank findings by severity and impact
5. **Recommendation**: Generate specific, actionable improvement suggestions
6. **Reporting**: Present findings with context and remediation guidance

## Key Features

- **Language-Aware**: Supports multiple programming languages with specific rules
- **Context-Sensitive**: Considers project architecture and patterns
- **Actionable**: Provides specific remediation steps, not just problem identification
- **Prioritized**: Focus on highest-impact issues first
- **Comprehensive**: Covers code quality, security, performance, and architecture

## Example Usage

```
/analyze_v2 src/
```

This will perform comprehensive analysis on the src directory, automatically determining the appropriate depth and focus areas based on the codebase characteristics.

## Analysis Scope

- Static code analysis (no code execution)
- Cross-file dependency analysis
- Pattern and anti-pattern detection
- Security vulnerability assessment
- Performance bottleneck identification
- Architecture quality evaluation
