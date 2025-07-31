# /analyze - Multi-Dimensional Analysis & Intelligence

Evidence-based systematic analysis across quality, security, performance, and architecture dimensions with intelligent Wave orchestration.

## Purpose
- **Multi-Dimensional Analysis**: Comprehensive analysis across quality, security, performance, and architecture
- **Evidence-Based Insights**: Data-driven findings with quantifiable metrics and actionable intelligence
- **Wave-Enabled Intelligence**: Auto-activate Wave mode for complex system-wide analysis
- **Root Cause Investigation**: Deep investigation beyond surface-level symptoms with systematic methodology
- **Actionable Recommendations**: Prioritized improvement strategies with clear implementation guidance

## Usage
```bash
/analyze [target] [--focus domain] [--depth level] [--strategy approach]
```

## Arguments & Flags

### Target Specification
- `[target]` - File, directory, or system component to analyze (default: current project)
- `@codebase/` - Full codebase analysis with architectural assessment
- `@security/` - Security-focused analysis across all components
- `@performance/` - Performance analysis with bottleneck identification
- `@component/Button` - Deep component analysis with usage patterns
- `@api/auth` - API module analysis with security and performance focus

### Analysis Focus
- `--focus quality` - Code quality, maintainability, technical debt
- `--focus security` - Vulnerabilities, compliance, threat modeling
- `--focus performance` - Bottlenecks, optimization, scalability
- `--focus architecture` - Design patterns, structure, modularity
- `--focus dependencies` - Dependency analysis, version management, security
- `--focus testing` - Test coverage, quality, strategy effectiveness
- `--focus accessibility` - UI/UX accessibility compliance and usability

### Analysis Depth
- `--depth surface` - Quick scan for obvious issues and patterns
- `--depth standard` - Comprehensive analysis with detailed findings (default)
- `--depth deep` - Architectural analysis with system-wide implications
- `--depth root-cause` - Deep investigation with root cause analysis
- `--depth comprehensive` - Full system analysis with Wave activation
- `--depth quick` - Fast analysis for immediate feedback
- `--depth systematic` - Methodical analysis with structured reporting

### Analysis Strategy
- `--strategy systematic` - Methodical analysis with comprehensive coverage
- `--strategy targeted` - Focus on specific issues or components
- `--strategy comparative` - Compare against benchmarks and best practices
- `--strategy historical` - Include historical trends and technical debt evolution
- `--strategy predictive` - Analyze trends and predict future issues

### Output Configuration
- `--output summary` - Executive summary with key findings
- `--output detailed` - Comprehensive analysis report (default)
- `--output actionable` - Action-focused recommendations with priorities
- `--output metrics` - Quantitative metrics and benchmarks
- `--output roadmap` - Strategic improvement roadmap
- `--format text` - Plain text format (default)
- `--format json` - JSON format for programmatic use
- `--format report` - Structured report format

### Integration Features
- `--create-tasks` - Generate `/task` hierarchy for identified improvements
- `--trigger-improve` - Automatically trigger `/improve` for high-priority issues
- `--update-workflow` - Update project workflows based on findings
- `--benchmark` - Compare against industry standards and best practices

## Auto-Activation Patterns

### Wave Mode Triggers
- **System-Wide Analysis**: >100 files or complex architectural analysis
- **Multi-Dimensional**: Analysis across 3+ focus areas simultaneously
- **Root Cause Investigation**: Deep analysis requiring systematic investigation
- **Enterprise Scale**: Large codebases with >50k lines of code

### Persona Auto-Activation
- **Quality Focus**: → analyzer persona + refactorer persona
- **Security Focus**: → security persona + analyzer persona
- **Performance Focus**: → performance persona + analyzer persona
- **Architecture Focus**: → architect persona + analyzer persona
- **Multi-Focus**: → intelligent persona coordination

### MCP Server Integration
- **Sequential**: Primary for systematic analysis and root cause investigation
- **Context7**: Documentation and best practices lookup for validation
- **Playwright**: Performance measurement and user experience analysis
- **Magic**: UI component analysis and accessibility evaluation

