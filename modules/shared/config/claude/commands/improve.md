# /improve - Code Quality Enhancement

Automatically improve code quality, performance, and maintainability through intelligent analysis.

## Purpose
Automatically select appropriate improvement strategies based on code complexity for efficient quality enhancement.

## Usage
```bash
/improve [target]                    # Smart improvement
/improve [target] --think            # Deep analysis-based improvement  
/improve [target] --ultrathink       # Comprehensive analysis and improvement
```

## Task Complexity Strategy

### Simple Tasks (Default Mode)
```bash
/improve [target]
```
- Single file modifications
- Clear improvement points
- Direct processing for quick results

### Moderate Tasks (--think)
```bash
/improve [target] --think
```
- Multi-file improvements
- Architectural pattern analysis
- Performance bottleneck analysis
- Security vulnerability scanning

### Complex Tasks (--ultrathink)
```bash
/improve [target] --ultrathink
```
- System-wide impact analysis
- Legacy modernization strategies
- Technical debt prioritization matrix
- Comprehensive refactoring roadmap

## Coordination Strategy

### When to Use Subagents
- **Complex Analysis (3+ steps)**: Delegate to specialized subagents via Task tool
- **Multi-domain Problems**: Use multiple experts (security-auditor, performance-engineer, etc.)
- **System-wide Changes**: Coordinate backend-architect, frontend-developer, test-automator

### When to Handle Directly
- **Simple Fixes**: Single file modifications
- **Quick Updates**: Clear, straightforward improvements
- **Immediate Context**: Tasks requiring current conversation context

## Examples

### Basic Usage
```bash
/improve                          # Smart automatic improvement
/improve src/components          # Component-focused improvement  
/improve api/                    # API enhancement
```

### Deep Analysis
```bash
/improve src/ --think            # Multi-file architectural analysis
/improve . --ultrathink          # System-wide comprehensive review
/improve legacy/ --ultrathink    # Complete legacy modernization
```

## Implementation

### Complexity Assessment
- **Simple (1-2 steps)**: Direct processing, avoid subagent overhead
- **Moderate (3-5 steps)**: TodoWrite + selective subagent delegation
- **Complex (6+ steps)**: Full orchestration with specialized subagents

### Quality Assurance
- **Context Preservation**: Maintain project context across all delegations
- **Coordinated Validation**: Use appropriate subagents for quality gates
- **Result Integration**: Synthesize subagent outputs into coherent solutions
