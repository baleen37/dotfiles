---
name: analyze
description: "Analyzes code for security, performance, and quality issues, and generates a prioritized improvement plan."
mcp-servers: [sequential-thinking, context7]
tools: [Read, Bash, Grep, Glob, Write, Task, TodoWrite, WebSearch]
---

# /analyze - Code Analysis & Improvement Planning

**Core Principle**: This command is for **analysis and planning**, not execution. Its goal is to thoroughly assess a codebase and produce a clear, prioritized plan for improvement.

## Quick Start

```bash
# Analyze the current directory and view the report.
/analyze

# Run a security-focused analysis.
/analyze security

# Generate a prioritized to-do list in Markdown.
/analyze --todo > IMPROVEMENT_PLAN.md
```

## Core Concepts: Issue Prioritization

The analysis report categorizes issues to help you focus on what matters most:

- **P0 (Critical)**: Urgent issues posing a direct risk to security, stability, or data integrity. (e.g., SQL injection, data leaks).
- **P1 (High)**: Significant problems degrading performance or maintainability. (e.g., N+1 queries, high complexity).
- **P2 (Medium)**: Minor issues related to code quality, style, or small optimizations.

## Usage & Examples

*Note: `/analyze` is a command run within the Claude Code environment.*

### Analysis Scopes
```bash
# Analyze the entire current directory.
/analyze

# Analyze a specific subdirectory.
/analyze src/api/v1/

# Narrow the focus to security, performance, or quality.
/analyze security services/auth/
/analyze performance data/processing/
/analyze quality frontend/components/
```

### Reporting & Tracking

```bash
# Generate the standard, non-interactive report.
/analyze --report-only

# Compare to the last analysis to see the trend.
/analyze --history

# Export all findings to a Markdown to-do list for planning.
/analyze --todo
```

## The Analysis Report Explained

### 1. Executive Summary
- **Overall Score**: 🟡 72/100 (`🔴 <60` / `🟡 60-85` / `🟢 >85`)
- **Trend**: 📈 Improving (+5 pts since last week)
- **Critical Issues**: 🔴 2 found
- **Recommended Focus**: Security. Address the 2 P0 vulnerabilities first.

### 2. Detailed Findings
This section provides clear, actionable guidance for your plan.

```
🔴 [P0] SQL Injection in User Authentication
   - File:          api/auth.js:23
   - Impact:        Allows attackers to bypass authentication.
   - Recommendation: Refactor the database query to use parameterized statements, preventing SQL injection.
   - Verification:  Ensure the existing security test suite for authentication passes after the change.

🟡 [P1] N+1 Query Problem in Data Fetching
   - File:          services/UserService.js:45
   - Impact:        Causes slow page loads (e.g., 300ms+).
   - Recommendation: Modify the data access logic to use eager-loading (e.g., `include` in an ORM) to fetch related data in a single query.
   - Verification:  Run the relevant benchmark test to confirm a performance gain of at least 50% for this operation.

🟢 [P2] Unused Dependency Detected
   - File:          package.json
   - Impact:        Increases final bundle size by 2MB.
   - Recommendation: Remove the unused dependency from your `package.json` and run your package manager's install command to clean up `node_modules`.
   - Verification:  Confirm the dependency is removed from the final production bundle.
```

## Workflow Integration & Best Practices

To get the most out of `/analyze`, integrate it into your regular workflow:

-   **Pre-Commit Check**: Run `/analyze security` on your staged files before committing to catch issues early.
-   **CI/CD Pipeline**: Add `/analyze --report-only` to your CI pipeline to fail builds on new P0 or P1 issues, preventing regressions.
-   **Sprint Planning**: Use the output of `/analyze --todo` to create stories or tasks in your project management tool (e.g., Jira, Asana).
-   **Quarterly Reviews**: Use `/analyze --history` to track and report on code quality improvements over time.

---

## Appendix: Advanced Details

<details>
<summary><strong>Context-Aware Analysis Engine</strong></summary>

The analyzer automatically detects your project's framework and language to provide more accurate and relevant recommendations.

-   **Frameworks**: Next.js, React, Vue, Django, Express, Fastify, and more.
-   **Languages**: TypeScript, Python, Go, Rust, etc.
-   **Integration**: It respects `.gitignore` and leverages `Context7` to fetch the latest best practices, security advisories, and migration guides relevant to your specific stack.

</details>

<details>
<summary><strong>Smart Agent Routing & Parallelism</strong></summary>

To deliver results quickly, the tool uses an intelligent, multi-agent approach.

-   **Agents**: A `security-auditor` and a `performance-optimizer` agent work in parallel.
-   **Efficiency**: This parallel process is up to 50% faster than a sequential analysis by sharing file reads and context.
-   **Resource Management**: The tool monitors system resources and falls back to a sequential process on memory-constrained environments to ensure stability.

</details>
