---
name: brainstorm
description: "Transform ideas into detailed specifications through systematic questioning and structured exploration"
tools: [Write]
mcp: [Sequential]
---

# /brainstorm - Iterative Specification Development

**Purpose**: Transform vague ideas into comprehensive, actionable specifications through intelligent, systematic questioning. Uses structured exploration to uncover all requirement dimensions and create developer-ready documentation.

## How It Works

**Systematic Exploration Process**:
1. Initial idea analysis and domain classification
2. Sequential MCP-guided questioning for comprehensive discovery
3. Multi-dimensional exploration (technical, user, business perspectives)
4. Iterative refinement through structured dialogue
5. Specification synthesis and validation
6. Final deliverable creation (`spec.md`)
7. Optional GitHub repository setup

**Intelligence Features**:
- Context-aware question generation based on domain and complexity
- Automatic identification of missing requirements areas
- Progressive deepening from high-level concepts to implementation details
- Cross-domain validation (technical feasibility vs user needs)

## Question Flow Example

```bash
/brainstorm "team collaboration app"
```

```
Q1: What's the main problem this app solves for teams?
A1: Teams struggle to track who's working on what

Q2: What size teams are you targeting?
A2: Small teams, 5-15 people

Q3: Do they need real-time updates or is periodic sync enough?
A3: Real-time is important for coordination

Q4: What platforms do they need - web, mobile, desktop?
A4: Web-first, mobile nice to have
```

## Final Output

After our conversation, I will:

1. **Summarize** everything we've discussed
2. **Create `spec.md`** with:
   - Project overview and objectives
   - User requirements and workflows
   - Technical requirements
   - Success criteria
3. **Ask if you want** a GitHub repository created

## Next Step

The `spec.md` becomes input for `/workflow` to create implementation blueprint.

```bash
/brainstorm "idea" → spec.md → /workflow → implementation plan
```

## MCP Integration

- **Sequential**: Structured questioning flow and requirement discovery process
- **Context7**: Domain-specific best practices and requirement templates
