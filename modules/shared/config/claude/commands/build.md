# /build - Project Building & Compilation

Build, compile, and package projects with comprehensive error handling, optimization, and deployment preparation.

## Purpose
- **Framework Detection**: Auto-detect build systems and configure optimal build strategies
- **Dependency Management**: Verify and resolve build dependencies with version compatibility
- **Error Resolution**: Intelligent build error analysis and automated resolution strategies
- **Performance Optimization**: Apply build-time optimizations and comprehensive bundle analysis
- **Quality Assurance**: Integrate linting, type checking, testing, and security validation

## Usage
```bash
/build [target] [--type mode] [--clean] [--optimize] [--analyze]
```

## Arguments & Flags

### Build Targets
- `[target]` - Project or specific component to build (default: current project)
- `@component/Button` - Build specific component with dependencies
- `@service/api` - Build specific service module
- `@package/utils` - Build specific package or library

### Build Types
- `--type dev` - Development build with source maps and debugging
- `--type prod` - Production build with optimizations and minification (default)
- `--type test` - Test build with coverage instrumentation
- `--type preview` - Preview build for staging environments

### Build Options
- `--clean` - Clean build artifacts before building
- `--optimize` - Enable advanced optimizations and bundle analysis
- `--analyze` - Analyze bundle size and dependency tree
- `--verbose` - Enable detailed build output and diagnostics
- `--watch` - Enable watch mode for continuous rebuilds

### Quality Gates
- `--lint` - Run linting before build
- `--typecheck` - Run type checking before build
- `--test` - Run tests before build
- `--security` - Run security scans on build artifacts

## Build Framework Detection

### Frontend Frameworks
- **React**: Detect Vite, Webpack, Create React App configurations
- **Vue**: Support Vue CLI, Vite, Nuxt.js build systems
- **Angular**: Angular CLI and custom Webpack setups
- **Svelte**: SvelteKit and Vite-based Svelte projects
- **Next.js**: Next.js build and export configurations
- **Astro**: Astro static site generation

### Backend Frameworks
- **Node.js**: NPM/Yarn scripts, TypeScript compilation
- **Python**: Poetry, pip, setuptools, and virtual environment management
- **Go**: Go modules, build tags, and cross-compilation
- **Rust**: Cargo build system with target specifications
- **Java**: Maven, Gradle build automation
- **C#**: .NET Core/Framework MSBuild projects

### Build System Integration
- **Package Managers**: npm, yarn, pnpm, poetry, cargo, maven, gradle
- **Task Runners**: webpack, vite, rollup, parcel, esbuild
- **Monorepo Tools**: nx, lerna, rush, bazel integration
- **Docker**: Containerized builds and multi-stage optimization

## Build Execution Strategy

### Phase 1: Environment Analysis
1. **Project Detection**: Identify framework, language, and build system
2. **Dependency Validation**: Check package files and resolve conflicts
3. **Environment Setup**: Verify Node.js, Python, Go, or other runtime versions
4. **Configuration Analysis**: Parse build configs and detect custom setups

### Phase 2: Pre-Build Validation
1. **Quality Gates**: Run enabled quality checks (lint, typecheck, test, security)
2. **Dependency Resolution**: Install/update dependencies if needed
3. **Clean Operations**: Clear build artifacts if --clean specified
4. **Environment Variables**: Validate required environment configuration

### Phase 3: Build Execution
1. **Optimized Command Selection**: Choose optimal build command for detected framework
2. **Progress Monitoring**: Track build progress with detailed logging
3. **Error Detection**: Monitor for build errors and warnings
4. **Resource Monitoring**: Track build time and resource usage

### Phase 4: Post-Build Analysis
1. **Bundle Analysis**: Analyze output size and composition if --analyze enabled
2. **Quality Validation**: Verify build artifacts meet quality standards
3. **Performance Metrics**: Report build time, bundle size, and optimization gains
4. **Deployment Preparation**: Prepare artifacts for deployment or distribution

## Error Resolution Patterns

### Common Build Errors
- **Dependency Conflicts**: Version resolution and compatibility fixes
- **Type Errors**: TypeScript configuration and type definition issues
- **Import Errors**: Module resolution and path configuration problems
- **Memory Issues**: Build process optimization and resource allocation
- **Configuration Errors**: Build tool configuration and environment setup

### Automated Resolution Strategies
- **Dependency Updates**: Suggest and apply dependency updates
- **Configuration Fixes**: Auto-correct common configuration issues
- **Environment Setup**: Guide through environment configuration
- **Alternative Approaches**: Suggest alternative build strategies when primary fails

## Usage Examples

### Basic Build Operations
```bash
/build                              # Build current project with auto-detection
/build --type dev --watch          # Development build with watch mode
/build --type prod --optimize      # Production build with optimizations
/build --clean --analyze           # Clean build with bundle analysis
```

### Quality-First Builds
```bash
/build --lint --typecheck --test   # Full quality gate validation
/build --security --analyze        # Security-focused build with analysis
/build --type prod --all-checks    # Production build with all quality gates
```

### Framework-Specific Examples
```bash
/build @frontend --type prod       # Build frontend with production config
/build @api --typecheck --test     # Build API with type checking and tests
/build @components --analyze       # Build component library with analysis
```

## Tool Integration & Advanced Features

### Allowed Tools & Execution Pattern
- **Read**: Analyze build configurations and project structure
- **Bash**: Execute build commands and system operations
- **Glob**: Discover build files and dependency configurations
- **TodoWrite**: Track build progress and error resolution
- **Edit**: Fix configuration files when build errors are detected

### Build Optimization Features
- **Bundle Splitting**: Automatic code splitting for optimal loading
- **Tree Shaking**: Dead code elimination in production builds
- **Asset Optimization**: Image, CSS, and JavaScript minification
- **Caching Strategies**: Build cache optimization for faster rebuilds
- **Parallel Processing**: Multi-threaded builds when supported

### Integration Capabilities
- **CI/CD Integration**: Generate build artifacts suitable for deployment pipelines
- **Monorepo Support**: Coordinate builds across multiple packages
- **Docker Integration**: Container-optimized builds with layer caching
- **Performance Monitoring**: Track build performance metrics over time

### Wave System Integration
- **Complex Projects**: Auto-activates Wave mode for large codebases or monorepos
- **Multi-Framework**: Coordinate builds across different technology stacks
- **Error Resolution**: Systematic error analysis and resolution across build phases

## Quality Gates & Performance Targets
- **Build Success Rate**: >95% successful builds with error resolution
- **Build Time**: <5 minutes for standard projects, <20 minutes for large monorepos
- **Bundle Optimization**: 20-40% size reduction with optimization flags
- **Error Resolution**: 80%+ of common build errors automatically resolved or guided
