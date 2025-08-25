---
name: brainstorm
description: "Transform vague ideas into concrete requirements through codebase analysis"
agents: [system-architect, frontend-developer, backend-engineer]
---

# /brainstorm - Smart Requirements Discovery

**Purpose**: Convert fuzzy ideas into actionable specifications using codebase intelligence

## Usage

```bash
/brainstorm <idea>           # Smart discovery with codebase analysis
/brainstorm deep <idea>      # Extended strategic questioning
/brainstorm rapid <idea>     # Quick ideation mode
/brainstorm validate <idea>  # Feasibility-focused analysis
```

## Execution Strategy

- **Smart**: Codebase scan → intelligent questions → structured output
- **Deep**: Extended strategic analysis with multi-perspective evaluation
- **Rapid**: Quick validation and immediate actionability focus
- **Validate**: Feasibility assessment with risk analysis

## Enhanced 3-Phase Process

### Phase 1: Codebase Intelligence

- Scan project files for tech stack, patterns, and architecture
- Detect existing tools, frameworks, and conventions
- Identify integration points and constraints
- Present findings: "Based on your codebase using [X, Y, Z], I see [patterns]"

### Phase 2: Strategic Discovery

Generate intelligent questions and structured analysis based on complexity:

**Simple Ideas**: Direct conversion with validation:
- User stories with acceptance criteria
- Priority matrix (P0/P1/P2) with impact/effort scoring
- Technical feasibility check against current stack
- Immediate next steps with time estimates

**Complex Ideas**: Extended strategic questioning:
- **Context**: Platform choice, target audience, scale requirements
- **Constraints**: Technical limitations, resource availability, timeline
- **Trade-offs**: Speed vs. Stability vs. Features vs. Security
- **Integration**: How does this fit with existing systems?
- **Evolution**: Future extensibility and maintenance considerations

**Innovation Ideas**: Creative exploration:
- **Vision**: Long-term potential and transformative impact
- **Experimentation**: MVP definition and validation approach
- **Risk Assessment**: Technical, business, and operational risks
- **Alternative Approaches**: Multiple solution pathways

### Phase 3: Validation & Action Planning

Convert discoveries into executable roadmap:

**Feasibility Analysis**:
- Technical viability within current architecture
- Resource requirements (time, skills, infrastructure)
- Dependencies and potential blockers
- Risk mitigation strategies

**Implementation Strategy**:
- Phased delivery approach (MVP → iterations)
- Success metrics and validation checkpoints
- Resource allocation and timeline estimates
- Integration points and testing strategy

**Strategic Alignment**:
- Business value proposition and ROI estimation
- Stakeholder impact analysis
- Change management requirements
- Long-term maintenance considerations

## MCP Integration

- **Sequential**: Systematic thinking through requirement analysis
- **Context7**: Tech stack validation and framework best practices

## Examples

```bash
# Standard Mode
/brainstorm "team task tracker"     # Full 3-phase discovery with codebase scan
/brainstorm "user auth system"      # Authentication system planning  
/brainstorm "mobile app idea"       # Mobile application brainstorming

# Enhanced Modes
/brainstorm deep "AI-powered code review"       # Extended strategic analysis
/brainstorm rapid "quick feature toggle"       # Fast validation and planning
/brainstorm validate "microservices migration" # Feasibility-focused assessment

# Complex System Ideas
/brainstorm deep "real-time collaboration platform"
# → Multi-phase analysis covering technical architecture, scalability,
#   user experience, security, and business model considerations

/brainstorm validate "automated deployment pipeline"
# → Focus on technical feasibility, integration points, risk assessment,
#   and implementation timeline within current infrastructure
```

## Agent Routing

- **system-architect**: Complex systems requiring architectural decisions
- **frontend-developer**: UI/UX focused ideas and component planning
- **backend-engineer**: API design, data modeling, service architecture

## Workflow

1. **Codebase Scan**: Analyze existing code → present tech stack findings
2. **Smart Discovery**: Generate appropriate output based on idea complexity
