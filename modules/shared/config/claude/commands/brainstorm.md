---
name: brainstorm
description: "Transform ideas into detailed specifications through systematic questioning"
tools: [Write]
---

# /brainstorm - Iterative Specification Development

**Purpose**: Ask me one question at a time so we can develop a thorough, step-by-step spec for this idea. Each question builds on my previous answers, and our end goal is to have a detailed specification I can hand off to a developer.

## How It Works

1. You give me an idea
2. I ask **one question at a time**
3. Each question builds on your previous answers
4. We continue until we have a complete spec
5. I save the spec as `spec.md`
6. Optionally, I can create a GitHub repository

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

The `spec.md` becomes input for `/plan` to create implementation blueprint.

```bash
/brainstorm "idea" → spec.md → /plan → plan.md
```
