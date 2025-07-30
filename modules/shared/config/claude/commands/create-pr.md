Use the `pr-creator` specialized agent to handle all Pull Request creation tasks.

This command delegates to the pr-creator agent, which provides:
- Comprehensive pre-PR validation (branch sync, quality checks, clean working directory)
- Automated PR creation with proper titles and descriptions
- Post-creation setup (reviewers, labels, auto-merge, CI monitoring)
- Full compliance with project standards and Conventional Commits

Simply invoke this command and the pr-creator agent will handle the entire workflow.
