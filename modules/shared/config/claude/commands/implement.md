---
name: implement
description: "Feature and code implementation with intelligent agent routing and framework expertise"
agents: [frontend-developer, backend-engineer, system-architect]
---

# /implement - Feature Implementation

**Purpose**: Implement features, components, and code functionality with automatic expert activation and framework best practices

## Usage

```bash
/implement <description>         # Design-first feature implementation
/implement api <description>     # -> backend-engineer agent
/implement component <description> # -> frontend-developer agent
/implement rapid <description>   # Skip design phase, direct implementation
/implement design <description>  # Stop at design phase for review
```

## Execution Strategy

### **Design-First Approach** (Default)
1. **Requirements Analysis**: Clarify functional and non-functional requirements
2. **Design Phase**: Create architectural plan, interface definitions, and data models
3. **Pattern Alignment**: Ensure consistency with existing codebase patterns
4. **Implementation**: Code generation based on validated design
5. **Validation**: Testing strategy and quality assurance integration

### **Implementation Modes**

- **Design-First**: Complete design → validation → implementation cycle
- **Framework-Specific**: Apply technology-specific best practices via Context7
- **Multi-file**: Coordinate complex implementations across multiple files
- **Rapid**: Skip design for simple, well-understood features
- **Design**: Generate design specifications for review before implementation

## MCP Integration

- **Context7**: Framework documentation and best practices (React, Vue, Node.js, etc.)
- **Sequential**: Complex feature breakdown and systematic implementation
- **Playwright**: End-to-end testing and validation of implemented features

## Examples

```bash
# Design-First Implementation (Default)
/implement user authentication    # Design → validate → implement auth system
/implement api user management   # Backend API with design phase
/implement component UserProfile # Frontend component with design review

# Alternative Modes
/implement rapid "add dark mode toggle"      # Quick implementation for simple features
/implement design "real-time chat"          # Generate design spec for complex feature

# Complex Feature Examples
/implement "e-commerce shopping cart with persistent state"
# → 1. Requirements analysis: cart operations, persistence, state management
# → 2. Design: data structures, API endpoints, component hierarchy
# → 3. Pattern alignment: existing state management, API conventions
# → 4. Implementation: coordinated frontend/backend development
# → 5. Validation: testing strategy, performance considerations

/implement design api "GraphQL subscription for live notifications"
# → Focus on schema design, resolver architecture, subscription management
# → Output: detailed technical specification ready for implementation
```

## Agent Routing

- **frontend-developer**: UI components, client-side logic, React/Vue patterns
- **backend-engineer**: APIs, services, database integration, Node.js/Python
- **system-architect**: Complex features requiring architectural decisions and design-first approach
- **typescript-pro**: Advanced TypeScript implementations with complex type systems
- **python-ultimate-expert**: Python-specific implementations with advanced patterns
