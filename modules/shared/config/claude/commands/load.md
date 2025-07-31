# /load - Intelligent Project Context Loader

Comprehensively analyze and internalize project context with intelligent pattern recognition and framework detection.

## Purpose
- **Intelligent Analysis**: Deep project structure analysis with framework detection
- **Context Internalization**: Build comprehensive understanding of codebase patterns
- **Development Environment**: Verify toolchain and environment configuration
- **Pattern Recognition**: Identify architectural patterns and conventions
- **Documentation Generation**: Create project context maps and development guides

## Usage
```bash
/load [target] [--scope project|module|component] [--focus domain] [--output format]
```

## Arguments & Flags

### Target Specification
- `[target]` - Project path, module, or component (default: current directory)
- `@monorepo/` - Load entire monorepo with workspace analysis
- `@backend/` - Focus on backend services and APIs
- `@frontend/` - Focus on UI components and client-side code
- `@docs/` - Load documentation and knowledge base

### Scope Control
- `--scope project` - Full project analysis (default)
- `--scope module` - Single module/package analysis
- `--scope component` - Individual component deep-dive
- `--scope dependencies` - Dependency tree and external libraries

### Focus Areas
- `--focus architecture` - System design and structure patterns
- `--focus security` - Security implementation and vulnerabilities
- `--focus performance` - Performance patterns and bottlenecks
- `--focus testing` - Test coverage and quality patterns
- `--focus deployment` - CI/CD and deployment configuration
- `--focus documentation` - Documentation quality and coverage

### Output Formats
- `--output summary` - Executive summary with key insights (default)
- `--output detailed` - Comprehensive analysis report
- `--output patterns` - Code patterns and conventions guide
- `--output roadmap` - Development roadmap and improvement areas
- `--output wiki` - Knowledge base format for team sharing

### Analysis Depth
- `--quick` - Essential patterns and configuration (5-10 min)
- `--standard` - Comprehensive analysis (15-30 min, default)
- `--deep` - Full architectural analysis (45+ min)
- `--continuous` - Ongoing analysis with change detection

### Integration Features
- `--create-tasks` - Generate task hierarchy for identified improvements
- `--update-wiki` - Update project documentation automatically
- `--benchmark` - Compare against industry standards and best practices
- `--dependencies` - Analyze and audit dependency security/updates

## Auto-Activation Patterns
- **New Project**: Automatically suggest when entering unfamiliar codebase
- **Framework Changes**: Trigger when major dependencies change
- **Team Onboarding**: Activate for new team member context building
- **Architecture Review**: Enable for system-wide analysis requests

## Analysis Framework

### Phase 1: Discovery & Inventory
1. **Project Structure Analysis**: Directory layout, module organization
2. **Framework Detection**: Technology stack identification and versions
3. **Configuration Mapping**: Build tools, environment variables, secrets
4. **Dependency Analysis**: Package dependencies, version compatibility
5. **Documentation Inventory**: README, wikis, code comments, API docs

### Phase 2: Pattern Recognition
1. **Architectural Patterns**: MVC, microservices, monolith, event-driven
2. **Code Conventions**: Naming, formatting, organization standards
3. **Security Patterns**: Authentication, authorization, data protection
4. **Testing Patterns**: Unit, integration, E2E test strategies
5. **Error Handling**: Logging, monitoring, recovery patterns

### Phase 3: Quality Assessment
1. **Code Quality**: Complexity, maintainability, technical debt
2. **Security Posture**: Vulnerability assessment, compliance gaps
3. **Performance Analysis**: Bottlenecks, optimization opportunities
4. **Documentation Quality**: Coverage, accuracy, usefulness
5. **Development Experience**: Tooling, automation, developer productivity

### Phase 4: Intelligent Recommendations
1. **Improvement Priorities**: Risk-based improvement roadmap
2. **Best Practice Alignment**: Framework-specific recommendations
3. **Tooling Optimization**: Development workflow enhancements
4. **Architecture Evolution**: Scalability and maintainability improvements
5. **Team Enablement**: Knowledge transfer and documentation needs

## Framework-Specific Intelligence

### Frontend Frameworks
```yaml
React:
  patterns: [components, hooks, context, routing]
  conventions: [file_structure, naming, state_management]
  tools: [bundler, testing, linting, deployment]
  performance: [bundle_size, rendering, caching]

Vue:
  patterns: [components, composition_api, stores, routing]
  conventions: [sfc_structure, naming, organization]
  tools: [vite, testing, devtools, deployment]
  performance: [tree_shaking, lazy_loading, optimization]

Angular:
  patterns: [modules, components, services, routing]
  conventions: [file_structure, naming, dependency_injection]
  tools: [cli, testing, linting, deployment]
  performance: [change_detection, lazy_loading, optimization]
```

