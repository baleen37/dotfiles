# /spawn - Meta-Orchestration & Complex Operation Execution

Intelligent decomposition and execution of complex multi-domain operations using specialized agents and advanced coordination.

## Purpose
- **Intelligent Decomposition**: Break complex operations into coordinated subtasks
- **Specialized Agent Coordination**: Deploy domain-specific agents for optimal execution
- **Real-Time Integration**: Live coordination and result synthesis within session
- **Resource Optimization**: Intelligent resource allocation and execution ordering
- **Immediate Completion**: End-to-end execution from analysis to delivery
- **Meta-Orchestration**: Coordinate multiple SuperClaude commands and systems

## Usage
```bash
/spawn [operation] [--strategy approach] [--coordination method] [--agents list]
```

## Arguments & Flags

### Operation Types
- `[operation]` - Complex multi-domain task description
- `@enterprise-audit` - Full system audit across all domains
- `@feature-complete` - End-to-end feature implementation
- `@security-hardening` - Comprehensive security improvement
- `@performance-optimization` - System-wide performance enhancement
- `@modernization` - Technology stack upgrade and modernization

### Coordination Strategies
- `--strategy parallel` - Maximum parallelization for speed
- `--strategy sequential` - Careful step-by-step execution
- `--strategy hybrid` - Mixed parallel/sequential optimization (default)
- `--strategy fail-safe` - Conservative with extensive validation
- `--strategy aggressive` - Fast execution with calculated risks

### Agent Coordination
- `--agents auto` - Automatic agent selection based on operation (default)
- `--agents [list]` - Specific agent specializations (architect,security,performance)
- `--coordination centralized` - Single coordinator with specialized agents
- `--coordination distributed` - Peer-to-peer agent coordination
- `--coordination hierarchical` - Tiered coordination with lead agents

### Execution Control
- `--timeout [duration]` - Maximum execution time (default: 2h)
- `--checkpoints [n]` - Number of validation checkpoints
- `--rollback-ready` - Enable automatic rollback on failure
- `--dry-run` - Plan and validate without execution
- `--interactive` - Pause for approval at key decision points

### Integration Features
- `--create-tasks` - Generate `/task` hierarchy for ongoing work
- `--update-workflow` - Update project `/workflow` based on results
- `--document-process` - Create comprehensive execution documentation
- `--benchmark` - Measure and compare against baseline metrics

## Auto-Activation Patterns
- **Complex Multi-Domain**: Operations requiring 3+ specialized domains
- **Enterprise Scale**: Large-scale operations affecting >100 files
- **Critical Deadlines**: Time-sensitive operations requiring coordination
- **Integration Challenges**: Operations spanning multiple systems/technologies
- **Quality Requirements**: Operations requiring comprehensive validation

## Orchestration Framework

### Phase 1: Intelligent Decomposition
1. **Operation Analysis**: Parse complex requirements and success criteria
2. **Domain Identification**: Identify required specializations and expertise
3. **Dependency Mapping**: Map interdependencies and execution constraints
4. **Agent Assignment**: Select optimal agents for each subdomain
5. **Coordination Planning**: Design execution strategy and communication patterns

### Phase 2: Agent Deployment & Coordination
1. **Agent Initialization**: Deploy specialized agents with clear mandates
2. **Communication Setup**: Establish inter-agent communication and data sharing
3. **Resource Allocation**: Distribute computational and tool resources
4. **Synchronization Points**: Define coordination checkpoints and validation gates
5. **Conflict Resolution**: Establish protocols for conflicting recommendations

### Phase 3: Coordinated Execution
1. **Parallel Execution**: Execute independent operations simultaneously
2. **Real-Time Coordination**: Continuous communication and progress synchronization
3. **Dynamic Adaptation**: Adjust strategy based on intermediate results
4. **Quality Monitoring**: Continuous validation and quality assessment
5. **Progress Integration**: Synthesize results from all agents

### Phase 4: Integration & Validation
1. **Result Synthesis**: Integrate findings and deliverables from all agents
2. **Conflict Resolution**: Resolve any conflicting recommendations or implementations
3. **Comprehensive Validation**: End-to-end testing and quality verification
4. **Documentation Generation**: Create comprehensive execution report
5. **Handoff Preparation**: Prepare results for ongoing development or maintenance

## Specialized Agent Types

### Domain Specialists
```yaml
architect_agent:
  focus: [system_design, patterns, scalability]
  tools: [Sequential, Context7, Task]
  deliverables: [architecture_docs, design_decisions, scaling_plans]

security_agent:
  focus: [vulnerabilities, compliance, hardening]
  tools: [Sequential, Context7, security_scanning]
  deliverables: [security_assessment, remediation_plan, compliance_report]

performance_agent:
  focus: [optimization, bottlenecks, monitoring]
  tools: [Playwright, Sequential, profiling]
  deliverables: [performance_report, optimization_plan, monitoring_setup]

frontend_agent:
  focus: [ui_components, accessibility, user_experience]
  tools: [Magic, Playwright, Context7]
  deliverables: [component_library, accessibility_audit, user_testing]

backend_agent:
  focus: [apis, databases, infrastructure]
  tools: [Context7, Sequential, deployment]
  deliverables: [api_documentation, database_optimization, deployment_pipeline]
```

### Process Specialists
```yaml
qa_agent:
  focus: [testing, validation, quality_assurance]
  tools: [Playwright, testing_frameworks, validation]
  deliverables: [test_suite, quality_report, validation_results]

devops_agent:
  focus: [deployment, monitoring, infrastructure]
  tools: [infrastructure_tools, monitoring, deployment]
  deliverables: [deployment_pipeline, monitoring_setup, infrastructure_code]

scribe_agent:
  focus: [documentation, communication, knowledge_transfer]
  tools: [Context7, documentation_tools, wiki]
  deliverables: [comprehensive_docs, user_guides, knowledge_base]
```

