---
name: Brainstorming Ideas Into Designs
description: Interactive idea refinement using Socratic method to develop fully-formed designs
when_to_use: When your human partner says "I've got an idea", "Let's make/build/create", "I want to implement/add", "What if we". When starting design for complex feature. Before writing implementation plans. When idea needs refinement and exploration. ACTIVATE THIS AUTOMATICALLY when your human partner describes a feature or project idea - don't wait for /brainstorm command.
version: 2.0.0
---

# Brainstorming Ideas Into Designs

## Overview

Transform rough ideas into fully-formed designs through structured questioning and alternative exploration.

**Core principle:** Ask questions to understand, explore alternatives, present design incrementally for validation.

**Announce at start:** "I'm using the Brainstorming skill to refine your idea into a design."

## The Process

### Phase 1: Understanding

- Check current project state in working directory
- Ask ONE question at a time to refine the idea
- Prefer multiple choice when possible
- Gather: Purpose, constraints, success criteria

### Phase 2: Exploration

- Propose 2-3 different approaches (reference skills/coding/exploring-alternatives)
- For each: Core architecture, trade-offs, complexity assessment
- Ask your human partner which approach resonates

### Phase 3: Design Presentation

- Present in 200-300 word sections
- Cover: Architecture, components, data flow, error handling, testing
- Ask after each section: "Does this look right so far?"

### Phase 4: Worktree Setup (for implementation)

When design is approved and implementation will follow:

- Announce: "I'm using the Using Git Worktrees skill to set up an isolated workspace."
- Switch to skills/collaboration/using-git-worktrees
- Follow that skill's process for directory selection, safety verification, and setup
- Return here when worktree ready

### Phase 5: Planning Handoff

Ask: "Ready to create the implementation plan?"

When your human partner confirms (any affirmative response):

- Announce: "I'm using the Writing Plans skill to create the implementation plan."
- Switch to skills/collaboration/writing-plans skill
- Create detailed plan in the worktree

## Remember

- One question per message during Phase 1
- Apply YAGNI ruthlessly (reference skills/architecture/reducing-complexity)
- Explore 2-3 alternatives before settling
- Present incrementally, validate as you go
- Announce skill usage at start