### Backend Frameworks
```yaml
Node.js:
  patterns: [express, fastify, nest, microservices]
  conventions: [routing, middleware, error_handling]
  tools: [package_manager, testing, monitoring]
  performance: [async_patterns, clustering, caching]

Python:
  patterns: [django, flask, fastapi, async]
  conventions: [project_structure, naming, imports]
  tools: [dependency_management, testing, deployment]
  performance: [async_patterns, database_optimization]

Go:
  patterns: [modules, interfaces, concurrency]
  conventions: [package_structure, naming, error_handling]
  tools: [modules, testing, build, deployment]
  performance: [goroutines, memory_management, profiling]
```

## Integration with SuperClaude Ecosystem

### Persona Auto-Activation
- **Architect**: Complex system analysis, architecture review
- **Security**: Security-focused analysis, vulnerability assessment
- **Performance**: Performance analysis, optimization opportunities
- **Frontend**: UI/UX patterns, component architecture
- **Backend**: API design, data architecture, scalability
- **QA**: Testing patterns, quality assessment
- **Scribe**: Documentation analysis, knowledge base creation

### MCP Server Integration
- **Context7**: Framework documentation, best practices lookup
- **Sequential**: Complex architectural analysis, pattern recognition
- **Magic**: UI component analysis, design system evaluation
- **Playwright**: E2E testing analysis, user workflow mapping

### Command Integration
- **→ /workflow**: Generate implementation workflows from analysis
- **→ /task**: Create task hierarchy for identified improvements
- **→ /improve**: Target specific improvement areas discovered
- **→ /analyze**: Deep-dive into specific components or patterns
- **→ /document**: Generate comprehensive project documentation

### Wave System Integration
- **Auto-Activation**: Complex projects (>100 files, multiple frameworks)
- **Progressive Analysis**: Systematic analysis across multiple domains
- **Quality Gates**: Validation and verification at each analysis phase

## Output Examples

### Summary Format (`--output summary`)
```markdown
# Project Context Summary

## 🏢 Architecture Overview
- **Type**: Monorepo with React frontend + Node.js backend
- **Scale**: ~2.5K files, 15 services, 3 databases
- **Maturity**: Production-ready with moderate technical debt

## 🛠️ Technology Stack
- **Frontend**: React 18, TypeScript, Vite, Tailwind CSS
- **Backend**: Node.js, Express, PostgreSQL, Redis
- **Infrastructure**: Docker, AWS, GitHub Actions

## 📈 Key Insights
- Strong component architecture with 85% TypeScript coverage
- Well-structured API with OpenAPI documentation
- Comprehensive testing (78% coverage) but limited E2E tests
- Modern CI/CD pipeline with automated deployments
```

### Patterns Format (`--output patterns`)
```markdown
# Development Patterns Guide

## Component Patterns
```typescript
// Standard component structure
interface ComponentProps {
  // Props definition
}

export const Component: React.FC<ComponentProps> = ({ }) => {
  // Implementation
};
```

## API Patterns
```javascript
// Standard API endpoint structure
router.get('/api/resource/:id',
  authenticate,
  validate(schema),
  async (req, res) => {
    // Implementation
  }
);
```
```

### Roadmap Format (`--output roadmap`)
```markdown
# Development Roadmap

## 🔴 High Priority (Next 30 days)
- [ ] Upgrade React to v18 for concurrent features
- [ ] Implement comprehensive error boundaries
- [ ] Add E2E testing with Playwright

## 🟡 Medium Priority (Next 90 days)
- [ ] Migrate to React Server Components
- [ ] Implement advanced caching strategies
- [ ] Enhance monitoring and observability

## 🟢 Low Priority (Future)
- [ ] Evaluate micro-frontend architecture
- [ ] Consider GraphQL migration
- [ ] Implement advanced performance optimizations
```

## Performance & Quality Gates
- **Analysis Speed**: <30s for standard projects, <2min for complex monorepos
- **Accuracy**: 95%+ framework detection, 90%+ pattern recognition
- **Coverage**: 100% file type recognition, 95%+ configuration detection
- **Usefulness**: Actionable insights in 90%+ of recommendations
- **Integration**: Seamless handoff to other SuperClaude commands
