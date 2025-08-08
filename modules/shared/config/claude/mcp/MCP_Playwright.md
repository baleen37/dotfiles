# Playwright MCP Server

## Purpose
Cross-browser E2E testing, performance monitoring, automation, and visual testing

## Activation Patterns

**Automatic Activation**:
- Testing workflows and test generation requests
- Performance monitoring requirements
- E2E test generation needs
- QA persona active

**Manual Activation**:
- Flag: `--play`, `--playwright`

**Smart Detection**:
- Browser interaction requirements
- Keywords: test, e2e, performance, visual testing, cross-browser
- Testing or quality assurance contexts

## Flags

**`--play` / `--playwright`**
- Enable Playwright for cross-browser automation and E2E testing
- Detection: test/e2e keywords, performance monitoring, visual testing, cross-browser requirements

**`--no-play` / `--no-playwright`**
- Disable Playwright server
- Fallback: Suggest manual testing, provide test cases
- Performance: 10-30% faster when testing not needed

## Workflow Process

1. **Browser Connection**: Connect to Chrome, Firefox, Safari, or Edge instances
2. **Environment Setup**: Configure viewport, user agent, network conditions, device emulation
3. **Navigation**: Navigate to target URLs with proper waiting and error handling
4. **Server Coordination**: Sync with Sequential for test planning, Magic for UI validation
5. **Interaction**: Perform user actions (clicks, form fills, navigation) across browsers
6. **Data Collection**: Capture screenshots, videos, performance metrics, console logs
7. **Validation**: Verify expected behaviors, visual states, and performance thresholds
8. **Multi-Server Analysis**: Coordinate with other servers for comprehensive test analysis
9. **Reporting**: Generate test reports with evidence, metrics, and actionable insights
10. **Cleanup**: Properly close browser connections and clean up resources

## Integration Points

**Commands**: `test`, `troubleshoot`, `analyze`, `validate`

**Thinking Modes**: Works with all thinking modes for test strategy planning

**Other MCP Servers**:
- Sequential (test planning and analysis)
- Magic (UI validation and component testing)
- Context7 (testing patterns and best practices)

## Strategic Orchestration

### When to Use Playwright
- **E2E Test Generation**: Creating comprehensive user workflow tests
- **Cross-Browser Validation**: Ensuring functionality across all major browsers
- **Performance Monitoring**: Continuous performance measurement and threshold alerting  
- **Visual Regression Testing**: Automated detection of UI changes and layout issues
- **User Experience Validation**: Accessibility testing and usability verification

### Testing Strategy Coordination
- **With Sequential**: Sequential plans test strategy → Playwright executes comprehensive testing
- **With Magic**: Magic generates UI components → Playwright validates component functionality
- **With Context7**: Context7 provides testing patterns → Playwright implements best practices
- **With Serena**: Serena analyzes code changes → Playwright generates targeted regression tests

### Multi-Browser Orchestration
- **Parallel Execution Strategy**: Intelligent distribution of tests across browser instances
- **Resource Management**: Dynamic allocation based on system capabilities and test complexity
- **Result Aggregation**: Unified reporting across all browser test results
- **Failure Analysis**: Cross-browser failure pattern detection and reporting

### Advanced Testing Intelligence
- **Adaptive Test Generation**: Tests generated based on code change impact analysis
- **Performance Regression Detection**: Automated identification of performance degradation
- **Visual Diff Analysis**: Pixel-perfect comparison with intelligent tolerance algorithms
- **User Journey Optimization**: Test paths optimized for real user behavior patterns
- **Continuous Quality Monitoring**: Real-time feedback loop for development quality assurance

## Use Cases

- **Test Generation**: Create E2E tests based on user workflows and critical paths
- **Performance Monitoring**: Continuous performance measurement with threshold alerting
- **Visual Validation**: Screenshot-based testing and regression detection
- **Cross-Browser Testing**: Validate functionality across all major browsers
- **User Experience Testing**: Accessibility validation, usability testing, conversion optimization

## Error Recovery

- **Connection lost** → Automatic reconnection → Provide manual test scripts
- **Browser timeout** → Retry with adjusted timeout → Fallback to headless mode
- **Element not found** → Apply wait strategies → Use alternative selectors

## Quality Gates Integration

- **Step 5 - E2E Testing**: End-to-end tests with coverage analysis (≥80% unit, ≥70% integration)
- **Step 8 - Integration Testing**: Deployment validation and cross-browser testing
