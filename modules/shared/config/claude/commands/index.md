# /index - Intelligent Command Discovery & Navigation

Navigate and discover commands intelligently with contextual recommendations and smart search capabilities.

## Purpose
- **Intelligent Discovery**: Smart command search with contextual recommendations
- **Usage Analytics**: Track command effectiveness and user patterns
- **Contextual Help**: Situation-aware command suggestions
- **Learning System**: Adaptive recommendations based on usage patterns
- **Cross-Reference**: Understand command relationships and workflows

## Usage
```bash
/index [query] [--suggest] [--context domain] [--learn] [--export format]
```

## Arguments & Flags

### Query & Search  
- `[query]` - Search term, command name, or task description
- `"workflow automation"` - Find commands related to workflow automation
- `"debug performance"` - Contextual search for debugging and performance
- `"security audit"` - Security-related command discovery
- `@recent` - Recently used commands with effectiveness ratings

### Smart Suggestions
- `--suggest` - Get contextual command recommendations for current project
- `--context frontend` - Frontend development context recommendations  
- `--context backend` - Backend/API development context recommendations
- `--context security` - Security-focused command suggestions
- `--context performance` - Performance optimization command suggestions
- `--context testing` - Testing and quality assurance commands

### Learning & Analytics
- `--learn` - Enable usage pattern learning for personalized recommendations
- `--analytics` - Show command usage statistics and effectiveness metrics
- `--patterns` - Display common command combinations and workflows
- `--optimize` - Suggest command workflow optimizations based on usage

### Export & Integration
- `--export markdown` - Export command catalog as structured markdown
- `--export json` - Export command metadata for tooling integration
- `--export cheatsheet` - Generate quick reference cheat sheet

## Command Categories

### Development Workflow
- **workflow** - PRD-based implementation planning
- **implement** - Feature and code implementation
- **improve** - Code quality and performance enhancement
- **analyze** - Multi-dimensional code analysis

### Project Management
- **task** - Hierarchical task management (Epic→Story→Task)
- **spawn** - Meta-orchestration for complex operations
- **load** - Project context loading and pattern recognition

### Quality & Debugging
- **troubleshoot** - Systematic problem diagnosis
- **explain** - Educational code explanations
- **build** - Build process management
- **test** - Testing workflow automation

### Documentation & Communication
- **document** - Documentation generation
- **commit** - Git commit message generation
- **create-pr** - Pull request creation

### Advanced Operations
- **cleanup** - Codebase cleanup and maintenance
- **design** - System design and architecture
- **estimate** - Project estimation and planning

## Smart Recommendations

### By Project Context
**React/Frontend Projects**:
- Primary: implement, improve, analyze, troubleshoot
- Secondary: build, test, document
- Workflows: workflow → implement → improve → test

**API/Backend Projects**:
- Primary: implement, analyze, improve, troubleshoot  
- Secondary: load, spawn, test
- Workflows: analyze → implement → test → improve

**Legacy Modernization**:
- Primary: analyze, improve, cleanup, load
- Secondary: troubleshoot, implement, document
- Workflows: load → analyze → improve → cleanup

### By Task Type
**New Feature Development**:
1. `/workflow` - Generate implementation plan
2. `/task` - Create hierarchical task structure  
3. `/implement` - Build feature components
4. `/test` - Validate functionality
5. `/improve` - Optimize and refine

**Bug Investigation**:
1. `/troubleshoot` - Systematic diagnosis
2. `/analyze` - Deep code analysis
3. `/explain` - Understand complex logic
4. `/implement` - Apply fixes
5. `/test` - Verify resolution

**Code Quality Improvement**:
1. `/analyze` - Assess current quality
2. `/improve` - Apply enhancements
3. `/cleanup` - Remove technical debt
4. `/test` - Ensure stability
5. `/document` - Update documentation

## Usage Analytics

### Command Effectiveness Tracking
- **Success Rate**: Percentage of successful command executions
- **Time to Resolution**: Average time from command to solution
- **Follow-up Patterns**: Common command sequences
- **User Satisfaction**: Subjective effectiveness ratings

### Learning Patterns
- **Contextual Usage**: Commands used in specific project types
- **Seasonal Patterns**: Command usage by development phase
- **Skill Development**: Command complexity progression over time
- **Team Patterns**: Collaborative command usage in team environments

### Optimization Suggestions
- **Workflow Shortcuts**: Suggest command combinations for common tasks
- **Flag Optimization**: Recommend optimal flag combinations
- **Context Switching**: Suggest context-aware command transitions
- **Efficiency Improvements**: Identify slower command patterns

## Integration Features

### Cross-Command Intelligence
- **Workflow Continuity**: Maintain context across command transitions  
- **Result Pipeline**: Pass results between related commands
- **State Persistence**: Remember user preferences and patterns
- **Error Recovery**: Suggest recovery commands when operations fail

### External Integration
- **IDE Integration**: Export command shortcuts for development environments
- **Documentation Sync**: Keep command docs synchronized with implementation
- **Team Sharing**: Share command patterns and workflows across teams
- **Metrics Dashboard**: Visual analytics for command usage and effectiveness
