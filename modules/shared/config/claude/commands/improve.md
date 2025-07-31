# /improve - Evidence-Based Code Enhancement

Systematically improve code quality, performance, and maintainability through evidence-based analysis and iterative enhancement.

## Purpose
- **Evidence-Based Improvements**: Measure before and after for quantifiable results
- **Systematic Enhancement**: Multi-dimensional improvement across quality, performance, security
- **Wave-Enabled Orchestration**: Auto-activate Wave mode for complex improvements
- **Iterative Refinement**: Built-in loop capability for progressive enhancement
- **Safety-First Approach**: Preserve functionality while enhancing structure

## Usage
```bash
/improve [target] [--focus domain] [--strategy approach] [--depth level]
```

## Arguments & Flags

### Target Specification
- `[target]` - File, directory, or pattern to improve (default: current directory)
- `@component/Button.tsx` - Specific component improvement
- `@api/auth/` - API module enhancement
- `@performance` - Performance-focused improvements across codebase
- `@security` - Security hardening and vulnerability fixes
- `@quality` - Code quality and maintainability improvements

### Focus Areas
- `--focus performance` - Performance optimization and bottleneck resolution
- `--focus security` - Security hardening and vulnerability remediation
- `--focus quality` - Code quality, readability, and maintainability
- `--focus architecture` - Structural improvements and pattern application
- `--focus accessibility` - UI/UX accessibility compliance and enhancement
- `--focus testing` - Test coverage and quality improvements
- `--focus documentation` - Documentation completeness and quality

### Improvement Strategies
- `--strategy conservative` - Safe, low-risk improvements only
- `--strategy balanced` - Mix of safe and moderate-risk improvements (default)
- `--strategy aggressive` - Comprehensive improvements including refactoring
- `--strategy modern` - Upgrade to latest patterns and technologies
- `--strategy minimal` - Smallest changes for maximum impact

### Analysis Depth
- `--depth surface` - Quick wins and obvious improvements
- `--depth standard` - Comprehensive analysis and improvements (default)
- `--depth deep` - Architectural improvements and major refactoring
- `--depth comprehensive` - System-wide improvements with Wave activation

### Iterative Enhancement
- `--loop` - Enable iterative improvement mode (auto-detected for refinement)
- `--iterations [n]` - Number of improvement cycles (default: 3)
- `--interactive` - Pause between iterations for review and approval
- `--validate` - Comprehensive validation between iterations

### Safety & Validation
- `--safe-mode` - Maximum safety with extensive validation
- `--backup` - Create backup before making changes
- `--dry-run` - Show planned improvements without making changes
- `--validate-tests` - Run tests before and after improvements
- `--rollback-ready` - Prepare automatic rollback capability

### Wave Integration
- `--wave-mode auto|force|off` - Control Wave orchestration activation
- `--wave-strategy progressive|systematic|adaptive` - Wave execution strategy
- `--wave-validation` - Enable comprehensive validation across Wave phases

## Auto-Activation Patterns

### Wave Mode Triggers
- **High Complexity**: >0.8 complexity score with >20 files
- **Multi-Domain**: Performance + security + quality improvements
- **Large Scale**: >100 files or enterprise-level improvements
- **Critical Systems**: Production systems requiring systematic enhancement

### Persona Auto-Activation
- **Performance Focus**: → performance persona + Playwright metrics
- **Security Focus**: → security persona + vulnerability scanning
- **Quality Focus**: → refactorer persona + systematic analysis
- **Architecture Focus**: → architect persona + design pattern analysis
- **Frontend Focus**: → frontend persona + accessibility validation

### Loop Mode Auto-Activation
- **Refinement Keywords**: polish, refine, enhance, iteratively
- **Quality Improvement**: Code quality below thresholds
- **Performance Issues**: Metrics below performance budgets

## Improvement Framework

### Phase 1: Evidence Collection & Analysis
1. **Current State Assessment**: Metrics, performance, quality scores
2. **Problem Identification**: Bottlenecks, vulnerabilities, technical debt
3. **Impact Analysis**: Risk assessment and improvement prioritization
4. **Success Criteria**: Define measurable improvement targets
5. **Safety Planning**: Backup and rollback strategies

### Phase 2: Improvement Planning
1. **Strategy Selection**: Choose optimal improvement approach
2. **Change Sequencing**: Order improvements by safety and impact
3. **Dependency Mapping**: Identify interdependencies and conflicts
4. **Validation Planning**: Test strategies and quality gates
5. **Timeline Estimation**: Realistic improvement timeline

### Phase 3: Implementation
1. **Incremental Changes**: Small, safe, verifiable improvements
2. **Continuous Validation**: Test and validate each change
3. **Progress Monitoring**: Track metrics and quality indicators
4. **Risk Management**: Monitor for regressions or issues
5. **Documentation**: Record changes and rationale

### Phase 4: Validation & Measurement
1. **Comprehensive Testing**: Unit, integration, E2E validation
2. **Performance Measurement**: Before/after metrics comparison
3. **Quality Assessment**: Code quality and maintainability scores
4. **Security Validation**: Vulnerability and compliance checks
5. **Success Verification**: Confirm improvement targets met

