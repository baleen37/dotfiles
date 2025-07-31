# /troubleshoot - Systematic Problem Diagnosis & Root Cause Analysis

Evidence-based systematic debugging and problem resolution with intelligent Wave orchestration for complex issues.

## Purpose
- **Systematic Diagnosis**: Structured investigation methodology for reliable problem identification
- **Root Cause Analysis**: Deep investigation beyond surface symptoms to identify underlying causes
- **Wave-Enabled Intelligence**: Auto-activate Wave mode for complex multi-domain issues
- **Evidence-Based Solutions**: Data-driven diagnosis with verifiable resolution steps
- **Pattern Recognition**: Identify recurring issues and systemic problems
- **Learning Integration**: Build knowledge base from resolved issues for future prevention

## Usage
```bash
/troubleshoot [problem-description] [--category type] [--severity level] [--strategy approach]
```

## Arguments & Flags

### Problem Specification
- `[problem-description]` - Description of the issue or symptoms (required)
- `@error/stacktrace` - Analyze specific error logs or stack traces
- `@build/failure` - Build system failures and compilation issues
- `@runtime/crash` - Runtime errors and application crashes
- `@performance/degradation` - Performance issues and bottlenecks
- `@deployment/failure` - Deployment and infrastructure issues
- `@integration/broken` - Integration and API failures

### Problem Categories
- `--category runtime` - Runtime errors, crashes, exceptions
- `--category build` - Build failures, compilation errors, dependency issues
- `--category performance` - Slow responses, bottlenecks, resource usage
- `--category security` - Security vulnerabilities, authentication failures
- `--category integration` - API failures, service communication issues
- `--category environment` - Configuration, deployment, infrastructure issues
- `--category ui` - Frontend issues, rendering problems, UX bugs
- `--category data` - Database issues, data corruption, query problems

### Severity Levels
- `--severity critical` - System down, data loss, security breach
- `--severity high` - Major functionality broken, significant impact
- `--severity medium` - Partial functionality affected, workaround available
- `--severity low` - Minor issues, cosmetic problems, edge cases

### Investigation Strategy
- `--strategy systematic` - Comprehensive methodical investigation (default)
- `--strategy targeted` - Focus on specific known issue patterns
- `--strategy comparative` - Compare against known working states
- `--strategy forensic` - Deep analysis for complex or intermittent issues
- `--strategy collaborative` - Multi-persona approach for complex domains

### Analysis Depth
- `--depth quick` - Surface-level diagnosis for obvious issues
- `--depth standard` - Comprehensive investigation with root cause analysis
- `--depth forensic` - Deep investigation with historical analysis
- `--depth comprehensive` - System-wide analysis with Wave activation

### Diagnostic Modes
- `--reproduction` - Focus on reproducing the issue consistently
- `--isolation` - Isolate variables to identify specific causes
- `--monitoring` - Set up monitoring to track issue patterns
- `--preventive` - Identify preventive measures and early warning signs

## Diagnostic Framework

### Phase 1: Issue Assessment & Triage
```yaml
initial_assessment:
  symptoms: [visible_errors, performance_degradation, functionality_loss]
  impact: [user_experience, business_operations, system_stability]
  urgency: [critical, high, medium, low]
  affected_components: [frontend, backend, database, infrastructure]

triage_criteria:
  critical: "System down, security breach, data loss"
  high: "Major functionality broken, significant user impact"
  medium: "Partial functionality affected, workaround available"
  low: "Minor issues, cosmetic problems, edge cases"
```

### Phase 2: Evidence Collection
```yaml
evidence_gathering:
  logs: [application_logs, system_logs, error_logs, access_logs]
  metrics: [performance_metrics, resource_usage, response_times]
  traces: [stack_traces, execution_traces, network_traces]
  environmental: [configuration, dependencies, infrastructure_state]
  user_reports: [reproduction_steps, error_messages, screenshots]

data_sources:
  - Application error logs and debugging output
  - System monitoring and performance metrics
  - User reports and reproduction scenarios
  - Configuration files and environment variables
  - Database logs and query performance
  - Network traces and API responses
```