## Analysis Framework

### Phase 1: Discovery & Inventory
1. **Structural Analysis**: Codebase organization, module relationships
2. **Technology Assessment**: Framework versions, dependency analysis
3. **Quality Baseline**: Current metrics and technical debt assessment
4. **Security Posture**: Initial vulnerability and compliance scan
5. **Performance Profile**: Baseline performance characteristics

### Phase 2: Multi-Dimensional Analysis

#### Quality Analysis
```yaml
code_quality:
  complexity: [cyclomatic, cognitive, nesting_depth]
  maintainability: [readability, documentation, consistency]
  technical_debt: [code_smells, duplication, deprecated_patterns]
  test_quality: [coverage, quality, strategy_effectiveness]

metrics:
  maintainability_index: '>70 target'
  cyclomatic_complexity: '<10 per function'
  code_duplication: '<5% overall'
  test_coverage: '>80% unit, >70% integration'
```

#### Security Analysis
```yaml
security_assessment:
  vulnerabilities: [known_cve, custom_analysis, dependency_audit]
  compliance: [owasp_top_10, industry_standards, regulatory]
  threat_modeling: [attack_surface, data_flow, access_control]
  best_practices: [secure_coding, configuration, deployment]

metrics:
  vulnerability_score: 'CVSS scoring'
  compliance_percentage: '>95% target'
  security_debt: 'high/medium/low categorization'
  risk_level: 'critical/high/medium/low'
```

#### Performance Analysis
```yaml
performance_assessment:
  bottlenecks: [cpu_intensive, memory_leaks, io_blocking]
  scalability: [horizontal, vertical, resource_utilization]
  optimization: [algorithmic, caching, database_queries]
  monitoring: [metrics_coverage, alerting, observability]

metrics:
  response_time: '<200ms API, <3s page_load'
  memory_usage: '<100MB baseline'
  cpu_utilization: '<30% average'
  database_performance: '<50ms query_time'
```

#### Architecture Analysis
```yaml
architecture_assessment:
  patterns: [design_patterns, architectural_style, modularity]
  coupling: [component_dependencies, interface_design]
  cohesion: [module_focus, responsibility_clarity]
  evolution: [adaptability, extensibility, maintainability]

metrics:
  coupling_score: 'loose coupling target'
  cohesion_score: 'high cohesion target'
  pattern_consistency: '>90% adherence'
  architectural_debt: 'quantified technical debt'
```

### Phase 3: Root Cause Investigation
1. **Problem Correlation**: Link symptoms to underlying causes
2. **Impact Analysis**: Assess business and technical impact
3. **Dependency Mapping**: Identify interdependencies and cascading effects
4. **Historical Analysis**: Track issue evolution and patterns
5. **Predictive Assessment**: Forecast future issues and risks

### Phase 4: Actionable Intelligence
1. **Priority Matrix**: Risk vs. effort prioritization framework
2. **Implementation Planning**: Detailed improvement strategies
3. **Resource Estimation**: Time, complexity, and skill requirements
4. **Risk Assessment**: Implementation risks and mitigation strategies
5. **Success Metrics**: Measurable outcomes and validation criteria

## Focus-Specific Analysis Patterns

### Quality-Focused Analysis
```yaml
analysis_dimensions:
  - code_complexity: 'Identify overly complex functions and classes'
  - duplication: 'Find and quantify code duplication patterns'
  - maintainability: 'Assess readability and modification ease'
  - testing: 'Evaluate test coverage and quality'
  - documentation: 'Assess documentation completeness and accuracy'
  - conventions: 'Validate coding standards adherence'

deliverables:
  - quality_scorecard: 'Quantified quality metrics'
  - improvement_roadmap: 'Prioritized quality improvements'
  - refactoring_candidates: 'Specific components needing attention'
  - best_practices_guide: 'Project-specific quality guidelines'
```

