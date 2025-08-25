---
name: analyze
description: "Intelligent codebase analysis with automated quality reports, performance insights, and architecture recommendations"
argument-hint: "Natural language description of analysis target and requirements (paths, error messages, problem situations, etc.)"
allowed-tools: Read, Grep, Bash, Context7, Task(performance-optimizer), Task(root-cause-analyzer), Task(system-architect), Task(debugger)
agents: [performance-optimizer, root-cause-analyzer, system-architect, debugger]
---

# /analyze - Comprehensive Codebase Analysis

**Purpose**: Automatically assess project situation to prioritize the most urgent issues, with optional $ARGUMENTS for additional focus areas, delivering actionable improvement recommendations.

## Fully Automated Analysis

AI scans the project and automatically determines priorities for analysis:

```bash
/analyze                    # AI automatically judges and analyzes everything

# AI's automatic decision process:
# 1. Project scan: Auto-detect tech stack, file structure, git history
# 2. Issue detection: Auto-identify error logs, performance metrics, stability risks
# 3. Priority ranking: Auto-prioritize by urgency and impact
# 4. Optimal strategy: Auto-select appropriate analysis tools and agents
# 5. Execute & report: Perform analysis and provide actionable solutions

# When $ARGUMENTS provided, used as additional focus areas
/analyze "seems slow"           # AI base analysis + performance focus
/analyze "errors happening"     # AI base analysis + stability focus
```

## Core Features

### 🎯 Multi-Dimensional Analysis Engine
- **Architecture**: Module dependencies, coupling analysis, design pattern evaluation
- **Performance**: Bottleneck identification, resource usage patterns, optimization opportunities
- **Quality**: Code complexity, technical debt measurement, maintainability metrics
- **Stability**: Error patterns, test coverage, exception handling
- **Compliance**: Framework conventions, industry standard adherence

### 🧠 Intelligent Context Recognition
- **Auto tech stack detection**: Automatically parse package.json, requirements.txt, go.mod, etc.
- **Problem pattern recognition**: Analyze git commits, error logs, performance metrics to auto-detect issues
- **Auto priority determination**: Automatically rank importance as Stability > Performance > Quality
- **Optimal tool selection**: Auto-select most effective analysis tools based on situation

### ⚡ Smart Agent Routing & Performance Optimization

| Processing Mode | Analysis Time | Token Usage | Accuracy | Recommended Use |
|-----------------|---------------|-------------|----------|-----------------|
| Default Mode | 3-5 min | 100% | 85% | General analysis |
| Agent Mode | 1-3 min | 70% | 90% | Expert-level analysis |
| Critical Scope | 1-2 min | 50% | 95% | Urgent issue diagnosis |

**Parallel Processing Architecture**:
- **Context Sharing**: 50% I/O savings through shared file reads
- **Adaptive Routing**: Auto-select optimal agents by issue type
- **Token Optimization**: 30% cost reduction through deduplication

## Automatic Agent Selection

AI automatically selects optimal agents based on project scan results:

| Detected Situation | Auto-Selected Agent | Processing Content |
|---------------------|--------------------|--------------------|
| **Errors/Crashes Found** | debugger | Log analysis, error pattern tracking, root cause identification |
| **Performance Degradation** | performance-optimizer | Bottleneck identification, memory usage, optimization strategies |
| **Complex Issues** | root-cause-analyzer | Multi-issue correlation, system-wide analysis |
| **Structural Problems** | system-architect | Architecture evaluation, scalability review, design improvements |
| **Compound Issues** | Multi-agent parallel | Multiple experts simultaneously analyze from different angles |

## Practical Usage Examples

### Fully Automatic Mode
```bash
/analyze                        # AI automatically judges and executes everything

# What AI does automatically:
# 1. Project scan → Detect React + TypeScript project
# 2. Error log check → Find memory leak patterns
# 3. Performance metrics → Detect rendering bottlenecks
# 4. Git history → Discover recent performance-related commit increases
# 5. Priority decision → Determine stability issues are most urgent
# 6. Agent selection → Run debugger + performance-optimizer simultaneously
# 7. Analysis & report → Provide specific solutions with code examples
```

