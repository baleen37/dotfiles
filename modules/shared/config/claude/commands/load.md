# /load - Intelligent Context Loading

**Purpose**: Load project files and context into AI for comprehensive understanding and analysis.

## Usage

```bash
/load                    # Load current project
/load [path]             # Load specific path  
/load [pattern]          # Load files matching pattern
```

## What It Does

<details>
<summary><strong>Smart Context Analysis</strong></summary>

Intelligently analyzes and loads project context:

- **File Dependencies**: Understands import/require relationships
- **Recent Changes**: Prioritizes recently modified files
- **Project Structure**: Maps directory hierarchy and key files
- **Semantic Understanding**: Groups related functionality together

</details>

<details>
<summary><strong>Adaptive Loading</strong></summary>

Optimizes loading based on project characteristics:

- **Size Management**: Handles large projects through selective loading
- **Type Recognition**: Identifies and prioritizes source code over generated files  
- **Context Relevance**: Focuses on files most relevant to current work
- **Memory Efficiency**: Balances comprehensive context with performance

</details>

## Common Scenarios

### New Project Analysis
```bash
/load                    # Full project overview
```

### Feature Development  
```bash
/load src/components     # Focus on specific module
/load *.config.*         # Configuration files only
```

### Bug Investigation
```bash
/load src/utils/helper.js    # Specific problematic file
/load tests/ src/utils/      # Tests and related code
```

## Best Practices

- **Progressive Loading**: Start broad, then narrow to specific areas
- **Context Management**: Load only what's needed for current task  
- **Performance Consideration**: Exclude build outputs and large binaries
- **Workflow Integration**: Use with other commands for comprehensive analysis

## Troubleshooting

### Loading Takes Too Long
- **Cause**: Large project with many files
- **Solution**: Use specific paths or patterns to limit scope

### Memory Issues
- **Cause**: Too many files loaded at once  
- **Solution**: Load incrementally by directory or file type

### Missing Expected Files
- **Cause**: Files excluded by ignore patterns
- **Solution**: Check .gitignore and specify explicit paths if needed

## Integration

Works seamlessly with other commands:
- `/analyze` for loaded context analysis
- `/implement` using loaded project understanding
- `/debug` with full context awareness

The command provides foundation for all AI-assisted development tasks by ensuring comprehensive project understanding.
