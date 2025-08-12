---
name: document
description: "Generate focused documentation for components, APIs, and features"
agents: [technical-writer]
---

# /document - Documentation Generation

**Purpose**: Generate comprehensive documentation for code components, APIs, and features with proper formatting and integration

## Usage

```bash
/document <target>           # Generate general documentation
/document api <path>         # API documentation with examples
/document inline <file>      # Add inline code comments
/document guide <feature>    # User guide documentation
```

## Execution Strategy

- **Basic**: Code analysis and documentation generation from source
- **API**: RESTful API documentation with request/response examples
- **Inline**: JSDoc/DocString comments for functions and classes
- **Guide**: User-facing documentation with usage examples
- **Integration**: Cross-reference linking and project standards

## MCP Integration

- **Context7**: Framework-specific documentation patterns and best practices

## Examples

```bash
/document auth/login.js      # Function documentation
/document api endpoints/     # API reference documentation
/document inline UserClass  # Add JSDoc comments
/document guide authentication # User guide creation
```

## Agent Routing

- **technical-writer**: Complex documentation projects, style consistency, comprehensive guides
