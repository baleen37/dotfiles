# Magic MCP Server

## Purpose
Modern UI component generation, design system integration, and responsive design

## Activation Patterns

**Automatic Activation**:
- UI component requests detected in user queries
- Design system queries or UI-related questions
- Frontend persona active in current session
- Component-related keywords detected

**Manual Activation**:
- Flag: `--magic`

**Smart Detection**:
- Component creation requests (button, form, modal, etc.)
- Design system integration needs
- UI/UX improvement requests
- Responsive design requirements

## Flags

**`--magic`**
- Enable Magic for UI component generation
- Auto-activates: UI component requests, design system queries
- Detection: component/button/form keywords, JSX patterns, accessibility requirements

**`--no-magic`**
- Disable Magic server
- Fallback: Generate basic component, suggest manual enhancement
- Performance: 10-30% faster when UI generation not needed

## Workflow Process

1. **Requirement Parsing**: Extract component specifications and design system requirements
2. **Pattern Search**: Find similar components and design patterns from 21st.dev database
3. **Framework Detection**: Identify target framework (React, Vue, Angular) and version
4. **Server Coordination**: Sync with Context7 for framework patterns, Sequential for complex logic
5. **Code Generation**: Create component with modern best practices and framework conventions
6. **Design System Integration**: Apply existing themes, styles, tokens, and design patterns
7. **Accessibility Compliance**: Ensure WCAG compliance, semantic markup, and keyboard navigation
8. **Responsive Design**: Implement mobile-first responsive patterns
9. **Optimization**: Apply performance optimizations and code splitting
10. **Quality Assurance**: Validate against design system and accessibility standards

## Integration Points

**Commands**: `build`, `implement`, `design`, `improve`

**Thinking Modes**: Works with all thinking modes for complex UI logic

**Other MCP Servers**:
- Context7 for framework patterns
- Sequential for complex component logic
- Playwright for UI testing

## Strategic Orchestration

### When to Use Magic
- **UI Component Creation**: Building modern, accessible components with design system integration
- **Design System Implementation**: Applying existing design tokens and patterns consistently
- **Rapid Prototyping**: Quick UI generation for testing and validation
- **Framework Migration**: Converting components between React, Vue, Angular
- **Accessibility Compliance**: Ensuring WCAG compliance in UI development

### Component Generation Strategy
- **Context-Aware Creation**: Magic analyzes existing design systems and applies consistent patterns
- **Performance Optimization**: Automatic code splitting, lazy loading, and bundle optimization
- **Cross-Framework Compatibility**: Intelligent adaptation to detected framework patterns  
- **Design System Integration**: Seamless integration with existing themes, tokens, and conventions

### Advanced UI Orchestration
- **Design System Evolution**: Components adapt to design system changes automatically
- **Accessibility-First Generation**: WCAG compliance built into every component from creation
- **Cross-Device Optimization**: Components optimized for desktop, tablet, and mobile simultaneously
- **Pattern Library Building**: Successful components added to reusable pattern library
- **Performance Budgeting**: Components generated within performance constraints and budgets

## Use Cases

- **Component Creation**: Generate modern UI components with best practices
- **Design System Integration**: Apply existing design tokens and patterns
- **Accessibility Enhancement**: Ensure WCAG compliance in UI components
- **Responsive Implementation**: Create mobile-first responsive layouts
- **Performance Optimization**: Implement code splitting and lazy loading

## Error Recovery

- **Magic server failure** → Generate basic component with standard patterns
- **Pattern not found** → Create custom implementation following best practices
- **Framework mismatch** → Adapt to detected framework with compatibility warnings
