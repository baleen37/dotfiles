---
name: save
description: "Save current work context, session state, and learnings for cross-session continuity"
mcp: [Serena]
---

# /save - Comprehensive Session Preservation

Save current work context, TodoWrite state, and accumulated learnings with intelligent context preservation and cross-session memory management.

## Usage

```bash
/save                    # Smart auto-save (session + context)
/save <name>             # Named save with specific identifier  
/save session            # TodoWrite state only
/save context            # Project context and discoveries
/save learnings          # Accumulated insights and patterns
```

## Storage Location & Contents

**Storage Path**: `./session_{slug}_{yyyymmddHHMM}.md`

**Smart Context Preservation**:
- Complete TodoWrite state with execution history and task completion timeline
- Project context and architectural decisions with reasoning
- Code patterns and implementation insights discovered during work
- Problem-solution mappings and learnings from debugging sessions
- Planning decisions and alternative approaches considered
- Technical discoveries and insights gained during implementation
- Performance observations and optimization notes
- Error patterns and resolution strategies
- Cross-session knowledge accumulation via Serena MCP
- Dependency relationships and technical constraints
- Tool usage patterns and effectiveness observations

## Core Features

**Intelligent Preservation**:
- Automatic context classification and prioritization
- Cross-session learning accumulation via Serena MCP
- Smart deduplication of similar contexts
- Progressive knowledge building over multiple sessions

**Session Management**:
- TodoWrite state with complete execution history and task timeline
- Technical decisions and reasoning preservation with context
- Task planning evolution and decision branching points
- Implementation strategy changes and pivots documented
- Tool selection rationale and effectiveness evaluation
- Problem analysis methodology and solution approach
- Auto-naming based on current work context and primary objectives
- Incremental saves without data loss
- Work session continuity markers for seamless resume

## Content Examples

**Planning Context**:
- Initial task analysis and approach selection
- Alternative strategies considered and reasons for choices
- Risk assessment and mitigation strategies
- Resource requirements and constraints identified

**Technical Discovery Documentation**:
- Performance bottlenecks discovered and solutions applied
- Error patterns encountered and resolution methods
- Tool effectiveness evaluation and recommendations
- Integration challenges and workaround strategies

**Implementation Journey**:
- Code design decisions and architectural choices
- Testing strategy evolution and coverage decisions
- Refactoring decisions and quality improvements
- Debugging methodology and problem-solving patterns

## Safety Features

- **Overwrite Protection**: Confirmation prompt when plan name exists
- **File Validation**: Pre-save plan file integrity checks
- **Context Completeness**: Verification that all active work is captured
- **Recovery Markers**: Checkpoint creation for session resumption

## Integration

- Seamless `/load` compatibility for session recovery  
- Local storage in current working directory (`./`)
- Human-readable Markdown with intelligent naming
- Full TodoWrite ecosystem compatibility
- Progressive context building across multiple sessions
