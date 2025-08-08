# Context7 MCP Server

## Purpose
Official library documentation, code examples, best practices, and localization standards

## Activation Patterns

**Automatic Activation**:
- External library imports detected in code
- Framework-specific questions or queries
- Scribe persona active for documentation tasks
- Documentation pattern requests

**Manual Activation**:
- Flag: `--c7`, `--context7`

**Smart Detection**:
- Commands detect need for official documentation patterns
- Import/require/from/use statements in code
- Framework keywords (React, Vue, Angular, etc.)
- Library-specific queries

## Flags

**`--c7` / `--context7`**
- Enable Context7 for library documentation lookup
- Auto-activates: External library imports, framework questions
- Detection: import/require/from/use statements, framework keywords
- Workflow: resolve-library-id → get-library-docs → implement

**`--no-context7`**
- Disable Context7 server
- Fallback: WebSearch for documentation, manual implementation
- Performance: 10-30% faster when documentation not needed

## Workflow Process

1. **Library Detection**: Scan imports, dependencies, package.json for library references
2. **ID Resolution**: Use `resolve-library-id` to find Context7-compatible library ID
3. **Documentation Retrieval**: Call `get-library-docs` with specific topic focus
4. **Pattern Extraction**: Extract relevant code patterns and implementation examples
5. **Implementation**: Apply patterns with proper attribution and version compatibility
6. **Validation**: Verify implementation against official documentation
7. **Caching**: Store successful patterns for session reuse

## Integration Points

**Commands**: `build`, `analyze`, `improve`, `design`, `document`, `explain`, `git`

**Thinking Modes**: Works with all thinking flags for documentation-informed analysis

**Other MCP Servers**:
- Sequential: For documentation-informed analysis
- Magic: For UI pattern documentation
- Playwright: For testing patterns from documentation

## Strategic Orchestration

### When to Use Context7
- **Library Integration Projects**: When implementing external libraries or frameworks
- **Framework Migration**: Moving between versions or switching frameworks
- **Documentation-Driven Development**: When official patterns must be followed
- **Team Knowledge Sharing**: Ensuring consistent library usage across team
- **Compliance Requirements**: When adherence to official standards is mandatory

### Cross-Server Coordination
- **With Sequential**: Context7 provides documentation → Sequential analyzes implementation strategy
- **With Magic**: Context7 supplies framework patterns → Magic generates components
- **With Morphllm**: Context7 guides patterns → Morphllm applies transformations
- **With Serena**: Context7 provides external docs → Serena manages internal context
- **With Playwright**: Context7 provides testing patterns → Playwright implements test strategies

### Performance Optimization Patterns
- **Intelligent Caching**: Documentation lookups cached with version-aware invalidation
- **Batch Operations**: Multiple library queries processed in parallel for efficiency
- **Pattern Reuse**: Successful integration patterns stored for session-wide reuse
- **Selective Loading**: Topic-focused documentation retrieval to minimize token usage
- **Fallback Strategies**: WebSearch backup when Context7 unavailable or incomplete

## Use Cases

- **Library Integration**: Getting official patterns for implementing new libraries
- **Framework Patterns**: Accessing React, Vue, Angular best practices
- **API Documentation**: Understanding proper API usage and conventions
- **Security Patterns**: Finding security best practices from official sources
- **Localization**: Accessing multilingual documentation and i18n patterns

## Error Recovery

- **Library not found** → WebSearch alternatives → Manual implementation
- **Documentation timeout** → Use cached knowledge → Limited guidance  
- **Server unavailable** → Graceful degradation → Cached patterns

## Quality Gates Integration

- **Step 1 - Syntax Validation**: Language-specific syntax patterns from official documentation
- **Step 3 - Lint Rules**: Framework-specific linting rules and quality standards  
- **Step 7 - Documentation Patterns**: Documentation completeness validation