### Security-Focused Analysis
```yaml
analysis_dimensions:
  - vulnerability_scan: 'Known CVE and custom vulnerability detection'
  - threat_modeling: 'Attack surface and threat vector analysis'
  - compliance_audit: 'Industry standard and regulatory compliance'
  - secure_coding: 'Security best practices adherence'
  - dependency_audit: 'Third-party dependency security assessment'
  - configuration_review: 'Security configuration validation'

deliverables:
  - security_scorecard: 'Risk assessment and vulnerability inventory'
  - remediation_plan: 'Prioritized security improvements'
  - compliance_report: 'Standards adherence and gap analysis'
  - threat_model: 'Comprehensive threat landscape assessment'
```

### Performance-Focused Analysis
```yaml
analysis_dimensions:
  - bottleneck_identification: 'CPU, memory, I/O, and network bottlenecks'
  - algorithmic_analysis: 'Algorithm efficiency and optimization opportunities'
  - resource_utilization: 'Memory, CPU, and storage usage patterns'
  - scalability_assessment: 'Horizontal and vertical scaling readiness'
  - caching_strategy: 'Caching implementation and effectiveness'
  - database_performance: 'Query optimization and indexing analysis'

deliverables:
  - performance_baseline: 'Current performance metrics and benchmarks'
  - optimization_roadmap: 'Prioritized performance improvements'
  - monitoring_strategy: 'Performance monitoring and alerting setup'
  - scalability_plan: 'Growth-ready architecture recommendations'
```

## Integration with SuperClaude Ecosystem

### Command Coordination
- **→ /improve**: Direct handoff of analysis findings for systematic improvement
- **→ /task**: Generate hierarchical task structure for addressing findings
- **← /load**: Import project context for informed analysis
- **↔️ /workflow**: Coordinate with development workflows and requirements
- **→ /spawn**: Trigger complex multi-domain operations based on findings

### Wave System Integration
- **Progressive Analysis**: Multi-phase analysis with increasing depth
- **Systematic Waves**: Methodical analysis across all dimensions
- **Adaptive Waves**: Dynamic analysis strategy based on initial findings
- **Enterprise Waves**: Large-scale analysis with comprehensive coordination

### Quality Gates Integration
- **Analysis Validation**: Verify completeness and accuracy of findings
- **Evidence Requirements**: Quantifiable metrics and reproducible results
- **Recommendation Quality**: Actionable, prioritized, and measurable recommendations
- **Integration Testing**: Validate analysis accuracy through implementation results

## Output Formats

### Executive Summary
```markdown
# Analysis Executive Summary

## 🎯 Overall Health Score: 78/100
- **Quality**: 82/100 (Good - minor technical debt)
- **Security**: 68/100 (Moderate - 8 medium-risk vulnerabilities)
- **Performance**: 85/100 (Good - minor optimization opportunities)
- **Architecture**: 76/100 (Good - some coupling issues)

## 🔴 Critical Issues (Immediate Action Required)
1. **SQL Injection Vulnerability** - User input validation in auth module
2. **Memory Leak** - React component cleanup in dashboard
3. **N+1 Query Problem** - Database queries in user listing

## 🟡 High Priority Improvements (Next 30 Days)
- Implement comprehensive input validation
- Add React cleanup hooks for component unmounting
- Optimize database queries with proper indexing
- Upgrade 12 dependencies with security patches
```