### Phase 3: Pattern Analysis
```yaml
pattern_detection:
  temporal: [time_correlation, frequency_analysis, trend_identification]
  spatial: [component_correlation, dependency_analysis, impact_mapping]
  behavioral: [user_action_correlation, usage_pattern_analysis]
  environmental: [configuration_correlation, resource_correlation]

analysis_techniques:
  - Timeline reconstruction of events leading to issue
  - Correlation analysis between symptoms and system changes
  - Dependency mapping to identify cascade failures
  - Resource utilization pattern analysis
  - User behavior correlation with error occurrence
```

### Phase 4: Hypothesis Generation
```yaml
hypothesis_framework:
  root_causes: [code_defects, configuration_errors, resource_exhaustion]
  contributing_factors: [timing_issues, load_conditions, environmental_changes]
  failure_modes: [single_point_failure, cascade_failure, resource_contention]

hypothesis_validation:
  - Controlled reproduction of suspected conditions
  - A/B testing with suspected fixes
  - Rollback testing to confirm causation
  - Monitoring implementation to validate theories
```

### Phase 5: Root Cause Identification
```yaml
root_cause_analysis:
  techniques: [five_whys, fishbone_diagram, fault_tree_analysis]
  validation: [reproduction_testing, controlled_experiments]
  documentation: [cause_mapping, timeline_reconstruction]

validation_methods:
  - Reproduce issue in controlled environment
  - Implement targeted fix and validate resolution
  - Monitor for recurrence patterns
  - Verify fix doesn't introduce new issues
```

## Problem-Specific Methodologies

### Runtime Error Diagnosis
```yaml
runtime_investigation:
  stack_trace_analysis:
    - Parse exception stack trace for call path
    - Identify failing method and line number
    - Analyze variable states at failure point
    - Check for null references and boundary conditions

  memory_analysis:
    - Monitor memory usage patterns
    - Identify memory leaks and excessive allocation
    - Analyze garbage collection behavior
    - Check for resource cleanup issues

  concurrency_issues:
    - Identify race conditions and deadlocks
    - Analyze thread synchronization problems
    - Check for atomic operation violations
    - Monitor thread pool exhaustion
```

### Build Failure Diagnosis
```yaml
build_investigation:
  dependency_analysis:
    - Verify package versions and compatibility
    - Check for missing or corrupted dependencies
    - Analyze lock file consistency
    - Validate registry access and credentials

  compilation_errors:
    - Parse compiler error messages
    - Identify syntax and type errors
    - Check for missing imports or exports
    - Validate configuration and build settings

  environment_issues:
    - Verify build tool versions
    - Check environment variables and paths
    - Validate file permissions and access
    - Analyze build caching issues
```

### Performance Issue Diagnosis
```yaml
performance_investigation:
  bottleneck_identification:
    - Profile CPU usage and execution time
    - Analyze memory allocation patterns
    - Monitor I/O operations and database queries
    - Identify network latency and bandwidth issues

  scalability_analysis:
    - Test performance under load
    - Identify resource contention points
    - Analyze caching effectiveness
    - Monitor connection pool utilization

  optimization_opportunities:
    - Identify N+1 query problems
    - Find inefficient algorithms
    - Locate unnecessary processing
    - Optimize resource allocation
```

### Integration Failure Diagnosis
```yaml
integration_investigation:
  api_analysis:
    - Verify endpoint availability and response
    - Check authentication and authorization
    - Analyze request/response format compatibility
    - Monitor timeout and retry behavior

  network_diagnostics:
    - Test connectivity and routing
    - Analyze DNS resolution issues
    - Check firewall and proxy configuration
    - Monitor SSL/TLS certificate validity

  service_dependencies:
    - Map service dependency chain
    - Identify single points of failure
    - Check service health and availability
    - Analyze circuit breaker behavior
```

## Solution Development

### Solution Framework
```yaml
solution_development:
  immediate_fixes: [hotfixes, workarounds, rollbacks]
  root_solutions: [code_fixes, configuration_changes, infrastructure_updates]
  preventive_measures: [monitoring, testing, process_improvements]

implementation_strategy:
  - Prioritize fixes by impact and effort
  - Implement safeguards and rollback plans
  - Test solutions in isolated environments
  - Monitor implementation for side effects
```

