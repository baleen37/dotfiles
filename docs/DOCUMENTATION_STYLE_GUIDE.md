# Documentation Style Guide

> **Version**: 1.0  
> **Last Updated**: 2025-01-06  
> **For**: Dotfiles Repository Contributors

This guide establishes consistent documentation standards across the repository to improve maintainability, accessibility, and contributor experience.

## Overview

All documentation must follow these standards to ensure consistency, readability, and professional appearance. This guide covers structure, formatting, language, and maintenance practices.

## General Principles

### Language Standards
- **Primary Language**: English for all technical documentation
- **Audience**: International contributors and users
- **Tone**: Professional, clear, and concise
- **Accessibility**: Use simple, direct language where possible

### File Organization
- **File Extension**: Always use `.md` for markdown files
- **Naming**: Use kebab-case for file names (e.g., `installation-guide.md`)
- **Location**: Place documentation in appropriate directories (`docs/`, module-specific locations)

## Document Structure Template

### Standard Template
```markdown
# [Document Title]

> **Version**: [Version Number]  
> **Last Updated**: [YYYY-MM-DD]  
> **For**: [Target Audience]

[Optional: Brief description of document purpose]

## Overview
[Brief description of what this document covers]

## Usage
[How to use this information/tool/feature]

## Examples
[Practical examples with code blocks]

## Configuration
[Configuration options and settings]

## Troubleshooting
[Common issues and solutions]

## Related Documentation
[Links to related documents]
```

### Specialized Templates

#### Module Documentation
```markdown
# [Module Name]

> **Purpose**: [Brief module description]  
> **Platform**: [Darwin/NixOS/Shared]  
> **Dependencies**: [Required dependencies]

## Overview
[Module functionality and purpose]

## Configuration
[Available configuration options]

## Usage Examples
[Practical usage examples]

## Files Modified
[List of files this module affects]
```

#### Command Documentation (Claude Commands)
```markdown
# [Command Name]

<persona>
[Clear role and expertise definition]
</persona>

<objective>
[Primary goal and purpose]
</objective>

## Usage
[How to use this command]

## Core Features
[Key capabilities and features]

## Quick Reference
| Problem | Solution |
|---------|----------|
| [Issue] | [Fix] |

## Examples
[2-3 practical examples]

<constraints>
- [Essential requirements]
- [Important limitations]
</constraints>

<validation>
[Success criteria and verification steps]
</validation>
```

## Formatting Standards

### Headers
- Use consistent header hierarchy (H1 → H2 → H3)
- Use sentence case for headers
- Include clear, descriptive header text

### Code Blocks
```markdown
# Always specify language
```bash
command example
```

# Use appropriate language identifiers
```nix
{ pkgs, ... }: {
  # Nix configuration
}
```

# Use generic 'text' for configuration files
```text
key = value
```
```

### Lists
- Use `-` for unordered lists
- Use `1.` for ordered lists
- Maintain consistent indentation (2 spaces)
- Use parallel structure in list items

### Links
- Use descriptive link text (not "click here")
- Prefer relative links for internal documentation
- Use absolute links for external resources
- Format: `[descriptive text](url)`

### Tables
```markdown
| Header 1 | Header 2 | Header 3 |
|----------|----------|----------|
| Cell 1   | Cell 2   | Cell 3   |
```

### Emphasis
- Use `**bold**` for important terms and warnings
- Use `*italic*` for emphasis and first use of technical terms
- Use `code` for technical terms, commands, and file names

## Content Guidelines

### Metadata Standards
All major documents should include:
```markdown
> **Version**: [Semantic version]  
> **Last Updated**: [YYYY-MM-DD]  
> **For**: [Target audience]
```

### Section Organization
1. **Overview**: Brief summary of document purpose
2. **Usage**: How to use the information
3. **Examples**: Practical demonstrations
4. **Configuration**: Available options and settings
5. **Troubleshooting**: Common issues and solutions
6. **Related Documentation**: Cross-references

### Example Quality
- Provide 2-3 practical examples maximum
- Use realistic scenarios
- Include expected outputs
- Show common variations

### Error Handling
- Document common error scenarios
- Provide specific solution steps
- Include troubleshooting checklists
- Reference related issues or discussions

## Maintenance Standards

### Version Control
- Update "Last Updated" field when making changes
- Increment version numbers for significant changes
- Document changes in commit messages

### Review Process
- All documentation changes require review
- Check for consistency with this style guide
- Verify all links and code examples
- Test instructions for accuracy

### Link Maintenance
- Use relative links for internal documentation
- Check links during documentation updates
- Maintain link inventory for external resources
- Update broken or outdated links

## Quality Checklist

Before submitting documentation:

- [ ] **Structure**: Follows appropriate template
- [ ] **Language**: Written in clear English
- [ ] **Formatting**: Uses consistent markdown formatting
- [ ] **Examples**: Includes practical, tested examples
- [ ] **Links**: All links are working and appropriate
- [ ] **Metadata**: Includes version and update information
- [ ] **Cross-references**: Links to related documentation
- [ ] **Accessibility**: Uses clear, simple language
- [ ] **Completeness**: Covers all necessary topics
- [ ] **Accuracy**: All technical information is correct

## Tools and Linting

### Recommended Tools
- **Markdown Linter**: Use `markdownlint` for consistency
- **Link Checker**: Verify all links work
- **Spell Checker**: Check for typos and grammar
- **Pre-commit Hooks**: Automate quality checks

### Linting Configuration
```yaml
# .markdownlint.yaml
MD013: false  # Line length
MD033: false  # Inline HTML allowed
MD041: false  # First line in file
```

## Implementation Notes

### Migration Strategy
1. **Phase 1**: Create style guide and templates
2. **Phase 2**: Update high-priority documents
3. **Phase 3**: Standardize remaining documentation
4. **Phase 4**: Implement automated linting

### Enforcement
- Include style guide checks in CI/CD
- Require documentation updates for code changes
- Regular documentation audits
- Community feedback and improvements

## Examples

### Good Documentation Example
```markdown
# Nix Darwin Configuration

> **Version**: 2.1  
> **Last Updated**: 2025-01-06  
> **For**: macOS Users

## Overview
This module configures macOS-specific settings using nix-darwin.

## Usage
```nix
imports = [ ./modules/darwin/configuration.nix ];
```

## Configuration Options
| Option | Default | Description |
|--------|---------|-------------|
| `dock.autohide` | `true` | Auto-hide dock |
```

### Poor Documentation Example
```markdown
# stuff

this is how you do things

some code here
```

## Related Documentation
- [Contributing Guide](../CONTRIBUTING.md)
- [README](../README.md)
- [Claude Commands Documentation](../modules/shared/config/claude/commands/)
