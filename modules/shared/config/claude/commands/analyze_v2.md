---
name: analyze_v2
description: "Comprehensive multi-domain code analysis with severity-based findings and actionable recommendations"
---

Perform comprehensive code analysis across quality, security, performance, and architecture domains with prioritized, actionable recommendations.

**Usage**: `/analyze_v2 [target] [--focus quality|security|performance|architecture] [--depth quick|deep]`

## Analysis Domains

- `quality`: Code complexity, duplication, maintainability, coding standards
- `security`: OWASP vulnerabilities, authentication, authorization, data validation
- `performance`: Memory usage, algorithm complexity, bottlenecks, optimization opportunities
- `architecture`: Dependencies, coupling, cohesion, design patterns, structural issues

## Analysis Depth

- `quick`: Fast surface-level analysis for immediate issues
- `deep`: Comprehensive analysis including cross-file relationships and complex patterns


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
/analyze_v2 src/ --focus security --depth deep
```

This will perform deep security analysis on the src directory with vulnerability assessments and remediation guidance.

## Analysis Scope

- Static code analysis (no code execution)
- Cross-file dependency analysis
- Pattern and anti-pattern detection
- Security vulnerability assessment
- Performance bottleneck identification
- Architecture quality evaluation
