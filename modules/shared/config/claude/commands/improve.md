# /improve - Systematic Code Improvement

**Purpose**: Apply systematic improvements to code quality, performance, maintainability, and security with intelligent analysis and safe execution.

## Usage

```bash
/improve                              # Full codebase improvement
/improve [target]                     # Targeted improvement
/improve [target] --type quality      # Quality-focused improvements
/improve [target] --type performance  # Performance optimizations
/improve [target] --type maintainability # Maintainability enhancements
/improve [target] --type style        # Style and formatting fixes
/improve [target] --type security     # Security vulnerability fixes
/improve [target] --safe              # Apply only safe, validated changes
/improve [target] --interactive       # Interactive guidance for complex improvements
/improve [target] --thinkhard         # Deep analysis with comprehensive recommendations
```

## What It Does

<details>
<summary><strong>Systematic 5-Stage Improvement Process</strong></summary>

1. **Analyze**: Deep codebase analysis identifying improvement opportunities
2. **Plan**: Strategic improvement approach with risk assessment
3. **Execute**: Safe implementation of improvements with validation
4. **Validate**: Comprehensive testing and verification of changes
5. **Document**: Clear documentation of improvements and recommendations

</details>

<details>
<summary><strong>Multi-Type Improvements</strong></summary>

- **Quality**: Reduce technical debt, enhance readability, improve code structure
- **Performance**: Identify bottlenecks, optimize algorithms, reduce resource usage
- **Maintainability**: Simplify complexity, improve modularity, enhance testability
- **Style**: Apply consistent formatting, naming conventions, code organization
- **Security**: Identify vulnerabilities, apply security best practices, sanitize inputs

</details>

<details>
<summary><strong>Intelligent Safety Features</strong></summary>

- **Safe Mode**: Only applies changes with high confidence and low risk
- **Interactive Mode**: Provides guided improvements for complex scenarios
- **Rollback Capability**: Maintains change history for easy rollback
- **Validation Pipeline**: Runs tests and checks before finalizing changes
- **Risk Assessment**: Evaluates potential impact of each improvement

</details>

<details>
<summary><strong>Deep Analysis with ThinkHard</strong></summary>

When using `--thinkhard`, the tool performs:

- **Architectural Analysis**: System design patterns, coupling analysis, dependency evaluation  
- **Performance Profiling**: Memory usage patterns, execution bottlenecks, optimization opportunities
- **Security Audit**: Vulnerability scanning, attack surface analysis, security best practices
- **Technical Debt Assessment**: Code complexity metrics, maintainability scoring, refactoring priorities
- **Best Practices Compliance**: Framework conventions, industry standards, modern patterns

</details>

## MCP Integration

- **Sequential**: Multi-step improvement planning and systematic execution
- **Context7**: Framework-specific best practices and migration guidance

## Agent Routing

- **system-architect**: Architectural improvements, design pattern optimization
- **backend-engineer**: Performance optimization, database improvements, API enhancements  
- **code-reviewer**: Quality improvements, security enhancements, best practices
- **test-automator**: Test coverage improvements, testing strategy enhancement

## Examples

```bash
/improve src/api --type performance --safe
# Safely optimize API performance with validated changes

/improve components/ --type quality --interactive  
# Interactive quality improvements with guidance

/improve --type security --thinkhard
# Comprehensive security analysis and improvements

/improve legacy-module.js --safe
# Safe refactoring of legacy code with rollback capability
```

## Safety Guarantees

- **Non-Destructive**: All changes are validated and can be rolled back
- **Test Integration**: Runs existing tests before and after improvements
- **Incremental**: Applies changes step-by-step with validation checkpoints
- **Documentation**: Maintains clear record of all improvements made
- **Risk-Aware**: Assesses and communicates potential impact of changes

The improve command transforms code systematically while maintaining stability and providing clear visibility into all changes made.
