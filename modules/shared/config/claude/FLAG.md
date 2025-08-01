# Claude Code Thinking Mode Flags

A guide for utilizing thinking mode flags available in Claude Code.

## Thinking Mode Flags

### --think
```
Usage: "Solve this problem --think"
```
**Features:**
- Displays step-by-step logical thinking process
- Progresses through problem analysis → solution derivation → implementation stages
- Explicitly shows intermediate processes
- Systematic approach to complex problems

**When to use:**
- When complex logic design is needed
- During debugging and problem root cause analysis
- When architectural decisions are required
- When finding optimal solutions among multiple options

### --ultrathink
```
Usage: "Design this architecture --ultrathink"
```
**Features:**
- Deeper analysis than --think
- Multi-angle review and alternative comparison
- Considers pros/cons analysis and trade-offs
- Takes into account future scalability and maintainability

**When to use:**
- For important architectural decisions
- When establishing complex refactoring plans
- For performance optimization strategy design
- For comprehensive security vulnerability analysis

## New Specialized Thinking Modes

### --analyze
```
Usage: "Analyze this codebase --analyze"
```
**Features:**
- Thinking mode specialized for systematic analysis
- Follows data collection → pattern recognition → conclusion derivation sequence
- Evidence-based analysis and objective evaluation
- Clearly distinguishes structural problems from improvement points

**When to use:**
- For comprehensive codebase analysis
- Technical debt assessment
- System health diagnosis
- Data pattern analysis

### --debug  
```
Usage: "Fix this error --debug"
```
**Features:**
- Thinking mode focused on problem-solving
- Centers on Root Cause Analysis
- Follows hypothesis formation → verification → solution presentation
- Includes recurrence prevention strategies

**When to use:**
- Complex bug debugging
- System failure analysis
- Performance problem resolution
- Exception handling situations

### --architect
```
Usage: "Design microservice architecture --architect"
```
**Features:**
- System design-centered thinking mode
- Comprehensively considers scalability, maintainability, and performance
- Specifies rationale for technology choices and trade-offs
- Considers long-term evolution paths

**When to use:**
- Designing new system architecture
- Improving existing system structure
- Technology stack selection
- Scalability planning

### --optimize
```  
Usage: "Optimize this query --optimize"
```
**Features:**
- Specialized for performance and efficiency optimization
- Follows measure → analyze → improve → verify cycle
- Focuses on resource usage and execution time
- Provides before/after optimization comparison analysis

**When to use:**
- Performance bottleneck improvement
- Resource usage optimization
- Algorithm efficiency improvement
- Cost optimization

## Usage Guidelines

### Effective Flag Selection
1. **Based on task complexity**: Basic mode for simple tasks, --think or higher for complex tasks
2. **Balance of time and quality**: Basic mode for urgent tasks, --ultrathink for important decisions
3. **Learning and understanding**: Use --think when you want to understand complex logic

### Practical Application Examples

#### General Development Tasks (--think)
```
"Implement user login functionality --think"
"Add error handling logic to this function --think"
"Optimize database query --think"
```

#### Specialized Analysis Tasks
```
"Assess technical debt in this codebase --analyze"
"Find the root cause of login failures --debug"
"Design scalable API architecture --architect"
"Improve query performance --optimize"
```

#### Large-scale Strategic Tasks (--ultrathink)
```
"Establish legacy system modernization strategy --ultrathink"
"Design security architecture for entire system --ultrathink"
"Plan microservice architecture transition --ultrathink"
```

### Flag Combination Usage
Multiple flags can be combined for more precise thinking modes:
```
"Comprehensively analyze system performance issues --analyze --debug --optimize"
"Design and optimize new microservice --architect --optimize"
"Find and solve security vulnerabilities with comprehensive analysis --analyze --debug --ultrathink"
```

## Performance Considerations

- **Basic mode**: Fast response, optimal for simple tasks
- **--think**: Standard response time, suitable for most complex tasks
- **--ultrathink**: May take longer to respond, use only for critical decisions
