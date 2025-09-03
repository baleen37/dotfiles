---
name: workflow_v2
description: "Generate structured implementation workflows from requirements and specifications"
---

Generate comprehensive, structured workflows from product requirements and feature specifications for systematic implementation.

**Usage**: `/workflow_v2 [prd-file|feature-description]`

## Auto-Planning

- **Strategy Detection**: Automatically chooses systematic or agile approach based on project complexity
- **Smart Depth**: Adjusts workflow detail level based on feature scope
- **Parallel Optimization**: Identifies tasks that can run in parallel automatically

## Workflow Generation Process

1. **Requirements Analysis**: Parse and understand specifications, constraints, and success criteria
2. **Task Decomposition**: Break down features into actionable, granular tasks
3. **Dependency Mapping**: Identify task relationships and execution order
4. **Resource Planning**: Determine required skills, tools, and time estimates
5. **Validation Planning**: Define checkpoints and quality gates
6. **Workflow Assembly**: Create structured, executable implementation plan

## Strategy Details

### Systematic Workflow
```
Phase 1: Requirements & Architecture
├── Requirement validation
├── Technical architecture design
├── Database schema planning
└── API specification

Phase 2: Core Implementation
├── Backend services
├── Database setup
├── API endpoints
└── Core business logic

Phase 3: Frontend & Integration
├── UI component development
├── Frontend-backend integration
├── User experience implementation
└── End-to-end testing

Phase 4: Quality & Deployment
├── Security review
├── Performance testing
├── Production deployment
└── Monitoring setup
```

### Agile Workflow
```
Sprint 1: MVP Core (2-3 weeks)
├── Basic authentication (parallel)
├── Core data models (parallel)
├── Essential API endpoints
└── Basic UI framework

Sprint 2: Feature Development (2-3 weeks)
├── Advanced features
├── UI/UX improvements
├── Integration testing
└── Performance optimization

Sprint 3: Polish & Deploy (1-2 weeks)
├── Bug fixes and refinements
├── Security hardening
├── Production deployment
└── Post-launch monitoring
```

## Key Features

- **Dependency-Aware**: Identifies and manages task dependencies
- **Resource-Conscious**: Considers available skills and tools
- **Quality-Focused**: Includes validation and testing at appropriate stages
- **Flexible**: Adapts to different project sizes and constraints
- **Executable**: Generates actionable tasks, not just high-level phases

## Deliverables

- Structured workflow with task breakdown
- Dependency map and execution order
- Resource requirements and time estimates
- Quality checkpoints and success criteria
- Risk assessment and mitigation strategies

## Example Usage

```
/workflow_v2 "E-commerce checkout system"
```

This will automatically determine the optimal workflow strategy (likely agile for this complex feature), identify parallel execution opportunities, and provide detailed task breakdown.

## Workflow Boundaries

- **Will Generate**: Structured implementation plans, task breakdowns, dependency maps
- **Will Not Execute**: Actual implementation tasks (use `/implement_v2` for execution)
- **Focuses On**: Planning and organization, not code generation
