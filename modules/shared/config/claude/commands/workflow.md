# /workflow - Development Workflow & Project Planning

Analyze PRDs and feature specifications to generate systematic implementation workflows with expert guidance and task orchestration.

## Purpose
- **PRD-Based Analysis**: Automatically analyze requirement documents and establish comprehensive implementation plans
- **Strategy-Driven Workflows**: Generate customized workflows based on systematic, agile, or MVP development strategies
- **Wave System Integration**: Auto-activate Wave mode for complex multi-domain project coordination
- **Hierarchical Task Management**: Structure work using Epic → Story → Task hierarchy with dependency mapping
- **Expert Persona Integration**: Auto-activate domain specialists based on project requirements and complexity

## Usage
```bash
/workflow [target] [--strategy approach] [--output format] [--persona expert] [--estimate]
```

## Arguments & Flags
- `prd-file|feature-description` - PRD file path or feature description
- `--strategy` - Workflow strategy (systematic: methodical, agile: iterative, mvp: minimal viable)
- `--output` - Output format (roadmap: timeline, tasks: task list, detailed: comprehensive plan)
- `--estimate` - Include time and complexity estimates
- `--dependencies` - Dependency analysis and mapping
- `--risks` - Risk assessment and mitigation strategies
- `--parallel` - Identify parallelizable work areas
- `--milestones` - Milestone-based project phases
- `--persona` - Force specific expert persona (architect, frontend, backend, security, devops)

## Auto-Activation Patterns
- **Wave Mode**: Complexity ≥0.7, files >20, domains >2
- **MCP Servers**: Context7 (patterns), Sequential (analysis), Magic (UI-related)
- **Persona Auto-Activation**: Based on PRD content and feature requirements

### Expert Persona Auto-Detection
- **Frontend Persona**: UI/UX requirements, component specs, responsive design
- **Backend Persona**: API design, database schema, server architecture
- **Security Persona**: Authentication, authorization, compliance requirements
- **DevOps Persona**: Infrastructure, deployment, monitoring requirements
- **Architect Persona**: System design, technology stack, scalability planning

## Workflow Strategies

### Systematic Strategy (Default)
Methodical and phased implementation approach
1. **Requirements Analysis** - Deep analysis of PRD structure and acceptance criteria
2. **Architecture Planning** - System design and component architecture
3. **Dependency Mapping** - Identify internal and external dependencies  
4. **Implementation Phases** - Sequential phases with clear deliverables
5. **Testing Strategy** - Comprehensive testing approach at each phase
6. **Deployment Planning** - Production rollout and monitoring strategy

### Agile Strategy
Iterative and incremental development approach
1. **Epic Breakdown** - Convert PRD into user stories and epics
2. **Sprint Planning** - Organize work into iterative sprints
3. **MVP Definition** - Identify minimum viable product scope
4. **Iterative Development** - Plan for continuous delivery and feedback
5. **Stakeholder Engagement** - Regular review and adjustment cycles
6. **Retrospective Planning** - Built-in improvement and learning cycles

### MVP Strategy
Core feature-first rapid validation approach
1. **Core Feature Identification** - Strip down to essential functionality
2. **Rapid Prototyping** - Focus on quick validation and feedback
3. **Technical Debt Planning** - Identify shortcuts and future improvements
4. **Validation Metrics** - Define success criteria and measurement
5. **Scaling Roadmap** - Plan for post-MVP feature expansion
6. **User Feedback Integration** - Structured approach to user input

## Output Formats

### Roadmap Format (`--output roadmap`)
```markdown
# Feature Implementation Roadmap
## Phase 1: Foundation (Week 1-2)
- [ ] Architecture design and technology stack selection
- [ ] Database schema design and setup
- [ ] Basic project structure and CI/CD pipeline

## Phase 2: Core Implementation (Week 3-6)
- [ ] API development and authentication system
- [ ] Frontend components and user interface
- [ ] Integration testing and security validation
```

### Tasks Format (`--output tasks`)
```markdown
# Implementation Tasks
## Epic: User Authentication System
### Story: User Registration
- [ ] Design registration form UI components
- [ ] Implement backend registration API
- [ ] Add email verification workflow
- [ ] Create user onboarding flow
```

### Detailed Format (`--output detailed`)
```markdown
# Detailed Implementation Workflow
## Task: Implement User Registration API
**Estimated Time**: 8 hours
**Dependencies**: Database schema, authentication service
**MCP Context**: Express.js patterns, security best practices

### Implementation Steps:
1. **Setup API endpoint** (1 hour)
2. **Database integration** (2 hours)
3. **Security measures** (3 hours)
4. **Testing** (2 hours)
```

## Tool Integration & Advanced Features

### Allowed Tools & Execution Pattern
- **Read**: Analyze PRD files and project documentation
- **Write**: Generate workflow documentation and task specifications
- **Edit**: Update existing workflow plans and task hierarchies
- **Glob**: Discover project structure and related documentation
- **Grep**: Search for patterns and requirements in documentation
- **TodoWrite**: Track workflow generation progress and immediate tasks
- **Task**: Create hierarchical project tasks for complex workflows

### Integration with Command Ecosystem

#### TodoWrite Integration
- Automatically create session tasks for immediate next steps
- Track progress throughout workflow execution
- Link workflow phases to actionable development tasks

#### Task Command Integration
- Convert workflows into hierarchical project tasks (`/task`)
- Enable cross-session persistence and progress tracking
- Support complex orchestration through `/spawn`

#### Wave System Integration
- Auto-activate Wave mode when complexity ≥0.7
- Split multi-phase workflows into Wave execution
- Validation and quality gates at each Wave phase

### MCP Server Coordination
- **Sequential**: Complex multi-step analysis and systematic workflow planning
- **Context7**: Framework patterns, best practices, and implementation guidance
- **Magic**: UI component workflow planning and design system integration

### Advanced Workflow Features
- **Dependency Analysis**: Identify and map all internal and external dependencies
- **Risk Assessment**: Comprehensive risk analysis with mitigation strategies
- **Parallel Work Streams**: Identify parallelizable work areas for team coordination
- **Milestone Planning**: Create milestone-based project phases with clear deliverables
- **Expert Guidance**: Auto-activate domain-specific personas based on requirements

## Quality Gates & Performance
- **Workflow Completeness**: Ensure all PRD requirements are addressed
- **Technical Feasibility**: Assess implementation complexity and risks
- **Best Practices Validation**: Ensure adherence to established patterns
- **Performance Target**: Generate workflows within 30 seconds for standard PRDs
