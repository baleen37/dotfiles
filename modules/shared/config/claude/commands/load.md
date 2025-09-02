# /load - Project Context Restoration

**Purpose**: Restore project context, session state, and cross-session memory for seamless development continuity

## Usage

```bash
/load [project-name]             # Load specific project context
/load --recent                   # Load most recent memories  
/load --type checkpoint          # Restore specific checkpoint
/load --fresh                    # Start clean session
/load --analyze                  # Load with comprehensive analysis
```

## Core Features

### **Project Context Restoration**
- **Serena Memory Integration**: Restore all project memories, patterns, and insights
- **Session State Recovery**: TodoWrite status, active tasks, completion tracking
- **Development Context**: Git state, working files, environment configuration
- **Cross-Session Continuity**: Seamless resume of previous work with full context

### **Intelligent Context Loading**
- **Progressive Loading**: Load core context first, detailed memories on demand
- **Context Prioritization**: Recent discoveries and active work patterns prioritized
- **Selective Restoration**: Choose specific context types (memories, todos, git state)
- **Gap Detection**: Identify missing context and suggest recovery options

## Integration Points

### **Serena MCP Integration** (Required)
- `list_memories()`: Discover available project contexts
- `read_memory()`: Restore project state and patterns
- `think_about_collected_information()`: Assess loaded context completeness
- `check_onboarding_performed()`: Validate project initialization state

### **TodoWrite State Restoration**
- Deserialize saved todo states and progress tracking
- Restore exact todo content with status preservation
- Resume task sequences from interruption points
- Validate todo consistency with current project state

### **Environment Context Loading**
- **Git Repository State**: Branch information, uncommitted changes, stash status
- **Working Directory**: File states, recent modifications, active directories
- **Configuration State**: Model settings, permission grants, MCP server status
- **Session Metadata**: Previous session duration, checkpoint timestamps

## Command Behavior

### **Basic Project Loading**
```bash
/load "authentication-system"
```
- Loads project-specific memories and context
- Establishes session context with Serena integration
- Restores TodoWrite state and active tasks
- Prepares development environment for continuation

### **Recent Memory Loading**
```bash
/load --recent
```
- Retrieves most recent cross-session memories
- Focuses on latest discoveries and progress
- Quick context establishment for immediate work
- Filters obsolete or irrelevant historical context

### **Checkpoint Restoration**
```bash
/load --type checkpoint --checkpoint session_123
```
- Restores specific saved checkpoint with full context
- Includes complete session state and environment
- Enables precise restoration to known good states
- Preserves exact working conditions and progress

### **Fresh Session Start**
```bash
/load --fresh
```
- Starts new session without previous context loading
- Clears temporary session state while preserving project memories
- Useful for clean analysis or debugging sessions
- Maintains long-term project knowledge while resetting session

### **Comprehensive Analysis Loading**
```bash
/load /path/to/project --analyze
```
- Loads project with comprehensive context analysis
- Activates deep project understanding and cross-referencing
- Identifies gaps between saved state and current reality
- Provides recommendations for context synchronization

## Advanced Features

### **Context Validation & Repair**
```bash
/load --repair
```
- Identifies gaps and inconsistencies in loaded context
- Suggests missing context restoration options
- Repairs corrupted or incomplete memory states
- Validates cross-session data integrity

### **Selective Context Loading**
```bash
/load --type project --scope architecture
/load --type deps --refresh
```
- Load specific context types (project, config, dependencies, environment)
- Refresh outdated context with current state analysis
- Selective memory restoration for targeted work
- Optimize loading performance for specific use cases

### **Cross-Session Progress Assessment**
```bash
/load project-name && /reflect --scope project
```
- Loads context and immediately assesses current state
- Compares saved progress with current project reality
- Identifies completed, pending, and new work items
- Provides contextual next-step recommendations

## Context Types

### **Project Context**
- Architecture decisions and design patterns
- Implementation progress and milestones
- Key discoveries and learned lessons
- Team coordination and external dependencies

### **Session Context**  
- Active work items and task sequences
- Recent file changes and commit patterns
- Debugging context and issue resolution
- Temporary notes and experimental findings

### **Memory Context**
- Long-term project knowledge and patterns
- Cross-project insights and reusable solutions
- Institutional knowledge and best practices
- Historical context and evolution tracking

## Examples

```bash
# Resume project work
/load "e-commerce-platform"
/reflect --scope project  # Assess current state vs memory

# Quick context refresh
/load --recent
# Continue with latest discoveries and progress

# Restore specific milestone
/load --type checkpoint "payment-integration-complete"

# Clean analysis session
/load --fresh  
/analyze src/ --focus architecture

# Comprehensive project onboarding
/load dotfiles-project --analyze --deep
```

## Recovery & Error Handling

### **Context Recovery**
- **Missing Memories**: Suggest context reconstruction from available data
- **Corrupted State**: Fallback to last known good checkpoint
- **Version Conflicts**: Merge strategies for divergent context
- **Incomplete Loading**: Progressive recovery with user guidance

### **Validation & Verification**
- **State Consistency**: Verify loaded context matches current reality
- **Data Integrity**: Validate memory structure and relationships
- **Performance Monitoring**: Track loading times and optimize context size
- **User Feedback**: Confirm successful context restoration and readiness

The load command transforms Claude Code into a persistent development environment where every session builds upon previous work, creating true project continuity and accumulated intelligence.