### Solution Validation
```yaml
validation_process:
  functional_testing:
    - Verify fix resolves original issue
    - Test affected functionality thoroughly
    - Validate edge cases and boundary conditions
    - Confirm no regression in other areas

  performance_testing:
    - Measure performance impact of fix
    - Validate resource usage remains acceptable
    - Test under expected load conditions
    - Monitor for new bottlenecks

  integration_testing:
    - Verify system integration remains intact
    - Test all affected service dependencies
    - Validate data flow and processing
    - Confirm API contracts and interfaces
```

## Documentation & Learning

### Issue Documentation
```yaml
documentation_framework:
  problem_description: [symptoms, impact, timeline, affected_users]
  investigation_process: [methods_used, evidence_collected, hypotheses_tested]
  root_cause_analysis: [identified_causes, contributing_factors, failure_modes]
  solution_implementation: [fix_details, testing_performed, deployment_process]
  prevention_measures: [monitoring_added, process_changes, safeguards_implemented]

knowledge_capture:
  - Create searchable issue database
  - Document troubleshooting playbooks
  - Build diagnostic decision trees
  - Maintain solution knowledge base
```

### Preventive Measures
```yaml
prevention_strategy:
  monitoring_improvements:
    - Add health checks and alerting
    - Implement performance monitoring
    - Create error rate dashboards
    - Set up anomaly detection

  process_improvements:
    - Update deployment procedures
    - Enhance testing coverage
    - Improve code review practices
    - Strengthen configuration management

  system_hardening:
    - Add redundancy and failover
    - Implement circuit breakers
    - Improve error handling
    - Enhance logging and observability
```

## Wave Integration

### Complex Issue Orchestration
```yaml
wave_activation_triggers:
  multi_domain_issues: "complexity >= 0.7 AND affected_systems > 2"
  systemic_problems: "pattern_occurrence > 3 AND impact_scope = system_wide"
  forensic_investigation: "investigation_depth = comprehensive"
  cascading_failures: "failure_chain_length > 2"

wave_strategies:
  systematic: "Methodical investigation across all affected systems"
  forensic: "Deep historical analysis and pattern correlation"
  collaborative: "Multi-persona expertise for complex domain issues"
  comprehensive: "Full system analysis with preventive recommendations"
```

### Multi-Persona Collaboration
```yaml
persona_coordination:
  analyzer: "Lead investigation and pattern recognition"
  security: "Security-focused analysis and threat assessment"
  performance: "Performance impact analysis and optimization"
  architect: "System design impact and structural analysis"
  devops: "Infrastructure and deployment issue diagnosis"
```

## Command Integration

### Related Commands
```bash
# Deep system analysis for investigation
/analyze @system/ --focus [domain] --depth comprehensive

# Implement fixes and improvements
/improve @components/ --focus reliability --strategy targeted

# Build system troubleshooting
/build --validate --troubleshoot

# Performance issue investigation
/analyze @performance/ --depth forensic --strategy systematic

# Security incident response
/analyze @security/ --focus vulnerabilities --depth comprehensive
```

### Workflow Integration
```bash
# Investigation to improvement pipeline
/troubleshoot "API timeout issues" --category performance --severity high
# → /analyze @api/ --focus performance --depth forensic
# → /improve @api/ --focus performance --strategy targeted

# Build failure to fix pipeline
/troubleshoot "Build failing on CI" --category build --severity high
# → /analyze @build/ --focus dependencies --depth standard
# → /build --fix-dependencies --validate
```

## Quality Gates & Performance

### Diagnostic Quality
- **Issue Reproduction**: 95% of issues successfully reproduced in controlled environment
- **Root Cause Accuracy**: 90% of identified root causes validated through fix implementation
- **Solution Effectiveness**: 95% of implemented solutions resolve the original issue
- **Prevention Success**: 80% reduction in similar issue recurrence after preventive measures

### Performance Metrics
- **Diagnosis Time**: Average 30 minutes for standard issues, 2 hours for complex issues
- **Resolution Time**: 80% of issues resolved within SLA based on severity level
- **Knowledge Capture**: 100% of resolved issues documented in searchable knowledge base
- **Learning Integration**: Diagnostic patterns and solutions integrated into future troubleshooting

### Success Criteria
- **Problem Resolution**: Issue completely resolved with validation testing
- **Knowledge Transfer**: Investigation process and solution documented for team learning
- **Prevention Implementation**: Monitoring and safeguards implemented to prevent recurrence
- **Process Improvement**: Lessons learned integrated into development and deployment processes