## Focus-Specific Improvements

### Performance Optimization
```yaml
metrics:
  - response_time: "API endpoints <200ms"
  - bundle_size: "Frontend bundles <500KB"
  - memory_usage: "<100MB baseline"
  - database_queries: "N+1 elimination"

techniques:
  - caching_strategies: ["Redis", "CDN", "browser"]
  - code_splitting: ["route", "component", "vendor"]
  - database_optimization: ["indexing", "query_optimization"]
  - asset_optimization: ["compression", "lazy_loading"]
```

### Security Hardening
```yaml
vulnerabilities:
  - dependency_audit: "npm audit, Snyk scanning"
  - code_scanning: "Static analysis, SAST"
  - configuration_review: "Security headers, HTTPS"
  - authentication: "JWT, OAuth, session management"

compliance:
  - owasp_top_10: "Address security risks"
  - data_protection: "GDPR, encryption at rest"
  - access_control: "RBAC, principle of least privilege"
  - audit_logging: "Security event tracking"
```

### Code Quality Enhancement
```yaml
quality_metrics:
  - complexity: "Cyclomatic <10, cognitive <15"
  - maintainability: "Maintainability index >70"
  - test_coverage: "Unit >80%, integration >70%"
  - documentation: "API docs, code comments"

techniques:
  - refactoring: ["extract_method", "reduce_complexity"]
  - patterns: ["SOLID_principles", "design_patterns"]
  - conventions: ["naming", "formatting", "organization"]
  - technical_debt: ["debt_identification", "prioritization"]
```

## Integration with SuperClaude Ecosystem

### Command Coordination
- **← /analyze**: Import analysis findings for targeted improvements
- **← /load**: Use project context for informed improvement decisions
- **→ /task**: Generate improvement task hierarchy for complex changes
- **↔️ /workflow**: Coordinate with development workflows
- **→ /test**: Validate improvements with comprehensive testing

### MCP Server Integration
- **Sequential**: Primary for systematic improvement analysis
- **Context7**: Best practices and improvement patterns lookup
- **Playwright**: Performance measurement and E2E validation
- **Magic**: UI component improvement and accessibility enhancement

### Wave System Integration
- **Progressive Waves**: Incremental improvements across multiple phases
- **Systematic Waves**: Methodical improvement with comprehensive validation
- **Adaptive Waves**: Dynamic improvement strategy based on findings
- **Enterprise Waves**: Large-scale improvements with extensive coordination

### Quality Gates Integration
- **Pre-Improvement**: Baseline metrics and safety validation
- **During Improvement**: Continuous validation and progress monitoring
- **Post-Improvement**: Comprehensive verification and success measurement
- **Regression Prevention**: Ongoing monitoring and alerting

## Output Formats

### Summary Report
```markdown
# Improvement Summary

## 📈 Results Overview
- **Performance**: 45% faster response times (avg 280ms → 154ms)
- **Quality**: Maintainability index improved 68 → 84
- **Security**: 12 vulnerabilities resolved, 0 critical remaining
- **Bundle Size**: 35% reduction (1.2MB → 780KB)

## ✅ Improvements Applied
- Implemented React.memo for expensive components
- Added database query optimization and indexing
- Upgraded dependencies and fixed security vulnerabilities
- Refactored complex functions with >15 cognitive complexity
```

### Detailed Report
```markdown
# Detailed Improvement Analysis

## Performance Improvements
### Response Time Optimization
- **Before**: Average 280ms, 95th percentile 850ms
- **After**: Average 154ms, 95th percentile 420ms
- **Changes**:
  - Database query optimization (-40% query time)
  - Response caching implementation (-25% server load)
  - Bundle splitting and lazy loading (-30% initial load)

### Bundle Size Optimization
- **Before**: 1.2MB initial bundle, 3.4MB total
- **After**: 780KB initial bundle, 2.1MB total
- **Techniques**: Tree shaking, code splitting, dependency audit
```

### Action Plan
```markdown
# Improvement Action Plan

## Phase 1: Quick Wins (Week 1)
- [ ] Fix ESLint warnings and TypeScript errors
- [ ] Implement basic performance optimizations
- [ ] Update dependencies with security patches

## Phase 2: Structural Improvements (Week 2-3)
- [ ] Refactor components with high complexity
- [ ] Implement comprehensive error boundaries
- [ ] Add missing unit tests for critical paths

## Phase 3: Advanced Optimization (Week 4-5)
- [ ] Database query optimization and indexing
- [ ] Advanced caching strategies
- [ ] Performance monitoring and alerting
```

## Quality Gates & Performance
- **Improvement Verification**: 100% of changes validated with before/after metrics
- **Safety Assurance**: Zero regressions in functionality or performance
- **Quality Measurement**: Quantifiable improvements in all targeted areas
- **Performance Target**: Complete improvements within estimated timeline ±20%
- **Success Rate**: 95%+ of improvement targets achieved or exceeded
