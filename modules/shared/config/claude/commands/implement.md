# /implement - Intelligent Feature & Code Implementation

Context-aware implementation with pattern recognition, framework adaptation, and automated quality assurance.

## Purpose
- **Context-Aware Generation**: Analyze existing codebase patterns and adapt implementation style
- **Framework Intelligence**: Auto-detect and optimize for React, Vue, Node.js, Python, etc.
- **Quality-First Approach**: Built-in type safety, error handling, and testing
- **Pattern Consistency**: Maintain consistency with existing architectural patterns
- **Documentation Integration**: Auto-generate documentation and usage examples

## Usage
```bash
/implement [feature-description] [--type component|api|service|feature] [--framework auto|react|vue|node|python] [--with-tests] [--safe]
```

## Arguments & Flags

### Implementation Types
- `--type component` - UI components, widgets, and visual elements
- `--type api` - REST/GraphQL APIs, endpoints, and web services  
- `--type service` - Business logic services, utilities, and modules
- `--type feature` - Complete features spanning multiple layers
- `--type integration` - Third-party service integrations and connectors
- `--type migration` - Database migrations and data transformations

### Framework & Technology
- `--framework auto` - Auto-detect framework from project structure (default)
- `--framework react` - React components with hooks, TypeScript, modern patterns
- `--framework vue` - Vue 3 components with Composition API and TypeScript
- `--framework node` - Node.js services with Express, Fastify, or similar
- `--framework python` - Python with FastAPI, Django, or Flask patterns
- `--framework go` - Go services with standard library and common patterns

### Quality & Safety
- `--with-tests` - Generate comprehensive test suites (unit, integration, e2e)
- `--safe` - Conservative implementation with extensive validation
- `--iterative` - Step-by-step implementation with validation checkpoints
- `--review` - Include code review checklist and quality gates
- `--secure` - Enhanced security considerations and vulnerability prevention

### Development Mode
- `--tdd` - Test-driven development approach (tests first)
- `--prototype` - Rapid prototyping mode with basic functionality
- `--production` - Production-ready implementation with full error handling
- `--refactor` - Refactor existing implementation while preserving functionality

## Implementation Strategies

### Context Analysis
1. **Codebase Scanning**: Analyze existing patterns, conventions, and architecture
2. **Framework Detection**: Identify technology stack and version constraints
3. **Pattern Recognition**: Extract reusable patterns and design principles
4. **Dependency Analysis**: Understand available libraries and constraints
5. **Style Consistency**: Match coding style, naming conventions, and organization

### Code Generation Process
1. **Requirements Decomposition**: Break down feature into implementable components
2. **Architecture Planning**: Design component structure and data flow
3. **Implementation Generation**: Create code following best practices
4. **Integration Verification**: Ensure compatibility with existing codebase
5. **Quality Validation**: Apply linting, type checking, and security scanning

### Testing Integration
- **Unit Tests**: Component-level testing with comprehensive coverage
- **Integration Tests**: Service interaction and API endpoint testing
- **End-to-End Tests**: Complete user workflow validation
- **Performance Tests**: Load testing and performance benchmarking
- **Security Tests**: Vulnerability scanning and security validation

## Framework-Specific Features

### React Implementation
- Modern hooks and functional components
- TypeScript integration with proper typing
- State management (Context, Redux, Zustand)
- Performance optimization (memo, useMemo, useCallback)
- Accessibility compliance (WCAG 2.1)
- Testing with React Testing Library

### Vue Implementation  
- Vue 3 Composition API
- TypeScript support with defineComponent
- Reactive state management with Pinia
- Performance optimization with reactive patterns
- Testing with Vue Test Utils

### Node.js Implementation
- Express/Fastify server setup
- Middleware integration and error handling
- Database integration (SQL, NoSQL)
- Authentication and authorization
- API documentation with OpenAPI/Swagger
- Testing with Jest/Mocha

### Python Implementation
- FastAPI or Django REST framework
- Type hints and Pydantic models
- Database ORM integration (SQLAlchemy, Django ORM)
- Async/await patterns for performance
- Testing with pytest
- API documentation generation

## Quality Assurance

### Code Quality Standards
- **Type Safety**: Comprehensive TypeScript/type hints usage
- **Error Handling**: Graceful error handling and user feedback
- **Performance**: Optimized algorithms and resource usage
- **Security**: Input validation, sanitization, and vulnerability prevention
- **Maintainability**: Clear code structure and comprehensive documentation

### Automated Validation
- **Linting**: ESLint, Pylint, or language-specific linters
- **Type Checking**: TypeScript, mypy, or equivalent type checkers
- **Security Scanning**: SAST tools and vulnerability detection
- **Performance Analysis**: Bundle analysis and performance profiling
- **Accessibility Testing**: WCAG compliance validation

### Review Integration
- **Code Review Checklist**: Automated quality gate checklist
- **Architecture Review**: Design pattern and structure validation
- **Security Review**: Security vulnerability and best practice check
- **Performance Review**: Performance impact and optimization opportunities

## Advanced Features

### Smart Refactoring
- **Pattern Extraction**: Identify and extract reusable patterns
- **Legacy Modernization**: Update deprecated patterns to modern equivalents
- **Performance Optimization**: Optimize algorithms and resource usage
- **Security Hardening**: Apply security best practices and fix vulnerabilities

### Integration Capabilities
- **API Integration**: Third-party service integration with error handling
- **Database Integration**: ORM setup and migration generation
- **Authentication Integration**: OAuth, JWT, and session management
- **Payment Integration**: Stripe, PayPal, and payment gateway setup
- **Monitoring Integration**: Logging, metrics, and error tracking

### Documentation Generation
- **API Documentation**: OpenAPI/Swagger specification generation
- **Component Documentation**: Storybook integration and component guides
- **Usage Examples**: Practical implementation examples and tutorials
- **Architecture Documentation**: System design and integration guides

## Usage Examples

### Component Implementation
```bash
/implement "user profile card component" --type component --framework react --with-tests
/implement "data visualization chart" --type component --framework vue --secure
```

### API Implementation
```bash
/implement "user authentication API" --type api --framework node --with-tests --secure
/implement "file upload service" --type service --framework python --production
```

### Feature Implementation
```bash
/implement "real-time chat system" --type feature --iterative --with-tests
/implement "payment processing workflow" --type feature --safe --secure --review
```

### Integration Implementation
```bash
/implement "Stripe payment integration" --type integration --framework node --production
/implement "OAuth Google login" --type integration --secure --with-tests
```
