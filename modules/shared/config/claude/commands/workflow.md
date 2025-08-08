---
name: workflow
description: "Generate structured implementation workflows from PRDs and feature requirements with expert guidance, multi-persona coordination, and advanced orchestration"
allowed-tools: [Read, Write, Edit, MultiEdit, Bash, Grep, Glob, TodoWrite, Task, WebSearch, sequentialthinking]

# Command Classification
category: orchestration
complexity: advanced
scope: cross-session

# Integration Configuration
mcp-integration:
  servers: [sequential, context7, magic, playwright, morphllm, serena]
  personas: [architect, analyzer, frontend, backend, security, devops, project-manager]
  wave-enabled: true
  complexity-threshold: 0.6

# Performance Profile
performance-profile: complex
personas: [architect, analyzer, project-manager]
---

# /sc:workflow - Implementation Workflow Generator

## Purpose
Analyze Product Requirements Documents (PRDs) and feature specifications to generate comprehensive, step-by-step implementation workflows with expert guidance, multi-persona coordination, dependency mapping, and automated task orchestration.

## Usage
```
/sc:workflow [prd-file|feature-description] [--strategy systematic|agile|enterprise] [--depth shallow|normal|deep] [--parallel] [--validate] [--mcp-routing]
```

## Arguments
- `prd-file|feature-description` - Path to PRD file or direct feature description for workflow analysis
- `--strategy` - Workflow strategy selection (systematic, agile, enterprise)
- `--depth` - Analysis depth and thoroughness level for workflow generation
- `--parallel` - Enable parallel workflow processing with multi-agent coordination
- `--validate` - Comprehensive validation and workflow completeness quality gates
- `--mcp-routing` - Intelligent MCP server routing for specialized workflow analysis
- `--wave-mode` - Enable wave-based execution with progressive workflow enhancement
- `--cross-session` - Enable cross-session persistence and workflow continuity
- `--persona` - Force specific expert persona (architect, frontend, backend, security, devops, etc.)
- `--output` - Output format (roadmap, tasks, detailed)
- `--estimate` - Include time and complexity estimates
- `--dependencies` - Map external dependencies and integrations
- `--risks` - Include risk assessment and mitigation strategies
- `--milestones` - Create milestone-based project phases

## Execution Strategies

### Systematic Strategy (Default)
1. Comprehensive Analysis - Deep PRD analysis with architectural assessment
2. Strategic Planning - Multi-phase planning with dependency mapping
3. Coordinated Execution - Sequential workflow execution with validation gates
4. Quality Assurance - Comprehensive testing and validation cycles
5. Documentation - Comprehensive workflow documentation

### Agile Strategy
1. Rapid Assessment - Quick scope definition and priority identification
2. Iterative Planning - Sprint-based organization with adaptive planning
3. Continuous Delivery - Incremental execution with frequent feedback
4. Adaptive Validation - Dynamic testing and validation approaches
5. Retrospective Optimization - Continuous improvement and learning

### Enterprise Strategy
1. Stakeholder Analysis - Multi-domain impact assessment and coordination
2. Governance Planning - Compliance and policy integration planning
3. Resource Orchestration - Enterprise-scale resource allocation
4. Risk Management - Comprehensive risk assessment and mitigation
5. Compliance Validation - Regulatory and policy compliance verification

### MVP Strategy
1. Core Feature Identification - Strip down to essential functionality
2. Rapid Prototyping - Focus on quick validation and feedback
3. Technical Debt Planning - Identify shortcuts and future improvements
4. Validation Metrics - Define success criteria and measurement
5. Scaling Roadmap - Plan for post-MVP feature expansion

## Expert Persona Auto-Activation

### Frontend Workflow (`--persona frontend`)
- UI/UX Analysis - Design system integration and component planning
- State Management - Data flow and state architecture
- Performance Optimization - Bundle optimization and lazy loading
- Accessibility Compliance - WCAG guidelines and inclusive design

### Backend Workflow (`--persona backend`)
- API Design - RESTful/GraphQL endpoint planning
- Database Schema - Data modeling and migration strategy
- Security Implementation - Authentication, authorization, and data protection
- Performance Scaling - Caching, optimization, and load handling

