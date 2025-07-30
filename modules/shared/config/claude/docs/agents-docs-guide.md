# Agent Documentation Guide

This document provides a guide for documenting Claude agents to clearly define their roles and capabilities. This documentation helps other agents and users easily understand each agent's specialty and how to use them.

## Format

Agent documentation uses YAML front matter. Each document must start and end with `---`.

```yaml
---
name: [agent-name]
description: [Detailed description of the agent]
---
```

### Fields

- `name`: A unique, concise, and clear name for the agent, reflecting its core function (e.g., `security-auditor`, `nix-expert`, `frontend-developer`).
- `description`: A detailed explanation of the agent's responsibilities, skills, and areas of expertise.
    - What tasks does it perform?
    - What technology stack is it familiar with (e.g., JWT, OAuth2, Nix, React)?
    - What standards does it adhere to (e.g., OWASP, POSIX)?
    - Clear guidelines on when to use this agent (e.g., `Use PROACTIVELY for...`).

---

## Examples

### Good Example

This example is the gold standard. It clearly defines the agent's role, skills, and use case.

```yaml
---
name: security-auditor
description: Review code for vulnerabilities, implement secure authentication, and ensure OWASP compliance. Handles JWT, OAuth2, CORS, CSP, and encryption. Use PROACTIVELY for security reviews, auth flows, or vulnerability fixes.
---
```

### Another Good Example

```yaml
---
name: nix-expert
description: Manages Nix and NixOS configurations. Specializes in flake.nix, Nix modules, and home-manager. Responsible for optimizing Nix builds, ensuring reproducibility, and troubleshooting Nix-related issues.
---
```

### Bad Example

This example is too vague and lacks the necessary detail.

```yaml
---
name: coder
description: Writes code.
---
```

**Why it's bad:**
- **Vague**: It's unclear what kind of code the agent writes (frontend, backend, infrastructure, etc.).
- **Lacks Detail**: No mention of programming languages, frameworks, or libraries.
- **No Context**: It's impossible to know when to call this agent.

---

## Core Principles

1.  **Be Specific**: Detail the agent's abilities and specialties.
2.  **Be Clear**: Use simple, unambiguous language.
3.  **Write in English**: Maintain consistency with other project documents.
4.  **Keep Up-to-Date**: Update the documentation if the agent's capabilities change.
