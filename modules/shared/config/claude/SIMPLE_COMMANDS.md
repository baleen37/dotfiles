# Claude Core Commands (9 commands)

## /analyze [target]
**Purpose**: Code/system analysis
- Auto MCP: Context7, Sequential integration
- Output: Comprehensive quality, security, performance analysis

```bash
/analyze                    # Full project analysis
/analyze src/components     # Specific directory analysis
```

## 🧠 Deep Thinking & Sequential Analysis

### thinkhard mode
**Complex problem solving with Sequential thinking activation**
- Multi-step reasoning for root cause analysis
- System-wide context problem identification
- Step-by-step validation for accurate diagnosis
- Generate actionable solutions

### Auto MCP Server Selection
- **Sequential**: Complex logical analysis, multi-step reasoning needed
- **Context7**: Library/framework pattern analysis needed
- **Task**: Domain expert analysis needed (security, performance, Nix, etc)

### Auto Routing Conditions

- **Complex bugs**: Sequential MCP for step-by-step analysis
- **Architecture issues**: Sequential + Task(general-purpose) combination
- **Security issues**: Task(security-auditor) priority delegation
- **Performance issues**: Task(performance-engineer) + Sequential combination
- **Nix config**: Task(nix-system-expert) immediate delegation

## Analysis Domains

### 📊 Quality Analysis
- Code complexity, maintainability, technical debt

### 🛡️ Security Analysis
- Vulnerability assessment, security best practices

### ⚡ Performance Analysis
- Bottleneck identification, resource optimization

### 🏗️ Architecture Analysis
- Design patterns, coupling/cohesion evaluation

## Output Format

### Analysis Results
- **Core Issues**: Most critical problems summary
- **Detailed Analysis**: Present with evidence
- **Improvement Plan**: Concrete and actionable solutions

### Command Linkage
- **→ /improve**: Execute improvements based on analysis results
- **→ /implement**: Implement recommended solutions
- **→ /debug**: Debug discovered issues

## Examples

### Basic Usage
```bash
/analyze                          # Full project analysis
/analyze src/auth.js             # Specific file analysis
/analyze api/                    # Directory analysis
```

### Advanced Analysis
```bash
/analyze --think                 # Sequential MCP logical analysis
/analyze auth.js thinkhard       # Complex auth logic deep thinking
/analyze . --deep                # Full system comprehensive analysis
```

### Domain Specific
```bash
/analyze @security               # Security-focused analysis
/analyze @performance            # Performance-focused analysis
```

## /implement "feature description"
**Purpose**: New feature implementation with intelligent automation
- Auto technology stack detection and pattern application
- MCP integration: Magic(UI), Context7(patterns), Sequential(complex logic)
- Quality assurance: Security validation, test recommendations, error handling

```bash
/implement "user authentication"        # Auto apply auth patterns
/implement "API endpoint"               # Auto generate RESTful patterns
```

### 🎯 Auto Feature Detection

#### Implementation Type Auto Classification
- **Component**: React/Vue components → Magic MCP utilization
- **API**: REST/GraphQL endpoints → Context7 pattern application
- **Service**: Business logic modules → Sequential complex logic
- **Feature**: Complete features → Multi-MCP combination

#### Framework Auto Recognition
- **Frontend**: React, Vue, Angular pattern auto-application
- **Backend**: Express, FastAPI, Django structure following
- **Database**: ORM, SQL query optimization
- **Testing**: Extend existing test frameworks

### Quality Auto Assurance
- **Security-First**: Auth/permission auto validation
- **Error Handling**: Exception handling pattern auto-application
- **Type Safety**: TypeScript/type hint auto generation
- **Performance**: Optimization patterns default application

### Usage Examples
```bash
/implement "user dashboard component"  # Magic MCP UI generation
/implement "payment API endpoint"      # Context7 security pattern application
/implement "file upload feature"       # Sequential complex logic handling
```

## /improve [target]
**Purpose**: 3-stage systematic code improvement
- **Stage 1**: Performance optimization (bottlenecks, memory, speed)
- **Stage 2**: Security enhancement (vulnerabilities, permissions, encryption)
- **Stage 3**: Quality improvement (readability, maintainability, tests)

