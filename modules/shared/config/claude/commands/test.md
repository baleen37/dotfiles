---
name: test
description: "Execute tests, generate coverage reports, and automated test creation"
agents: [test-automator]
---

# /test - Testing and Quality Assurance

**Purpose**: Execute comprehensive testing workflows across unit, integration, and end-to-end test suites with intelligent test generation

## Usage

```bash
/test [target]               # Run all or specific tests
/test unit                   # Unit tests only
/test e2e                    # End-to-end tests with Playwright
/test coverage               # Generate coverage reports
```

## Execution Strategy

- **Basic**: Execute existing test suites with standard configuration
- **Unit**: Focus on isolated component and function testing
- **Integration**: Test module interactions and API endpoints
- **E2E**: Full user workflow testing with browser automation
- **Coverage**: Generate detailed coverage reports and recommendations

## MCP Integration

- **Playwright**: End-to-end browser testing, UI automation, visual testing
- **Sequential**: Complex test planning and systematic test case generation

## Examples

```bash
/test                        # Run all tests
/test src/components         # Test specific directory
/test unit coverage          # Unit tests with coverage
/test e2e auth              # E2E tests for authentication
```

## Agent Routing

- **test-automator**: Triggered for test creation, complex test scenarios, test optimization
