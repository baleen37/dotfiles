# GEMINI.md: AI Assistant Project Guide

> **Project:** [Project Name]
> **Version:** 1.0
> **Purpose:** This document provides essential guidance for AI assistants to effectively contribute to this project.

<persona>
You are a professional software engineer and a core contributor to this project. You must strictly adhere to the project's established conventions, architecture, and workflows.
</persona>

<objective>
To understand and follow the project's standards in order to write high-quality code, submit valid pull requests, and collaborate effectively with the team.
</objective>

---

## 1. Core Directives

**These are the fundamental rules for working on this project.**

1.  **Environment Setup**: [e.g., This project uses Docker for its development environment. Run `docker-compose up` to start.]
2.  **Code Style & Linting**: [e.g., We use Prettier and ESLint. Run `npm run lint` before committing.]
3.  **Testing**: [e.g., All new code requires unit tests. Run `npm test` to validate.]
4.  **Commit Messages**: [e.g., Commits must follow the Conventional Commits specification.]
5.  **Branching Strategy**: [e.g., All work must be done on feature branches named `type/scope` (e.g., `feat/user-auth`).]
6.  **Pull Requests (PRs)**: [e.g., All PRs must be reviewed and approved by at least one other developer.]
7.  **Secrets Management**: [e.g., Never commit secrets. Use the project's designated secrets manager.]

---

## 2. Key Commands

| Command | Description |
|---|---|
| `[build_command]` | [e.g., `npm run build`] - Compiles the project. |
| `[test_command]` | [e.g., `npm test`] - Runs all unit and integration tests. |
| `[lint_command]` | [e.g., `npm run lint`] - Lints and formats the codebase. |
| `[run_command]` | [e.g., `npm run dev`] - Starts the development server. |

---

## 3. Standard Workflow

1.  **Sync with Main**: `git checkout main && git pull`.
2.  **Create Feature Branch**: `git checkout -b <branch-name>`.
3.  **Implement Changes**: Write code and add tests.
4.  **Validate Locally**: Run `[lint_command]` and `[test_command]` to ensure all checks pass.
5.  **Commit Changes**: `git commit -m "Your descriptive commit message"`.
6.  **Push and Create PR**: Push your branch and open a pull request on GitHub, following the PR template.

---

## 4. Architecture Overview

- **`src/`**: [e.g., Contains all the primary application source code.]
- **`tests/`**: [e.g., Contains all unit and integration tests.]
- **`docs/`**: [e.g., Contains all project documentation.]
- **`scripts/`**: [e.g., Contains build and utility scripts.]

*(This section should be filled out with a high-level overview of the project's structure.)*
