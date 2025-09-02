---
name: implement_v2
description: "Intelligent code implementation with multi-domain coordination and validation"
---

Implement features through coordinated analysis, design, coding, and validation with comprehensive quality assurance.

**Usage**: `/implement_v2 [feature-description] [--type component|api|service|feature] [--framework react|vue|express|nextjs] [--safe] [--with-tests]`

## Implementation Types

- `component`: UI component implementation
- `api`: REST/GraphQL API endpoint development  
- `service`: Business logic service implementation
- `feature`: Complete end-to-end feature implementation

## Framework Support

- `react`: React.js components and hooks
- `vue`: Vue.js components and composition API
- `express`: Express.js server and middleware
- `nextjs`: Next.js full-stack implementation

## Flags

- `--safe`: Enhanced security validation and review
- `--with-tests`: Automatic test generation (unit, integration, e2e)

## Implementation Flow

1. **Requirements Analysis**: Parse specifications and determine technical approach
2. **Architecture Design**: Plan component structure, data flow, and integration points
3. **Code Generation**: Write implementation following project patterns and conventions
4. **Security Validation**: Review for vulnerabilities and security best practices
5. **Quality Assurance**: Code quality, performance, and maintainability review
6. **Testing**: Generate and run comprehensive test suite
7. **Integration**: Ensure compatibility with existing codebase

## Multi-Domain Coordination

- **Architecture**: System design and technical decisions
- **Frontend**: UI/UX implementation and user interaction
- **Backend**: Server logic, APIs, and data management
- **Security**: Vulnerability assessment and secure coding practices
- **Testing**: Test strategy and comprehensive validation

## Key Features

- **Context-Aware**: Analyzes existing codebase patterns and conventions
- **Incremental**: Builds features step-by-step with validation
- **Comprehensive**: Includes documentation, tests, and integration
- **Quality-First**: Validates security, performance, and maintainability

## Example Usage

```
/implement_v2 "User authentication with OAuth" --type feature --framework nextjs --safe --with-tests
```

This will implement a complete OAuth authentication system with security validation, comprehensive tests, and proper integration with your Next.js application.
