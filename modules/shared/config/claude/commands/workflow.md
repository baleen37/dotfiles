---
name: workflow
description: "Generate implementation workflows from PRDs with task decomposition, dependency mapping, and strategic execution planning"
---

# /workflow - PRD-Based Workflow Generation

**Purpose**: Transform Product Requirements Documents and feature descriptions into structured implementation workflows with dependency mapping and strategic execution planning.

## Usage

```bash
/workflow [prd-file]                       # Generate from PRD document
/workflow "feature-description"            # Generate from feature text
/workflow systematic [project]             # Detailed comprehensive approach
/workflow agile [feature]                  # Flexible parallel approach
/workflow enterprise [system]              # Validation-focused approach
```

## Strategic Workflow Generation

**Systematic Strategy:**
- Deep analysis of feature specifications
- Comprehensive dependency mapping
- Detailed risk assessment and mitigation
- Ideal for: Complex features, architectural changes

**Agile Strategy:**
- Parallel task coordination
- Flexible milestone planning
- Rapid iteration cycles
- Ideal for: Feature development, MVP creation

**Enterprise Strategy:**
- Comprehensive validation focus
- Compliance requirement integration
- Risk management emphasis
- Ideal for: Enterprise systems, regulated environments

## Core Workflow Features

**PRD Analysis:**
- Requirements decomposition into implementable tasks
- Cross-domain coordination planning
- Technical specification extraction
- Feasibility validation

**Task Decomposition:**
- Task breakdown → dependency mapping → structured implementation planning
- Progressive enhancement support
- Cross-session workflow management
- Implementation priority optimization

**Structured Output:**
- Clear step-by-step execution plan
- Completion criteria and validation methods for each phase
- Parallel execution opportunities identification
- Time estimation and complexity assessment

## Multi-Domain Coordination

**Cross-Domain Planning:**
- Architecture, frontend, backend, security, DevOps integration
- Intelligent routing and requirement analysis
- Progressive workflow enhancement
- Cross-session context preservation

## MCP Integration

- **Sequential**: Multi-step workflow planning and systematic evaluation
- **Context7**: Framework-specific best practices and implementation patterns
- **Serena**: Project context analysis and historical decision tracking

## Example Output

```
## Implementation Workflow: User Authentication System

### Phase 1: Foundation Setup
**Dependencies**: None | **Duration**: 2-3 hours
- [ ] Install auth dependencies (bcrypt, JWT, session store)
- [ ] Database schema design and migration
- [ ] Environment configuration setup

### Phase 2: Core Implementation  
**Dependencies**: Phase 1 complete | **Duration**: 1-2 days
- [ ] User registration endpoint with validation
- [ ] Login/logout functionality with session management
- [ ] Password hashing and verification
- [ ] JWT token generation and validation

### Phase 3: Security & Integration
**Dependencies**: Phase 2 complete | **Duration**: 4-6 hours
- [ ] Auth middleware implementation
- [ ] Route protection setup
- [ ] Security headers and CSRF protection
- [ ] Rate limiting for auth endpoints

### Phase 4: Testing & Validation
**Dependencies**: Phase 3 complete | **Duration**: 3-4 hours
- [ ] Unit tests for auth functions
- [ ] Integration tests for auth flows
- [ ] Security testing and validation
- [ ] Performance testing under load

**Risk Factors**:
- Session store configuration complexity
- JWT secret management
- Rate limiting calibration

**Success Criteria**:
- All auth flows working end-to-end
- Security tests passing
- Performance within acceptable limits
```

## Examples

```bash
/workflow auth-feature-prd.md systematic    # Comprehensive PRD analysis
/workflow "real-time chat feature" agile    # Flexible feature development
/workflow enterprise-dashboard.md           # Enterprise validation workflow
```

## Workflow Boundaries

**Generation Focus:**
- Will generate comprehensive workflow plans and strategies
- Will analyze PRDs and transform into actionable roadmaps
- Will coordinate multi-domain implementation planning

**Implementation Boundaries:**
- Will NOT execute actual implementation tasks
- Requires comprehensive requirement analysis before generation
- Focuses on planning rather than code execution

**Next Steps**: Generated workflows can be executed via `/implement` or `/task` commands
