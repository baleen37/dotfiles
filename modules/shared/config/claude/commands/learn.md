---
name: learn
description: "Socratic method-based learning through discovery and questioning instead of direct answers"
agents: [code-reviewer, system-architect, python-ultimate-expert, typescript-pro]
---

# /learn - Socratic Discovery Learning

**Purpose**: Transform learning from passive consumption to active discovery through strategic questioning. Instead of providing direct answers, guide users to discover principles, patterns, and best practices through their own insights.

## Usage

```bash
/learn [topic] [code]                    # General Socratic learning
/learn clean-code [code-snippet]        # Clean Code principles discovery
/learn patterns [code-snippet]          # Design patterns identification  
/learn architecture [system-design]     # Architecture patterns exploration
```

## Core Learning Philosophy

### **Discovery Over Instruction**
- **What**: Guide observation of code characteristics
- **How**: Progressive questioning to reveal underlying patterns
- **Why**: Connect discoveries to fundamental principles

### **Adaptive Questioning Strategy**
- **Beginner**: Simple observation questions, basic pattern recognition
- **Intermediate**: Comparative analysis, trade-off exploration
- **Advanced**: Complex system reasoning, architectural implications

## Learning Domains

### **Clean Code Discovery**
```bash
/learn clean-code [code-snippet]        # Discover Clean Code principles
/learn clean-code naming [code]         # Focus on naming conventions
/learn clean-code functions [code]      # Focus on function design
/learn clean-code structure [code]      # Focus on code organization
```

**Questioning Flow**:
1. **Observe**: "What do you notice about this code structure?"
2. **Compare**: "How does this differ from alternatives you've seen?"  
3. **Discover**: "What principle might explain this pattern?"
4. **Validate**: "How does this align with Clean Code guidelines?"
5. **Apply**: "Where else could this principle be useful?"

### **Pattern Recognition**
```bash
/learn patterns [code-snippet]          # Identify design patterns
/learn patterns creational [code]       # Focus on creational patterns
/learn patterns structural [code]       # Focus on structural patterns
/learn patterns behavioral [code]       # Focus on behavioral patterns
```

**Discovery Process**:
1. **Structure Analysis**: "What relationships do you see between objects?"
2. **Behavior Observation**: "How do these components interact?"
3. **Intent Discovery**: "What problem might this be solving?"
4. **Pattern Identification**: "Does this remind you of any common patterns?"
5. **Context Application**: "When would you choose this approach?"

### **Architecture Exploration**
```bash
/learn architecture [design]            # Explore architectural patterns
/learn architecture scalability [design] # Focus on scalability patterns
/learn architecture maintainability [design] # Focus on maintainability
/learn architecture security [design]   # Focus on security patterns
```

**Exploration Flow**:
1. **System Boundaries**: "How are responsibilities divided here?"
2. **Communication Patterns**: "What do you notice about data flow?"
3. **Constraint Analysis**: "What limitations or requirements are evident?"
4. **Trade-off Discovery**: "What benefits and costs do you see?"
5. **Principle Connection**: "Which architectural principles are demonstrated?"

## Learning Approaches

### **Guided Discovery**
- Progressive question sequences leading to insight
- Self-paced exploration with strategic prompts
- Principle validation against authoritative sources

### **Focused Exploration**  
- Domain-specific question sets for targeted learning
- Deep-dive into specific aspects (naming, patterns, security, etc.)
- Comparative analysis across different approaches

## MCP Integration

- **Context7**: Access to authoritative sources (Clean Code, Gang of Four patterns, architecture principles)
- **Sequential**: Multi-step learning progression and knowledge building
- **Code Analysis**: Real codebase examples for practical learning

## Agent Routing

- **code-reviewer**: Clean Code principles, code quality patterns
- **system-architect**: Architecture patterns, design principles, system thinking
- **python-ultimate-expert**: Python-specific patterns and idioms
- **typescript-pro**: TypeScript patterns, advanced typing concepts

## Learning Outcomes

### **Deep Understanding**
- Principle internalization through self-discovery
- Pattern recognition across different contexts
- Critical thinking about design decisions

### **Practical Application**
- Real codebase examples and exercises
- Immediate application opportunities
- Progressive skill building

### **Retained Knowledge**
- Self-discovered insights have higher retention
- Connected learning builds comprehensive understanding
- Question-based approach develops analytical skills

## Examples

```bash
/learn clean-code function validateUser(user) { ... }
# Guides discovery of function naming, single responsibility, error handling

/learn patterns creational class DatabaseConnection { ... }
# Explores singleton pattern through observation and questioning

/learn architecture scalability microservice-diagram.png
# Exploration of architectural trade-offs and scalability principles
```

The learning journey transforms from "Here's the answer" to "What do you discover?" - creating deeper understanding and lasting knowledge.
