# /improve - Interactive Code Improvement

**Purpose**: Apply systematic improvements through intelligent conversation, adaptive planning, and collaborative decision-making.

## Usage

```bash
/improve                    # Interactive full codebase improvement
/improve [target]           # Interactive targeted improvement
/improve src/auth          # Improve specific module with guided conversation
```

## What It Does

<details>
<summary><strong>Conversational Improvement Process</strong></summary>

1. **Discover**: Analyze target and identify improvement opportunities
2. **Discuss**: Ask clarifying questions about priorities and constraints  
3. **Plan**: Collaboratively design improvement strategy
4. **Execute**: Implement improvements with ongoing validation
5. **Review**: Evaluate results and gather feedback for future improvements

</details>

<details>
<summary><strong>Intelligent Question Framework</strong></summary>

The tool automatically asks relevant questions based on context:

- **New Project**: "What's your main concern - performance, maintainability, or security?"
- **Legacy Code**: "Are you planning a gradual refactor or major overhaul?"
- **Performance Issues**: "Are you seeing specific bottlenecks or general slowness?"
- **Security Code**: "What's your security compliance requirements?"
- **Team Project**: "What's the team's experience level with these patterns?"

</details>

<details>
<summary><strong>Adaptive Planning</strong></summary>

- **Risk Assessment**: Evaluates complexity and suggests appropriate approaches
- **Resource Consideration**: Factors in time constraints and team capacity
- **Incremental Strategy**: Breaks large improvements into manageable steps
- **Validation Points**: Identifies key checkpoints for testing and review
- **Rollback Planning**: Ensures safe execution with clear recovery paths

</details>

<details>
<summary><strong>Context-Aware Analysis</strong></summary>

- **Framework Detection**: Identifies technologies and suggests best practices
- **Pattern Recognition**: Detects common anti-patterns and improvement opportunities  
- **Dependency Analysis**: Understands impact of changes across the codebase
- **Performance Profiling**: Identifies real bottlenecks vs perceived issues
- **Security Assessment**: Evaluates vulnerabilities based on actual usage patterns

</details>

## MCP Integration

- **Sequential**: Multi-step improvement planning with conversational checkpoints
- **Context7**: Framework-specific best practices and migration guidance

## Agent Routing

- **system-architect**: For architectural decisions and design discussions
- **backend-engineer**: For performance and infrastructure improvements
- **code-reviewer**: For quality and security enhancement conversations
- **test-automator**: For testing strategy and coverage discussions

## Conversation Examples

```bash
/improve auth-service/
```

**Assistant**: "I've analyzed your auth service and found several improvement opportunities. Before we start, I need to understand your priorities:

1. Are you experiencing specific performance issues, or is this preventive optimization?
2. What's your timeline - is this urgent or can we take a methodical approach?
3. Are there any parts of the auth flow that are especially critical not to break?

Based on your answers, I'll create a tailored improvement plan."

```bash
/improve legacy-dashboard.js  
```

**Assistant**: "This dashboard has significant complexity (cyclomatic complexity: 23). I can see several refactoring approaches:

- **Conservative**: Extract utility functions, improve readability (2-3 hours)
- **Moderate**: Break into components, add proper state management (1-2 days)  
- **Comprehensive**: Full rewrite with modern patterns (1 week)

What's driving this improvement? Performance complaints, maintenance difficulty, or preparing for new features?"

## Collaborative Decision Making

The tool engages in natural conversation to:

- **Understand Context**: Why is improvement needed now?
- **Assess Constraints**: Time, resources, risk tolerance
- **Explore Options**: Multiple approaches with trade-offs
- **Build Consensus**: Ensure alignment on approach and priorities
- **Plan Execution**: Step-by-step roadmap with validation points

## Safety Through Conversation

- **Explicit Consent**: Every significant change requires confirmation
- **Impact Explanation**: Clear communication of what will change and why
- **Incremental Progress**: Small steps with frequent check-ins
- **Continuous Validation**: Regular testing and feedback loops
- **Adaptive Planning**: Adjusts approach based on results and feedback

The improve command transforms code through intelligent conversation, ensuring improvements align with your specific needs, constraints, and goals.
