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
- Complete TodoWrite state with execution history
- Project context and architectural decisions
- Code patterns and implementation insights
- Problem-solution mappings and learnings
- Cross-session knowledge accumulation
- Dependency relationships and technical constraints

## Core Features

**Intelligent Preservation**:
- Automatic context classification and prioritization
- Cross-session learning accumulation via Serena MCP
- Smart deduplication of similar contexts
- Progressive knowledge building over multiple sessions

**Session Management**:
- TodoWrite state with complete execution history
- Technical decisions and reasoning preservation
- Auto-naming based on current work context
- Incremental saves without data loss

## Safety Features

- **Overwrite Protection**: Confirmation prompt when plan name exists
- **File Validation**: Pre-save plan file integrity checks

## MCP Integration

- **Serena**: Cross-session memory management and learning accumulation
- Intelligent context indexing and retrieval
- Pattern recognition across save sessions
- Automatic knowledge graph building

## Integration

- Seamless `/restore` compatibility for session recovery  
- Local storage in current working directory (`./`)
- Human-readable Markdown with intelligent naming
- Full TodoWrite ecosystem compatibility
- Progressive context building across multiple sessions