## Operation Categories

### Enterprise Audit (`@enterprise-audit`)
```yaml
scope: comprehensive_system_assessment
agents: [architect, security, performance, qa, scribe]
deliverables:
  - system_architecture_assessment
  - security_vulnerability_report
  - performance_benchmark_analysis
  - quality_assessment_report
  - comprehensive_improvement_roadmap
timeline: 4-8 hours
```

### Feature Complete (`@feature-complete`)
```yaml
scope: end_to_end_feature_implementation
agents: [architect, frontend, backend, qa, scribe]
deliverables:
  - feature_specification
  - frontend_implementation
  - backend_implementation
  - comprehensive_test_suite
  - user_documentation
timeline: 6-12 hours
```

### Security Hardening (`@security-hardening`)
```yaml
scope: comprehensive_security_improvement
agents: [security, backend, devops, qa]
deliverables:
  - vulnerability_assessment
  - security_patches_implementation
  - compliance_documentation
  - security_monitoring_setup
timeline: 3-6 hours
```

### Performance Optimization (`@performance-optimization`)
```yaml
scope: system_wide_performance_improvement
agents: [performance, architect, frontend, backend]
deliverables:
  - performance_baseline_analysis
  - optimization_implementation
  - monitoring_and_alerting_setup
  - performance_documentation
timeline: 4-8 hours
```

## Integration with SuperClaude Ecosystem

### Command Orchestration
- **↔️ /workflow**: Import workflow requirements, export execution results
- **→ /task**: Generate persistent task hierarchy for ongoing maintenance
- **↔️ /analyze**: Import analysis findings, contribute comprehensive insights
- **↔️ /improve**: Coordinate with improvement initiatives
- **→ /load**: Update project context based on execution results

### Wave System Integration
- **Wave Coordination**: Spawn can trigger Wave mode for systematic execution
- **Multi-Wave Operations**: Complex spawns may execute across multiple Wave phases
- **Wave-Agent Hybrid**: Combine Wave orchestration with specialized agents

### Persona Integration
- **Dynamic Persona Activation**: Activate personas based on agent requirements
- **Cross-Persona Coordination**: Coordinate multiple personas within single session
- **Persona Specialization**: Deploy specific personas as specialized agents

### MCP Server Coordination
- **Server Load Balancing**: Distribute MCP server usage across agents
- **Shared Context**: Maintain shared context across multiple MCP operations
- **Resource Optimization**: Coordinate MCP server usage for optimal performance

## Output Formats

### Execution Summary
```markdown
# Spawn Execution Summary

## 🎯 Operation: Enterprise Security Audit
**Duration**: 3h 45m | **Agents**: 4 specialized | **Success Rate**: 98%

## 📈 Key Results
- **Security**: 15 vulnerabilities identified, 12 resolved immediately
- **Compliance**: OWASP Top 10 compliance achieved (was 60%, now 95%)
- **Infrastructure**: Monitoring and alerting deployed
- **Documentation**: Comprehensive security guide created

## 🚀 Next Steps
- [ ] Schedule monthly security review cycles
- [ ] Implement remaining 3 medium-priority fixes
- [ ] Train team on new security procedures
```

### Detailed Execution Report
```markdown
# Detailed Spawn Execution Report

## Agent Coordination Summary
### Security Agent (Lead)
- **Execution Time**: 2h 15m
- **Deliverables**: Vulnerability scan, remediation plan, compliance report
- **Key Findings**: 15 vulnerabilities (3 critical, 7 high, 5 medium)
- **Actions Taken**: Immediate patches for critical and high-priority issues

### DevOps Agent (Supporting)
- **Execution Time**: 1h 30m
- **Deliverables**: Security monitoring setup, alerting configuration
- **Key Contributions**: Automated security scanning, deployment pipeline hardening
- **Integration**: Seamless integration with existing CI/CD pipeline

### Documentation Agent (Supporting)
- **Execution Time**: 1h 00m
- **Deliverables**: Security procedures guide, incident response plan
- **Knowledge Transfer**: Team training materials, security checklist
```

### Task Hierarchy Export
```markdown
# Generated Task Hierarchy from Spawn Execution

📋 Epic: Security Hardening Implementation
├── 📖 Story: Critical Vulnerability Remediation
│   ├── ✅ Task: SQL injection vulnerability fixes
│   ├── ✅ Task: XSS protection implementation
│   └── ✅ Task: Authentication bypass patches
├── 📖 Story: Security Monitoring Setup
│   ├── ✅ Task: Security event logging
│   ├── ✅ Task: Automated vulnerability scanning
│   └── ✅ Task: Alert configuration and testing
└── 📖 Story: Team Security Training
    ├── ⏳ Task: Security awareness training schedule
    └── ⏳ Task: Incident response drill planning
```

## Quality Gates & Performance
- **Coordination Efficiency**: 95%+ successful agent coordination
- **Resource Utilization**: Optimal resource allocation across agents
- **Execution Speed**: 40-60% faster than sequential execution
- **Quality Assurance**: Comprehensive validation at each coordination checkpoint
- **Success Rate**: 90%+ operation completion within expected timeline

## Key Differences from Other Commands
- **vs /task**: Immediate execution vs long-term persistence
- **vs /workflow**: Execution focus vs planning and analysis
- **vs /improve**: Multi-domain coordination vs focused improvement
- **vs /analyze**: Action-oriented vs analysis-focused
- **vs Wave System**: Agent specialization vs orchestrated compound intelligence
