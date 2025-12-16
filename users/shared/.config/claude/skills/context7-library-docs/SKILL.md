---
name: context7-library-docs
description: Use when user asks about library documentation, API usage, framework features, or how to use specific libraries - retrieves up-to-date documentation using Context7 instead of relying on training data
---

# Context7 Library Documentation

## Overview

Use Context7 MCP tools to fetch current library documentation instead of relying on potentially outdated training data. Always prefer fresh documentation over knowledge cutoff.

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

## Two-Step Workflow

**REQUIRED: Always follow this sequence**

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

**API Reference Request:**
```
User: "Show me React useState examples"
1. resolve-library-id("react") → /facebook/react
2. get-library-docs(/facebook/react, topic="useState", mode="code")
```

**Conceptual Question:**
```
User: "Explain Next.js routing philosophy"
1. resolve-library-id("next.js") → /vercel/next.js
2. get-library-docs(/vercel/next.js, topic="routing", mode="info")
```

**Specific Version:**
```
User: "How does /vercel/next.js/v14.0.0 handle middleware?"
Skip resolve, use provided ID directly
get-library-docs(/vercel/next.js/v14.0.0, topic="middleware", mode="code")
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Using general knowledge instead of Context7 | Always check if Context7 has docs first |
| Skipping resolve-library-id | Required unless user gives explicit ID |
| Wrong mode selection | "how to" = code, "how it works" = info |
| Not paginating when context low | Try page=2, page=3 for more results |
| Guessing library ID format | Always resolve first |

## Real-World Impact

- **Current documentation**: Context7 provides latest versions, not training cutoff
- **Code examples**: Real, working examples from official docs
- **Accurate APIs**: No hallucinated methods or deprecated patterns
