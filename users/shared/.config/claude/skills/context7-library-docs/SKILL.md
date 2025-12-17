---
name: context7-library-docs
description: Use when user asks about library documentation, API usage, framework features, or how to use specific libraries - retrieves up-to-date documentation using Context7 instead of relying on training data
---

# Context7 Library Documentation

## Overview

Use Context7 to fetch current library documentation instead of relying on potentially outdated training data. Always prefer fresh documentation over knowledge cutoff.

**Two approaches available:**
1. **MCP tools** - Primary method using Context7 MCP server
2. **CLI tools** - Alternative using standalone Node.js scripts

## When to Use

**Use Context7 when user asks about:**
- Library APIs or methods ("How do I use React hooks?")
- Framework features ("Next.js routing patterns")
- Library configuration ("MongoDB connection options")
- Code examples for specific libraries
- Conceptual guides or architecture

**Don't use for:**
- General programming concepts
- Language syntax
- Questions answerable without library-specific docs

## Approach 1: MCP Tools (Primary)

**Two-step workflow - REQUIRED sequence:**

1. **Resolve library ID first**
   ```
   mcp__context7__resolve-library-id
   libraryName: "react" (or user's library name)
   ```
   Returns Context7-compatible ID like `/facebook/react`

2. **Get documentation**
   ```
   mcp__context7__get-library-docs
   context7CompatibleLibraryID: "/facebook/react"
   topic: "hooks" (optional focus)
   mode: "code" or "info"
   ```

**EXCEPTION:** Skip step 1 only if user provides explicit ID format: `/org/project` or `/org/project/version`

## Approach 2: CLI Tools (Alternative)

**Use when:** MCP server unavailable or manual testing needed

**Requirements:**
- Set environment variable: `CONTEXT7_API_KEY`
- Node.js runtime available

**Location:** `~/.config/claude/skills/context7-library-docs/tools/`

### resolve.js - Find Library ID

```bash
# Search for library
./resolve.js <library-name>

# Example
./resolve.js react
# Returns: {"count": 1, "libraries": [{"id": "/facebook/react", ...}]}
```

**Output:** JSON with library matches, IDs, scores, and descriptions

### get-docs.js - Fetch Documentation

```bash
# Basic usage
./get-docs.js <library-id> [--mode=code|info] [--topic=<topic>] [--page=<N>]

# Examples
./get-docs.js /facebook/react --topic=hooks
./get-docs.js /vercel/next.js --mode=info --topic=routing
./get-docs.js /mongodb/docs/v7.0.0 --page=2
```

**Library ID format:** `/owner/repo` or `/owner/repo/version`

**Parameters:**
- `--mode=code` (default) - API references, code examples
- `--mode=info` - Conceptual guides, architecture
- `--topic=<topic>` - Focus on specific topic
- `--page=<N>` - Pagination (1-10)

### When to Use CLI Tools vs MCP

| Situation | Use |
|-----------|-----|
| Normal Claude Code workflow | **MCP tools** |
| MCP server not responding | CLI tools |
| Manual testing/debugging | CLI tools |
| Scripting/automation | CLI tools |
| Need structured JSON output | CLI tools |

## Choosing Mode

- `mode: "code"` (default) - API references, method signatures, code examples
- `mode: "info"` - Conceptual guides, architecture, philosophy, "how things work"

User asks "how to use X" → **code**
User asks "how X works" → **info**

## Pagination

If context insufficient, try additional pages with same topic:
```
page: 2, page: 3, etc. (max 10)
```

## Examples

### MCP Workflow Examples

**API Reference Request:**
```
User: "Show me React useState examples"
1. mcp__context7__resolve-library-id("react") → /facebook/react
2. mcp__context7__get-library-docs(/facebook/react, topic="useState", mode="code")
```

**Conceptual Question:**
```
User: "Explain Next.js routing philosophy"
1. mcp__context7__resolve-library-id("next.js") → /vercel/next.js
2. mcp__context7__get-library-docs(/vercel/next.js, topic="routing", mode="info")
```

**Specific Version:**
```
User: "How does /vercel/next.js/v14.0.0 handle middleware?"
Skip resolve, use provided ID directly
mcp__context7__get-library-docs(/vercel/next.js/v14.0.0, topic="middleware", mode="code")
```

### CLI Workflow Examples

**API Reference Request:**
```bash
# Step 1: Find library ID
./resolve.js react
# Output: {"count": 1, "libraries": [{"id": "/facebook/react", ...}]}

# Step 2: Get documentation
./get-docs.js /facebook/react --topic=useState --mode=code
```

**Conceptual Question:**
```bash
# Combined workflow
./resolve.js next.js  # Get library ID
./get-docs.js /vercel/next.js --topic=routing --mode=info
```

**Pagination:**
```bash
# Get additional pages if first page lacks context
./get-docs.js /mongodb/docs --topic=aggregation --page=1
./get-docs.js /mongodb/docs --topic=aggregation --page=2
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Using general knowledge instead of Context7 | Always check if Context7 has docs first |
| Skipping resolve step | Required unless user gives explicit ID format |
| Wrong mode selection | "how to" = code, "how it works" = info |
| Not paginating when context low | Try page=2, page=3 for more results |
| Guessing library ID format | Always resolve first |
| Missing CONTEXT7_API_KEY for CLI tools | Set environment variable before running |
| Using CLI tools when MCP available | Prefer MCP tools in normal workflow |

## Real-World Impact

- **Current documentation**: Context7 provides latest versions, not training cutoff
- **Code examples**: Real, working examples from official docs
- **Accurate APIs**: No hallucinated methods or deprecated patterns