```bash
/improve auth.js            # Auth logic comprehensive improvement
/improve database/          # DB layer optimization
```

### 🔄 3-Stage Improvement Process

#### 1️⃣ Performance Optimization Priority
- **Task(performance-engineer)** auto activation
- Bottleneck identification and algorithm optimization
- Memory usage optimization
- Caching strategy application
- Build time reduction (Nix/dotfiles specialized)

#### 2️⃣ Security Enhancement
- **Task(security-auditor)** auto activation
- Vulnerability scan and patches
- Auth/permission validation strengthening
- Input validation and sanitization
- Security best practices application

#### 3️⃣ Quality Improvement
- **Task(code-reviewer)** auto activation
- Code complexity reduction
- Readability and documentation improvement
- Test coverage expansion
- Type safety strengthening

### 🛡️ Safe Refactoring
- **Risk Auto Assessment**: Change scope and impact analysis
- **Incremental Improvement**: Apply safely in small units
- **Test Priority**: Protect existing functionality while improving
- **Rollback Ready**: Instant recovery if issues occur

### Measurable Improvements
- **Before/After Metrics**: Performance, security, quality indicators
- **Specific Numbers**: Build time, memory usage, complexity
- **Benchmarks**: Quantitative measurement of improvement effects

### Domain Specialized Improvements
```bash
/improve @nix               # Nix build optimization specialized
/improve @dotfiles          # dotfiles performance tuning
/improve @security          # Security-focused improvement
/improve @performance       # Performance-focused optimization
```

## /test [target]
**Purpose**: Test pyramid implementation with E2E automation
- **Test Pyramid**: Unit → Integration → E2E strategy
- **Framework Auto Detection**: Utilize existing test tools
- **Playwright Integration**: E2E test auto generation
- **Performance Testing**: Build optimization and benchmarks

```bash
/test login.js              # Unit + integration tests
/test --e2e                 # E2E test auto generation
```

### 🏗️ Test Pyramid Strategy

#### 📝 Unit Tests (Foundation)
- **Fast Feedback**: Individual function/module validation
- **High Coverage**: 100% coverage of core logic
- **Auto Generation**: Generate test cases based on existing code
- **TDD Support**: Test-first development workflow

#### 🔗 Integration Tests (Middle)
- **Module Interaction**: API, DB, service integration tests
- **Real Environment**: Dev/staging environment simulation
- **Data Flow**: Complete data pipeline validation
- **Performance Validation**: Response time, throughput measurement

#### 🎭 E2E Tests (Top)
- **Playwright Auto Integration**: Browser automation tests
- **User Scenarios**: Real user journey simulation
- **Cross Browser**: Chrome, Firefox, Safari simultaneous testing
- **Visual Regression**: Screenshot-based UI validation

### 🎯 Auto Test Strategy

#### Framework Auto Detection
- **JavaScript**: Jest, Vitest, Mocha auto recognition
- **Python**: pytest, unittest pattern application
- **Nix**: Build tests and flake validation
- **dotfiles**: Config integrity and compatibility tests

#### Auto Test Generation
- **Per Function**: Input/output based test cases
- **Per API**: Request/response validation tests
- **Per Component**: Rendering and interaction tests
- **Per E2E**: User scenario based auto scripts

### 🚀 Performance and Benchmark Testing
- **Build Performance**: Nix build time measurement and optimization
- **Memory Usage**: Resource usage monitoring
- **Load Testing**: High load situation simulation
- **Regression Testing**: Auto detect performance degradation

### Real Usage Examples
```bash
/test auth.js               # Auth logic unit tests
/test api/users             # User API integration tests
/test --e2e login-flow      # Login E2E auto generation
/test --performance         # Performance benchmark execution
/test @nix                  # Nix build test specialized
```

### CI/CD Integration
- **Auto Execution**: Auto test execution on commit/PR
- **Parallel Processing**: Test suite parallel execution for time reduction
- **Result Reporting**: Detailed test results and coverage reports
- **Failure Analysis**: Auto analysis of failure causes and improvement suggestions

