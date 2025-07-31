# /task - Hierarchical Project Task Management

Persistent task management system with Epic→Story→Task hierarchy and cross-session persistence.

## Purpose
- **Hierarchical Structure**: Epic → Story → Task with dependency management
- **Cross-Session Persistence**: Tasks survive session restarts and maintain state
- **Workflow Integration**: Bridge between `/workflow` PRD analysis and `/spawn` execution
- **Progress Tracking**: Comprehensive status tracking and completion metrics
- **Dependency Management**: Intelligent dependency resolution and blocking prevention

## Usage
```bash
/task [operation] [target] [--flags]
```

## Operations

### Task Creation
```bash
/task create "Epic: User Authentication System" --type epic --priority high
/task create "Story: User Registration" --parent "Epic: User Authentication System" --type story
/task create "Implement registration API" --parent "Story: User Registration" --estimate 8h
```

### Task Management
```bash
/task list [--filter active|completed|blocked] [--parent epic-id]
/task show [task-id] [--detail]
/task update [task-id] --status in_progress|completed|blocked
/task dependency [task-id] --requires [dependency-id] --blocks [dependent-id]
```

### Workflow Integration
```bash
/task import @workflow-output.md --strategy systematic|agile|mvp
/task export [epic-id] --format roadmap|tasks|detailed
/task sync --todoist|github|linear
```

## Task Hierarchy

### Epic Level (Project Features)
- **Scope**: Large feature sets or major project components
- **Duration**: Weeks to months
- **Examples**: "User Authentication System", "Payment Processing", "Admin Dashboard"
- **Properties**: Business value, acceptance criteria, success metrics

### Story Level (User Stories)
- **Scope**: Specific user functionality within an Epic
- **Duration**: Days to weeks  
- **Examples**: "User Registration", "Password Reset", "Social Login"
- **Properties**: User personas, acceptance criteria, UI/UX requirements

### Task Level (Implementation Units)
- **Scope**: Specific development work items
- **Duration**: Hours to days
- **Examples**: "Create registration form", "Implement API endpoint", "Write unit tests"
- **Properties**: Technical specifications, time estimates, dependencies

## Arguments & Flags

### Task Properties
- `--type epic|story|task` - Task hierarchy level
- `--priority critical|high|medium|low` - Task priority level
- `--status planned|active|in_progress|blocked|completed|cancelled` - Current status
- `--estimate [time]` - Time estimate (e.g., "8h", "3d", "2w")
- `--parent [parent-id]` - Parent task in hierarchy
- `--assignee [name]` - Task assignee
- `--labels [tag1,tag2]` - Categorization labels

### Dependency Management
- `--requires [task-ids]` - Dependencies that must complete first
- `--blocks [task-ids]` - Tasks that depend on this completion
- `--related [task-ids]` - Related tasks for reference
- `--milestone [name]` - Project milestone association

### Filtering & Display
- `--filter [status|priority|assignee|label]` - Filter criteria
- `--sort [created|updated|priority|estimate]` - Sort order
- `--detail` - Show comprehensive task information
- `--tree` - Display hierarchical tree view
- `--timeline` - Show tasks in chronological order

### Integration Features
- `--link-pr [pr-url]` - Link task to pull request
- `--link-issue [issue-url]` - Link task to GitHub/Linear issue
- `--auto-close` - Auto-complete when linked PR/issue closes
- `--notification [slack|email]` - Progress notifications

## Auto-Activation Patterns
- **Workflow Import**: Automatically triggered by `/workflow` completion
- **Complex Projects**: Multi-session work requiring task breakdown
- **Team Collaboration**: Multiple assignees or external integrations
- **Wave Integration**: Large-scale operations with systematic execution

## Task States & Transitions

### State Definitions
```yaml
planned: "Defined but not yet started"
active: "Ready to begin work, dependencies satisfied"
in_progress: "Currently being worked on"
blocked: "Cannot proceed due to dependencies or issues"
completed: "Successfully finished with validation"
cancelled: "No longer needed or deprioritized"
```

### Valid Transitions
```
planned → active → in_progress → completed
planned → cancelled
active → blocked → active
in_progress → blocked → active
any_state → cancelled
```

## Integration with SuperClaude Ecosystem

### TodoWrite Bridge
- Convert session TodoWrite tasks into persistent task hierarchy
- Automatically promote recurring todos to Stories or Epics
- Sync session progress with long-term task status

### Workflow Command Integration
- Import `/workflow` PRD analysis as Epic/Story structure
- Maintain traceability from requirements to implementation
- Export task hierarchy back to workflow documentation

### Spawn Command Coordination
- Break down complex `/spawn` operations into trackable tasks
- Maintain execution context across multi-session workflows
- Coordinate parallel task execution with dependency awareness

### Wave System Integration
- Automatic Wave activation for Epic-level complexity
- Progressive task execution across Wave phases
- Quality gates and validation at Story completion

### Persona Integration
- **Architect**: Epic-level planning and dependency analysis
- **Analyzer**: Task breakdown and complexity assessment
- **QA**: Acceptance criteria and validation planning
- **Scribe**: Documentation and progress reporting

### MCP Server Integration
- **Sequential**: Complex task breakdown and dependency analysis
- **Context7**: Best practices for task estimation and planning
- **Magic**: UI task templates and component planning

## Output Formats

### Tree View (`--tree`)
```
📋 Epic: User Authentication System (active)
├── 📖 Story: User Registration (in_progress)
│   ├── ✅ Task: Design registration form UI
│   ├── 🔄 Task: Implement registration API
│   └── ⏳ Task: Add email verification
├── 📖 Story: User Login (planned)
│   ├── ⏳ Task: Create login form
│   └── ⏳ Task: Implement authentication middleware
└── 📖 Story: Password Reset (planned)
    └── ⏳ Task: Design password reset flow
```

### Timeline View (`--timeline`)
```
🗓️ Week 1-2: Foundation Phase
  🔄 Epic: Project Setup (in_progress)
  ⏳ Story: Development Environment (active)

🗓️ Week 3-4: Core Development  
  ⏳ Epic: User Authentication System (planned)
  ⏳ Story: User Registration (planned)
```

### Detailed View (`--detail`)
```
📋 Epic: User Authentication System
┌─ Status: active | Priority: high | Progress: 2/7 tasks
├─ Estimate: 3 weeks | Assignee: team-auth
├─ Dependencies: Database schema, Security review
├─ Acceptance Criteria:
│  • Users can register with email/password
│  • Secure password requirements enforced
│  • Email verification workflow functional
└─ Progress: 28% complete (2 of 7 tasks done)
```

## Quality Gates & Performance
- **Data Persistence**: Tasks survive system restarts and maintain full context
- **Dependency Validation**: Automatic cycle detection and resolution suggestions
- **Progress Accuracy**: Real-time status updates with validation
- **Performance Target**: <2s response time for complex hierarchy operations
- **Integration Reliability**: 99%+ sync accuracy with external systems

## Key Differences from Other Commands
- **vs /spawn**: Long-term persistence vs immediate execution
- **vs TodoWrite**: Cross-session vs session-specific
- **vs /workflow**: Task execution vs planning and analysis
- **vs /build**: Project management vs code compilation
