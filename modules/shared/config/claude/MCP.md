# MCP Server 스마트 활용 가이드

Claude Code의 MCP 서버들을 효과적으로 활용하는 실용적 가이드

## 🎯 핵심 MCP 서버들

### 스마트 감지 기반 MCP 활용

**키워드 기반 자동 검토**:
- **문서/라이브러리 질문** → Context7 우선 검토
- **복잡한 분석/계획** → Sequential 고려
- **복잡한 분석/계획** → Sequential 고려  
- **브라우저/테스트 작업** → Playwright 검토
- **일반적 코딩** → 기본 도구로 처리

### Context7: Documentation & Library Search
**Use Case**: API references, library documentation, framework information
**Trigger Keywords**: "docs", "API", "library", "framework", "version", "examples"
**Practical Usage**:
- "Find React 18 new features" → Context7 consideration
- "TypeScript type definition methods" → Context7 priority review

### Sequential: Complex Analysis & Step-by-Step Thinking
**Use Case**: Analysis, planning, strategy development
**Trigger Keywords**: "analyze", "step-by-step", "plan", "strategy", "architecture"
**Practical Usage**:
- "Analyze this error step by step" → Sequential consideration
- "Microservice design strategy" → Sequential utilization review

### Playwright: Browser Automation & Testing
**Use Case**: E2E testing, browser automation tasks
**Trigger Keywords**: "test", "E2E", "browser", "screenshot", "automation"
**Practical Usage**:
- "E2E test for login flow" → Playwright review
- "Screenshot this page" → Playwright utilization

## 🧠 Smart Routing Logic

### Automatic Detection Pattern
```
Question/Request → Keyword Analysis → MCP Server Review → Optimal Tool Selection
```

### Practical Decision Criteria
- **Documentation/Library Questions** → Context7 priority review
- **Complex Analysis/Planning** → Sequential consideration
- **Complex Analysis/Planning** → Sequential consideration  
- **Browser/Testing Tasks** → Playwright review
- **General Coding** → Standard tools processing

### Multi-Server Coordination
When complex tasks require multiple capabilities:
- **Research + Analysis**: Context7 + Sequential combination
- **Analysis + Testing**: Sequential + Playwright coordination
- **Documentation + Implementation**: Context7 + standard tools

## 🎛️ User Control Options

### Explicit MCP Server Requests
```bash
"Find React documentation using Context7"
"Analyze this problem with Sequential server"
"Analyze this problem with Sequential server"  
"Create E2E test using Playwright"
```

### Direct Processing Requests
```bash
"Handle without MCP servers"
"Use standard mode"
"Process directly without external tools"
```

### Context-Aware Examples
```bash
"React component performance analysis"
→ Context7(React best practices) + Sequential(performance analysis) review
→ Task delegation decision based on complexity

"Nix flake configuration issue"
"Nix flake configuration issue"  
→ nix-system-expert priority (specialized domain)
→ Sequential for complex troubleshooting if needed

"Authentication system security review"
→ security-auditor priority + Context7(security patterns) consideration
```

## Integration with Task Delegation

### MCP-Aware Routing Priority
1. **MCP Server Suitability Check** (keyword-based)
2. **Task Delegation Assessment** (complexity-based)
3. **Optimal Tool Combination Selection** (efficiency-based)

### Practical Workflow
```
"Analyze React performance"
→ Check Context7 (React patterns) + Sequential (analysis) suitability
→ Assess complexity for Task delegation
→ Select optimal approach
```

## Best Practices

### Effective MCP Utilization
- **Keyword Awareness**: Use trigger keywords naturally in requests
- **Clear Intent**: Specify what type of help needed (docs, analysis, testing)
- **Context Provision**: Include relevant project/framework information
- **Iterative Approach**: Start with MCP guidance, then refine with feedback

### Common Usage Patterns
```bash
# Documentation Research
"Find Next.js 14 routing examples" → Context7 utilization

# Complex Problem Solving
# Complex Problem Solving  
"Analyze authentication flow bottleneck" → Sequential consideration

# Testing Strategy
"E2E test strategy for checkout process" → Playwright review

# Multi-Domain Tasks
"React performance optimization approach" → Context7 + Sequential coordination
```

### Fallback Strategy
- **MCP Server Unavailable**: Graceful fallback to standard tools
- **Context7 Alternative**: WebSearch for documentation needs
- **Sequential Alternative**: Basic step-by-step manual analysis
- **Sequential Alternative**: Basic step-by-step manual analysis  
- **Playwright Alternative**: Manual test strategy guidance
