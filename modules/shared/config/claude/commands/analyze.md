---
name: analyze
description: "Systematic code analysis: Scan → Analyze → Report with actionable plan"
mcp-servers: [sequential-thinking, context7, serena]
agents: [security-auditor, performance-optimizer]
---

# /analyze - Systematic Code Analysis

**Purpose**: Systematic code review with actionable improvement plan

## Usage

```bash
/analyze [path]           # Full systematic analysis
/analyze security [path]  # Security focus → security-auditor
/analyze performance [path] # Performance focus → performance-optimizer
```

## 3-Phase Analysis Process

### Phase 1: Scan
**Goal**: Understand codebase and identify issues
```bash
□ Map file structure and dependencies
□ Identify code smells and potential bugs
□ Check for security vulnerabilities
□ Measure performance bottlenecks
```

### Phase 2: Analyze
**Goal**: Assess severity and business impact
- **P0 Critical**: Security holes, production bugs
- **P1 High**: Performance issues, maintainability problems  
- **P2 Medium**: Code quality, minor optimizations

### Phase 3: Report
**Goal**: Actionable plan with specific next steps

## Report Structure

### Executive Summary
- **Overall Score**: 🔴 Needs Work / 🟡 Good / 🟢 Excellent
- **Critical Issues**: Must fix immediately (P0)
- **Recommended Focus**: What to tackle first

### Detailed Findings
```
🔴 [P0] SQL Injection in user authentication
   File: api/auth.js:23
   Impact: Full database compromise possible
   Fix: Use parameterized queries with validation

🟡 [P1] N+1 query problem in data fetching  
   File: services/UserService.js:45
   Impact: 300ms+ page load times
   Fix: Add eager loading or batch queries

🟢 [P2] Unused dependencies detected
   Files: package.json, 12 components
   Impact: 2MB bundle size increase
   Fix: Remove unused imports via cleanup script
```

### Action Plan Checklist
- [ ] **This Week**: Fix all P0 security issues
- [ ] **Next Sprint**: Address P1 performance bottlenecks
- [ ] **Ongoing**: Gradually improve P2 code quality

## Analysis Checklist

**Security**:
- [ ] Input validation and sanitization
- [ ] Authentication and authorization flows
- [ ] Dependency vulnerability scan
- [ ] Secrets and sensitive data handling

**Performance**:
- [ ] Algorithm complexity analysis
- [ ] Database query optimization
- [ ] Memory usage patterns
- [ ] Bundle size and loading performance

**Code Quality**:
- [ ] Code duplication and reusability
- [ ] Naming conventions and readability
- [ ] Test coverage and reliability
- [ ] Documentation and maintainability

## Examples

```bash
/analyze                    # Complete systematic review
/analyze src/auth          # Focus on authentication module
/analyze security          # Security-only deep scan
/analyze performance api/  # Performance review of API layer
```

## Smart Agent Routing

- **security-auditor**: Auto-triggered for auth, API, data handling
- **performance-optimizer**: Auto-triggered for algorithms, queries, bottlenecks
- **sequential-thinking**: For complex multi-step analysis workflows