### Architecture Workflow (`--persona architect`)
- System Design - High-level architecture and service boundaries
- Technology Stack - Framework and tool selection rationale
- Scalability Planning - Growth considerations and bottleneck prevention
- Integration Patterns - Service communication and data flow

### Security Workflow (`--persona security`)
- Threat Modeling - Security risk assessment and attack vectors
- Data Protection - Encryption, privacy, and compliance requirements
- Authentication Strategy - User identity and access management
- Compliance Validation - Regulatory requirements (GDPR, HIPAA, etc.)

### DevOps Workflow (`--persona devops`)
- Infrastructure Planning - Cloud architecture and resource allocation
- CI/CD Pipeline - Automated testing, building, and deployment
- Environment Management - Development, staging, and production environments
- Monitoring Strategy - Application and infrastructure monitoring

## Output Formats

### Roadmap Format (`--output roadmap`)
```
# Feature Implementation Roadmap
## Phase 1: Foundation (Week 1-2)
- [ ] Architecture design and technology selection
- [ ] Database schema design and setup
- [ ] Basic project structure and CI/CD pipeline

## Phase 2: Core Implementation (Week 3-6)
- [ ] API development and authentication
- [ ] Frontend components and user interface
- [ ] Integration testing and security validation
```

### Tasks Format (`--output tasks`)
```
# Implementation Tasks
## Epic: User Authentication System
### Story: User Registration
- [ ] Design registration form UI components
- [ ] Implement backend registration API
- [ ] Add email verification workflow
- [ ] Create user onboarding flow
```

### Detailed Format (`--output detailed`)
```
# Detailed Implementation Workflow
## Task: Implement User Registration API
**Persona**: Backend Developer
**Estimated Time**: 8 hours
**Dependencies**: Database schema, authentication service

### Implementation Steps:
1. Setup API endpoint (1 hour)
2. Database integration (2 hours)
3. Security measures (3 hours)
4. Testing (2 hours)

### Acceptance Criteria:
- [ ] User can register with email and password
- [ ] Passwords are properly hashed
- [ ] Rate limiting prevents abuse
```

## MCP Integration Flags
- `--c7` / `--context7` - Enable Context7 for framework patterns
- `--sequential` - Enable Sequential thinking for complex analysis
- `--magic` - Enable Magic for UI component workflow planning
- `--all-mcp` - Enable all MCP servers for comprehensive workflow generation

## Advanced Features

### Dependency Analysis
- Internal Dependencies - Component and feature coupling
- External Dependencies - Third-party services and APIs
- Technical Dependencies - Framework versions, database requirements
- Infrastructure Dependencies - Cloud services, deployment requirements

### Risk Assessment & Mitigation
- Technical Risks - Complexity, performance, scalability concerns
- Timeline Risks - Dependency bottlenecks and resource constraints
- Security Risks - Data protection and compliance vulnerabilities
- Mitigation Strategies - Fallback plans and alternative approaches

## Examples

### Generate from PRD File
```
/sc:workflow docs/feature-100-prd.md --strategy systematic --c7 --sequential --estimate
```

### Frontend-Focused Workflow
```
/sc:workflow "User dashboard with real-time analytics" --persona frontend --magic --output detailed
```

### MVP Planning with Risks
```
/sc:workflow user-authentication-system --strategy mvp --risks --parallel --milestones
```

### Full-Stack Feature
```
/sc:workflow social-media-integration --all-mcp --sequential --parallel --estimate --output roadmap
```

## Integration with Other Commands
- **Brainstorm Integration**: Takes PRDs generated by `/sc:brainstorm`
- **TodoWrite Integration**: Creates session tasks for immediate next steps
- **Task Integration**: Converts workflow into hierarchical project tasks
- **Implementation Integration**: Connects to `/sc:implement` for feature development

## Quality Gates
- Requirements Coverage - All PRD requirements addressed
- Technical Feasibility - Implementation complexity assessment
- Security Standards - Security considerations at each phase
- Performance Requirements - Performance targets and monitoring

## Boundaries

**This command will:**
- Generate structured implementation workflows from PRDs
- Coordinate multiple MCP servers and personas for optimal outcomes
- Map dependencies and risks with automated task orchestration
- Maintain cross-session persistence for workflow continuity

**This command will not:**
- Execute without proper analysis and planning phases
- Proceed without stakeholder alignment and clear success criteria
- Compromise quality standards for speed or convenience
