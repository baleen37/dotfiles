---
name: implement
description: "Feature and code implementation with intelligent agent routing and framework expertise"
agents: [frontend-specialist, backend-engineer, system-architect]
---

<command>
/implement - Feature Implementation

<purpose>
Implement features, components, and code functionality with automatic expert activation and framework best practices
</purpose>

<usage>
```bash
/implement <description>         # Basic feature implementation
/implement api <description>     # -> backend-engineer agent
/implement component <description> # -> frontend-specialist agent
```
</usage>

<execution-strategy>
- **Basic**: Implement features using existing patterns and conventions
- **Framework-Specific**: Apply technology-specific best practices via Context7
- **Multi-file**: Coordinate complex implementations across multiple files
- **Quality Assurance**: Include testing and validation recommendations
</execution-strategy>

<mcp-integration>
- **Context7**: Framework documentation and best practices (React, Vue, Node.js, etc.)
- **Sequential**: Complex feature breakdown and systematic implementation
- **Playwright**: End-to-end testing and validation of implemented features
</mcp-integration>

<examples>
```bash
/implement user authentication    # Basic auth implementation
/implement api user management   # Backend API with validation
/implement component UserProfile # Frontend component
```
</examples>

<agent-routing>
- **frontend-specialist**: UI components, client-side logic, React/Vue patterns
- **backend-engineer**: APIs, services, database integration, Node.js/Python
- **system-architect**: Complex features requiring architectural decisions
</agent-routing>
</command>
