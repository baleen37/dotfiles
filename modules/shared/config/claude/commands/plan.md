<objective>
Draft a detailed, step-by-step blueprint for building this project using specialized agents to optimize the planning and implementation process. Break down the project into small, iterative chunks that build on each other, leveraging different agent capabilities for each phase.
</objective>

<process>
1. **Planning Phase with Context Manager Agent**
   - Use the context-manager agent to coordinate the overall project planning across multiple sessions
   - Maintain context and requirements across the entire planning process
   - Ensure architectural consistency throughout the project lifecycle

2. **Analysis & Research Phase with General-Purpose Agent**
   - Deploy general-purpose agent to research existing codebase patterns and conventions
   - Analyze project dependencies, architecture, and integration points
   - Gather technical requirements and constraints

3. **Implementation Planning with Test-Automator Agent**
   - Use test-automator agent to proactively design the testing strategy
   - Plan unit, integration, and e2e test coverage for each implementation step
   - Establish CI/CD pipeline requirements and test automation setup

4. **Quality Assurance with Code-Reviewer Agent**
   - Engage code-reviewer agent after each implementation step
   - Ensure code quality, security, and maintainability standards
   - Review architectural decisions and suggest improvements

5. **Step-by-Step Implementation**
   - Break down into small, safe implementation chunks
   - Each step should build incrementally on previous work
   - Ensure no orphaned code or hanging integrations
   - Use appropriate agents for each specific task type
</process>

<deliverables>
Store the comprehensive plan in plan.md using the following structure:
- Executive summary with agent coordination strategy
- Detailed implementation phases with assigned agents
- Testing strategy (developed with test-automator agent)
- Quality gates and review checkpoints (code-reviewer agent)
- Context preservation strategy (context-manager agent)

Create todo.md to track state and agent task assignments.
</deliverables>

<agent-coordination>
**Primary Agent Assignment Strategy:**
- **Context Manager**: Overall project coordination and long-term context preservation
- **General-Purpose**: Research, analysis, and complex multi-step implementation tasks
- **Test-Automator**: Proactive test planning and CI/CD setup
- **Code-Reviewer**: Quality assurance and architectural review after each major step

**Agent Handoff Protocol:**
- Document findings and decisions for smooth agent transitions
- Maintain shared context through the context-manager agent
- Ensure each agent has access to relevant previous work and decisions
</agent-coordination>

<context>
The spec is in the file called:
</context>