### With Additional Hints
```bash
/analyze "seems slow"               # AI base analysis + performance focus
/analyze "errors frequently"        # AI base analysis + stability focus
/analyze "code needs cleanup"       # AI base analysis + architecture focus
/analyze "quality check"            # AI base analysis + code quality focus
```

### Example Results
```
🤖 Issues automatically detected by AI:

🔴 Critical (Immediate Action Required)
  - Memory leak: Missing useEffect cleanup (src/hooks/useData.js:45)
  - Stability risk: Missing exception handling (src/api/userService.js:89)

🟡 Performance (Performance Improvements)
  - Unnecessary re-renders (Button component triggers every 3 seconds)
  - Bundle size increase (200KB added from full lodash import)

🟢 Quality (Code Quality)
  - Recommend enabling TypeScript strict mode
  - Test coverage improvement: 45% → 80% target
```

## Analysis Report Format

### 1. Executive Summary
```
🎯 Key Findings (Priority: High/Medium/Low)
📊 Key Metrics (performance, quality, stability scores)
⚠️  Items requiring immediate action
📈 Expected improvement impact
```

### 2. Detailed Analysis Results
```
🔍 Architecture Analysis
  - Module dependency graph
  - Circular dependency detection
  - Coupling/cohesion measurements

⚡ Performance Insights  
  - Bottleneck identification and improvement strategies
  - Memory usage pattern analysis
  - Optimization priorities

🛡️  Stability Assessment
  - Error pattern analysis results
  - Exception handling coverage
  - Test reliability evaluation
```

### 3. Actionable Recommendations
```markdown
## Priority-based Improvement Plan

### 🔴 High Priority (Immediate Action)
- [ ] Memory leak in useEffect cleanup
- [ ] Missing exception handling in auth module  
- [ ] Circular dependency: A → B → A

### 🟡 Medium Priority (Within 2 weeks)
- [ ] Bundle optimization: code splitting
- [ ] API response caching implementation
- [ ] Test coverage improvement (current 45% → target 80%)

### 🟢 Low Priority (Technical Debt)
- [ ] Legacy component refactoring
- [ ] Documentation updates
- [ ] Type safety improvements
```

## MCP Integration & Tools

- **Context7**: Framework-specific best practices and latest standards reference
- **Sequential**: Multi-step analysis planning and systematic evaluation
- **Grep**: Code pattern search and issue identification
- **Bash**: Performance measurement, test execution, build analysis

## Error Handling & Alternative Strategies

### Natural Language Option Processing
```bash
# AI automatically determines processing method
/analyze "urgent stability issues first"            → auto-set critical scope
/analyze "comprehensive full analysis"              → auto-set full scope  
/analyze "stable step-by-step analysis"            → auto-set sequential mode
/analyze "results in JSON format"                  → auto-set json format

# Complex requirements in natural language
/analyze "quick performance check only"            → performance + critical + fast mode
/analyze "thorough memory leak investigation"      → memory analysis + full + documentation
```

### Automatic Analysis Mode Selection
- **critical**: Triggered by "urgent", "first", "important only" keywords
- **full**: Triggered by "comprehensive", "thorough", "all", "complete" keywords
- **sequential**: Triggered by "stable", "step-by-step", "gradual" keywords  
- **json/markdown**: Triggered by "JSON", "report", "document" keywords

## Performance Optimization

- **Token Efficiency**: 50% cost reduction through context deduplication
- **Parallel Processing**: Reduced processing time through multi-agent simultaneous analysis
- **Adaptive Analysis**: Auto-adjust analysis depth based on project size
- **Cache Utilization**: Reuse previous results for repeated analysis

Get comprehensive codebase health insights and specific improvement roadmaps.