## /git [operation]
**Purpose**: Smart Git workflow automation
- **AI Commit Messages**: Analyze changes to generate meaningful commit messages
- **Branch Management**: Auto branch naming and strategy application
- **Conflict Resolution**: Merge conflict auto analysis and resolution suggestions
- **Workflow Optimization**: Git status analysis with next action recommendations

```bash
/git commit                 # AI-generated commit message smart commit
/git branch feature-auth    # Branch creation + naming convention application
/git status                 # Current status + recommended next actions
/git merge --smart          # Intelligent merge and conflict resolution
```

### 🎯 Git Automation Features
- **Commit Message Generation**: Analyze code changes → generate meaningful commit messages
- **Branch Strategy**: Auto-detect via CONTRIBUTING.md → .github/CONTRIBUTING.md → Git standard fallback
- **Status Analysis**: Current Git state → suggest optimal next actions
- **Conflict Resolution**: Merge conflict analysis and resolution suggestions
- **Workflow Patterns**: Auto-apply GitFlow, GitHub Flow patterns

## /cleanup [target]
**Purpose**: System and code cleanup automation
- **Universal Cleanup**: Project cache, logs, temp files cleanup
- **Config Cleanup**: Remove unused config files
- **Code Cleanup**: Dead code, duplicate code, unused import cleanup
- **Safe Cleanup**: Risk assessment then staged cleanup

```bash
/cleanup cache              # Project cache and temp files cleanup
/cleanup config             # Unused config files cleanup
/cleanup code src/          # Source code dead code removal
/cleanup --dry-run          # Cleanup preview (no execution)
```

### 🧹 Cleanup Automation Features
- **Universal Cleanup**: Project temp files, log files, cache files cleanup
- **Config Cleanup**: Backup files, duplicate configs, unused config files
- **Code Cleanup**: AST analysis for dead code, unused functions/variables detection
- **Safety Mode**: Risk assessment → auto-execute only safe cleanup operations
- **Recovery Ready**: Pre-cleanup backup → instant recovery if issues occur

## /workflow [description]
**Purpose**: Implementation workflow generation and task planning
- **Sequential MCP**: Analyze and plan complex features step-by-step
- **Task Breakdown**: Split large tasks into executable units
- **Dependency Analysis**: Auto analyze task dependencies and order
- **Parallelization Identification**: Identify concurrent executable task groups

```bash
/workflow "user auth system implementation"    # Complete feature implementation plan
/workflow "API performance optimization"          # Optimization task step-by-step plan
/workflow "Nix config migration"     # Migration workflow
```

### 📋 Workflow Generation Features
- **Requirements Analysis**: Feature description → extract detailed requirements
- **Task Breakdown**: Complex features → split into executable task units
- **Dependency Mapping**: Inter-task dependencies → derive optimal execution order
- **Resource Planning**: Predict required tech, tools, and time estimates
- **Parallel Execution**: Identify independent tasks → concurrent execution groups

## /document [target]
**Purpose**: Customized documentation auto generation
- **Code Documentation**: Function, class, API auto documentation
- **Usage Guides**: Tool, config usage auto generation
- **Architecture Docs**: System structure analysis → auto document generation
- **README Generation**: Project analysis → complete README writing

```bash
/document api/auth.js       # API documentation auto generation
/document README            # README.md auto writing
/document --type guide      # Usage guide generation
/document architecture      # Architecture documentation generation
```

### 📚 Documentation Automation Features
- **Code Analysis**: AST parsing → extract function signatures, class structures
- **Usage Extraction**: Code pattern analysis → generate real usage examples
- **Multi-language Support**: Korean comments → English docs, English code → Korean explanations
- **Template Application**: Auto-select documentation templates by project type
- **Link Management**: Auto-generate internal references and external dependency links

## Automation Features
- **MCP Servers**: Keyword-based auto selection
- **Think Flags**: Complexity detection auto activation
- **Expert Agents**: Auto call when needed
- **Rule #1 Guarantee**: Risk operations require approval