### Detailed Analysis Report
```markdown
# Comprehensive Analysis Report

## Quality Analysis
### Code Complexity Assessment
- **Average Cyclomatic Complexity**: 6.2 (Target: <10) ✅
- **High Complexity Functions**: 8 functions >15 complexity
- **Technical Debt Ratio**: 12% (Industry average: 15%) ✅

#### Complex Functions Requiring Attention
| Function | File | Complexity | Priority |
|----------|------|------------|----------|
| `processUserData` | `src/auth/validator.js` | 23 | High |
| `generateReport` | `src/reports/generator.js` | 18 | Medium |

### Code Duplication Analysis
- **Overall Duplication**: 4.2% (Target: <5%) ✅
- **Largest Duplicated Block**: 45 lines in utility functions
- **Duplication Hotspots**: Form validation, API error handling

## Security Analysis
### Vulnerability Assessment
- **Critical**: 0 vulnerabilities ✅
- **High**: 3 vulnerabilities ⚠️
- **Medium**: 5 vulnerabilities ⚠️
- **Low**: 12 vulnerabilities ℹ️

#### High-Priority Security Issues
1. **SQL Injection** (CVSS: 8.1)
   - **Location**: `src/auth/login.js:42`
   - **Impact**: Database compromise
   - **Fix**: Parameterized queries implementation

2. **XSS Vulnerability** (CVSS: 7.8)
   - **Location**: `src/components/UserProfile.jsx:28`
   - **Impact**: Session hijacking
   - **Fix**: Input sanitization and CSP headers
```

### Actionable Roadmap
```markdown
# Analysis-Driven Improvement Roadmap

## Phase 1: Critical Security Fixes (Week 1)
- [ ] **Priority 1**: Fix SQL injection in authentication module
- [ ] **Priority 1**: Implement XSS protection in user profile component
- [ ] **Priority 2**: Upgrade vulnerable dependencies (express, lodash, axios)
- [ ] **Priority 2**: Add security headers and CSP configuration

**Estimated Effort**: 16 hours | **Risk Reduction**: 85%

## Phase 2: Performance Optimization (Week 2-3)
- [ ] **Priority 1**: Resolve N+1 query issues in user listing
- [ ] **Priority 1**: Fix memory leaks in React dashboard components
- [ ] **Priority 2**: Implement Redis caching for frequently accessed data
- [ ] **Priority 2**: Optimize database queries and add missing indexes

**Estimated Effort**: 32 hours | **Performance Gain**: 40-60%

## Phase 3: Quality Improvements (Week 4-5)
- [ ] **Priority 1**: Refactor high-complexity functions (8 functions)
- [ ] **Priority 2**: Eliminate code duplication in form validation
- [ ] **Priority 2**: Improve test coverage from 72% to 85%
- [ ] **Priority 3**: Update documentation and code comments

**Estimated Effort**: 28 hours | **Maintainability Improvement**: 30%
```

## Tool Integration & Execution Framework

### Allowed Tools & Purpose
- **Read**: Deep code inspection and comprehensive file analysis
- **Grep**: Pattern-based analysis and code searching across codebase
- **Glob**: Systematic file discovery and categorization by type
- **Bash**: Execute analysis tools, run performance measurements, and validation
- **TodoWrite**: Track analysis progress, findings, and recommendation implementation

### Analysis Execution Pattern
1. **Discovery Phase**: Use Glob to identify and categorize target files
2. **Pattern Analysis**: Apply Grep for systematic code pattern detection
3. **Deep Inspection**: Read files for detailed quality, security, and architecture analysis
4. **Validation**: Execute Bash commands for performance testing and validation
5. **Progress Tracking**: Use TodoWrite to manage analysis workflow and findings

### Advanced Integration Features
- **Wave-Enabled**: Auto-activates Wave mode for complex system-wide analysis
- **Complexity Threshold**: 0.7+ complexity triggers enhanced analysis modes
- **Persona Coordination**: Automatically activates analyzer, security, performance, or architect personas
- **MCP Server Integration**: Leverages Sequential for systematic analysis, Context7 for best practices

## Quality Gates & Performance
- **Analysis Completeness**: 100% coverage of specified dimensions
- **Evidence Quality**: All findings supported by quantifiable metrics
- **Actionability**: 95%+ of recommendations include specific implementation guidance
- **Accuracy**: 90%+ of identified issues confirmed through validation
- **Performance Target**: Complete standard analysis within 15 minutes
- **Tool Efficiency**: Sub-5 second file discovery, sub-30 second pattern analysis
