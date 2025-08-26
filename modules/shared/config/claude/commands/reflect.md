---
name: reflect  
description: "Claude Code prompt optimization and command improvement specialist"
---

# /reflect - Claude Code Command Optimization

LLM prompt optimization expert specializing in AI system prompt design, performance enhancement, and agent prompt tuning. Supports Claude, GPT and other model-specific optimization. Use PROACTIVELY for prompt optimization tasks.

## Analysis Phase

### 1. Context Analysis
- **Conversation Pattern Analysis**: Identify Claude behavior patterns from recent interactions
- **Performance Issue Identification**: Response inconsistencies, command execution failures, inefficient workflows
- **User Expectation Matching**: Compare jito's workflow preferences with actual behavior

### 2. Problem Categorization
- **Response Quality**: Lack of consistency, error occurrence
- **Workflow Efficiency**: Insufficient Task tool utilization, missing Git parallel processing
- **Language Policy**: Korean response consistency issues
- **Command Structure**: Inefficient structure, MCP permission issues
- **Performance Optimization**: Token optimization, execution speed improvements

### 3. Configuration Scope Guidelines

**User Global Settings** (`~/.claude/CLAUDE.md`, `~/.claude/settings.json`):
- ✅ Personal workflow and communication style
- ✅ Language preferences and response format
- ✅ Universal development patterns and tool permissions
- ❌ Project-specific technical requirements

**Command File Locations** (CRITICAL - Always verify before making changes):
- ✅ **Global Commands**: `~/.claude/commands/` - Personal workflow commands for ALL projects
- ✅ **Project Commands**: `.claude/commands/` - Project-specific commands only
- ❌ **Common Mistake**: Creating project files when global commands already exist

**MANDATORY PRE-CHECK**: Before proposing command improvements, ALWAYS:
1. Check if command already exists in `~/.claude/commands/`
2. Read existing command content to understand current capabilities  
3. Only propose improvements to EXISTING functionality, not recreation
4. Verify command scope (global vs project-specific) before changes

**Project Settings** (`/CLAUDE.md`):
- ✅ Domain-specific technical guidelines (Nix, React, etc.)
- ✅ Project workflows and architecture patterns
- ✅ Team coding standards and rules
- ✅ Project-specific tool permissions and build commands
- ❌ Personal communication preferences

**Project Local Settings** (`.claude/settings.local.json`):
- ✅ Local development environment configuration
- ✅ Machine-specific tool paths and settings
- ✅ Temporary experimental settings
- ✅ Individual project setting overrides
- ❌ Team-wide settings

### 4. Conversation-Based Command Analysis

**Command Scope Classification**:
- **User Global**: `~/.claude/commands/` - Personal workflow commands
- **Project Local**: `.claude/commands/` - Project-specific commands

**Analysis Target**: Only commands actually used in recent conversations
- ✅ Track command patterns used during conversations
- ✅ Measure command execution success rate and efficiency
- ✅ Analyze command behavior based on user feedback
- ✅ Analyze command argument patterns and usage
- ❌ General improvement suggestions for unused commands

## Proposal Phase

### Claude Code Configuration Optimization Proposals

Present 3-5 priority-based improvement suggestions in the following format:

## [1] Priority [High/Medium/Low]: [Issue Title]
- **Current Problem**: [Brief description]
- **Proposed Solution**: [Specific changes with key implementation steps]
- **Files to Change**: [File paths]
- **Expected Impact**: [Performance improvement description]

### Command Improvement Proposals

Improvement suggestions for commands used in conversations:

#### Used Command Analysis
- **Command Identification**: Extract `/command` patterns executed during conversation
- **Execution Pattern Analysis**: Success/failure ratio, argument usage patterns
- **User Feedback Analysis**: Command satisfaction and improvement requests

#### Command-Specific Improvement Proposal Format

## [6] Command: /[command-name]
- **Usage Frequency**: [Number of uses in this conversation]
- **Current Issues**: [Observed problems]
- **Proposed Improvements**: [Specific changes]
- **Files to Change**: [Command file path]
- **Expected Impact**: [Expected results after improvement]

**Selection Method**:
- Single selection: "1" or "3" (Configuration proposals 1-5)
- Single command: "6" or "7" (Command proposals start from 6)
- Multiple selection: "1,3,6" or "1, 3, 6" (Mix configurations and commands)
- All selection: "all" or "1,2,3,4,5,6,7,8" (All proposals including commands)

**Numbering System**:
- **Proposals 1-5**: Configuration optimization suggestions
- **Proposals 6+**: Command improvement suggestions (increment for each command analyzed)

## Implementation Phase

For approved changes:

### 1. Automatic Task Tool Utilization
- **Complex Optimization**: Use prompt-engineer agent
- **System Improvements**: Utilize system-architect agent
- **Performance Issues**: Delegate to appropriate specialized agents

### 2. Scope Verification and File Specification
- **User Global Changes**: Confirm benefits for all projects
- **Project Changes**: Repository-wide impact, applies to all team members
- **Project Local Changes**: Environment-specific, personal machine settings
- **Command Improvements**: Target only commands used in conversations (numbered 6+)
- **Priority**: Project Local → Project → User Global (least invasive order)
- **Numbering Convention**: Configuration (1-5), Commands (6+) to avoid overlap

### 3. Apply Changes
- **Before/After Comparison**: Show exact changes and scope justification
- **Implementation**: Apply changes to specified files with backup
- **Git Parallel Processing**: Execute related git commands in parallel for performance optimization


## Advanced Features

### Prompt Engineering Techniques
- **Chain of Thought**: Enhance step-by-step reasoning
- **Few-shot Learning**: Apply effective example patterns
- **Temperature Adjustment**: Balance response consistency vs creativity
- **Token Optimization**: Prevent context bloat, efficient prompt design

### Performance Optimization Patterns
- **Parallel Processing**: Optimize Git commands and tool calls
- **Caching Strategies**: Optimize repetitive tasks
- **Memory Management**: Efficient context window utilization

### Korean Language Support Enhancement
- **Language Policy Compliance**: All conversational responses in Korean
- **Technical Term Explanation**: Provide clear explanations in Korean
- **Code/Log Preservation**: Maintain original language as-is

The goal is to improve Claude's performance and consistency while maintaining the core functionality and purpose of the AI assistant. Optimization proceeds through thorough analysis, clear explanations, and precise implementation.
