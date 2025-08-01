# MCP Server Auto-Execution System

Intelligent system that automatically activates MCP (Model Context Protocol) servers based on user requests.

## Auto-Execution Mechanism

### Keyword-Based Auto-Activation

#### Magic Server Auto-Execution
**Trigger Keywords**: UI, component, design, button, form, logo, /ui, /logo
```
"Create login form component" → Magic server auto-execution
"Add GitHub logo" → Magic server auto-execution  
"Design responsive navigation bar" → Magic server auto-execution
```

#### Context7 Server Auto-Execution
**Trigger Keywords**: API, library, documentation, framework, version, migration
```
"Show me Next.js latest version usage" → Context7 server auto-execution
"Find React Query implementation patterns" → Context7 server auto-execution
"Search TypeScript type definition methods" → Context7 server auto-execution
```

#### Sequential Server Auto-Execution  
**Trigger Keywords**: analysis, planning, design, step-by-step, strategy, architecture
```
"Analyze this error step by step" → Sequential server auto-execution
"Establish microservice architecture design strategy" → Sequential server auto-execution
"Plan legacy code refactoring" → Sequential server auto-execution
```

#### Playwright Server Auto-Execution
**Trigger Keywords**: test, E2E, browser, screenshot, automation
```
"Write E2E test for login flow" → Playwright server auto-execution
"Take screenshot of this page" → Playwright server auto-execution
"Create browser automation script" → Playwright server auto-execution
```

### Multi-Server Auto-Collaboration

#### Sequential Server Chain
```
"Implement new payment system"
↓
1. Context7: Payment library research → Auto-execution
2. Sequential: Implementation strategy setup → Auto-execution  
3. Magic: Payment UI component creation → Auto-execution
4. Playwright: Payment flow testing → Auto-execution
```

#### Parallel Server Execution
```
"Create completely new user dashboard"
↓
Simultaneous execution:
- Context7: Dashboard library pattern search
- Magic: Dashboard UI component creation
- Sequential: Data flow architecture design
```

#### Fallback System
- **Primary server failure** → Auto-switch to similar function server
- **Context7 failure** → Document search via WebSearch
- **Magic failure** → Manual component code generation
- **Sequential failure** → Basic step-by-step analysis provision

## Intelligent Server Selection Algorithm

### Context Analysis-Based Auto-Selection

#### Project Type Detection
- **Frontend-focused**: React components → Magic server priority
- **Backend-focused**: API/DB models → Context7 server priority  
- **Test-focused**: E2E files → Playwright server priority
- **Analysis needed**: Unclear → Sequential server priority

#### Task Complexity-Based Server Combination
- **Simple**: Single server only
- **Moderate**: Primary/secondary server 2-combo
- **Complex**: Full server chain utilization

*Detailed selection algorithm referenced in @ORCHESTRATION.md*

### Auto-Detection Criteria for Complexity
**Simple Tasks (Single Server)**:
- 1 keyword, clear single purpose
- Example: "Add GitHub logo" → Magic only
- Example: "Find Next.js docs" → Context7 only

**Moderate Tasks (2-3 Servers)**:
- 2-3 keywords, multiple steps expected
- Example: "Implement login API" → Context7 + Sequential
- Example: "Create dashboard component" → Context7 + Magic

**Complex Tasks (Full Server Chain)**:
- 4+ keywords, includes "system", "architecture", "entire"
- Example: "Design entire authentication system" → 4 servers sequential
- Example: "Build payment platform" → 4 servers collaborative

### Auto-Execution Conditions

#### Immediate Execution (0-second delay)
- Clear keyword matching ("UI component", "API documentation")
- Tasks solvable with single server
- Requests identical to previously successful patterns

#### Delayed Execution (1-2 seconds later)
- After context analysis of ambiguous requests
- Complex tasks requiring multi-server collaboration
- Large-scale changes that may require user confirmation

## Auto-Optimization System

### Learning-Based Server Selection
Learns from past success patterns to automatically predict and select optimal servers for each request type.

### Performance Monitoring and Auto-Adjustment
- **Response Time Tracking**: Monitor average response time for each server
- **Success Rate Analysis**: Statistics on task success rates by server
- **Load Balancing**: Automatically utilize alternative servers when overload is detected
- **Cache Utilization**: Cache results of frequently requested patterns

### Real-Time Performance Metrics
```
Current server status (example):
- Context7: Average 3.2s, Success rate 94%, Status: Normal
- Sequential: Average 8.1s, Success rate 89%, Status: Normal  
- Magic: Average 2.8s, Success rate 96%, Status: Optimal
- Playwright: Average 12.3s, Success rate 87%, Status: Caution
```

### Intelligent Fallback Chain
**When Context7 server fails**:
1. Alternative document search via WebSearch
2. Utilize cached similar patterns
3. Provide manual implementation guide

**When Sequential server fails**:
1. Switch to basic step-by-step analysis
2. Suggest simplified approach
3. Request user manual breakdown

**When Magic server fails**:
1. Provide basic component templates
2. Manual code generation guide
3. Reference existing components

**When Playwright server fails**:
1. Provide manual test scenarios
2. Basic E2E template guidance
3. Present test strategy guide

### User-Personalized Optimization
jito preference learning: Sequential (detailed analysis), Magic (React work), Playwright (test workflow) auto-activation

## Auto-Workflow Patterns

### Smart Feature Development Workflow
```
User: "Create user profile editing functionality"
↓ (Auto-detect: New feature + UI + API)
↓
Auto-execution sequence:
1. Context7 (0s): Search React form library patterns
2. Magic (simultaneous): Generate profile editing UI component
3. Sequential (1s later): API design and data flow planning
4. Playwright (final): Create editing flow E2E tests
```

### Intelligent Debugging Workflow
```
User: "Login fails intermittently"
↓ (Auto-detect: Bug + intermittent = complex analysis needed)
↓
Auto-execution:
1. Sequential (immediate): Step-by-step problem situation analysis
2. Context7 (parallel): Search similar authentication issue patterns
3. Playwright (conditional): Generate automated tests if reproducible
```

### Adaptive Code Review Workflow
```
User: "Review this component code"
↓ (Auto-detect: React component file)
↓
Auto-execution:
1. Context7: Check React best practices and anti-patterns
2. Sequential: Logic complexity analysis (activate if complex)
3. Magic: UI improvement suggestions (if design issues detected)
```

### Silent vs Notification Execution

#### Silent Auto-Execution (Background)
- Clear single-server tasks
- Requests identical to previous success patterns
- Quick information retrieval (Context7)

#### Notification Auto-Execution (User Guidance)
```
🤖 "Generating UI component with Magic server and finding related documentation in Context7..."
🤖 "Sequential server is analyzing implementation strategy..."
🤖 "Integrating results from 3 servers to prepare final response."
```

## User Control Options

### Disable MCP Auto-Execution
```
"Turn off MCP auto-execution and handle directly"
"Answer in basic mode without servers"
"Write code directly without Magic server"
```

### Force Specific Server Execution
```
"Find React 18 documentation using Context7"
"Analyze this problem with Sequential server"
"Create login form using Magic server"
"Test this feature with Playwright"
```

### Customize Server Combinations
```
"Design API using only Context7 + Sequential"
"Analyze with other servers excluding Magic"
"Create complete solution using all MCP servers"
```
