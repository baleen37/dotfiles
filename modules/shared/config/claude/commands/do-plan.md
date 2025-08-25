---
name: do-plan
description: "Execute plans step-by-step with progress tracking and smart assistance"
agents: [project-manager, implementation-specialist]
tools: [TodoWrite, Task]
---

# /do-plan - Sequential Plan Execution

**Purpose**: Execute planned tasks one by one in order, with progress tracking

## How It Works

### 1. Load Existing Plan
- Takes the plan created by `/plan` command
- Reads the checklist of tasks in order
- Identifies the next uncompleted task

### 2. Sequential Processing
- **Execute one task at a time** in the planned order
- Complete the current task fully before moving to next
- Update task status (pending → in progress → completed)
- Ask for confirmation before proceeding to next task

### 3. Progress Tracking
- Show which tasks are done, current, and remaining
- Display overall progress percentage
- Estimate time remaining based on completed tasks

## Basic Usage

```bash
/do-plan
```

Example sequential execution:
```
📋 Login System Implementation - Task 3 of 8

✅ COMPLETED TASKS:
  ✅ Analyze current authentication system
  ✅ Define security requirements

🔄 CURRENT TASK:
  🔄 Design database schema
     Status: In progress - working on user table structure
     Started: 15 minutes ago

⏳ REMAINING TASKS:
  ⏳ Develop authentication API
  ⏳ Implement password hashing
  ⏳ JWT token management
  ⏳ Implement login form
  ⏳ Error handling and validation

Progress: 2/8 tasks complete (25%) | Current task ETA: 30 minutes
```

## Sequential Execution Features

### Task Focus
- **One task at a time**: Complete current task before starting next
- **Context switching prevention**: Stay focused on single objective
- **Clear completion criteria**: Know exactly when task is done

### Progress Management
- **Linear progression**: Follow the planned sequence strictly
- **Checkpoint confirmations**: Verify completion before advancing
- **Rollback capability**: Return to previous task if needed

### Smart Assistance
- **Task-specific help**: Provide relevant guidance for current task
- **Context retention**: Remember what was done in previous tasks
- **Dependency validation**: Ensure prerequisites are met before proceeding

## Control Options

During execution, you can:
- Pause current task if needed
- Resume paused work
- Skip to next task if current one is complete
- Go back to previous task if needed

You can also request:
- Current progress status
- Overview of all tasks
- Preview of upcoming tasks

## Completion & Cleanup

Upon completion, automatically:
- Provide comprehensive results summary
- Suggest running tests
- Verify deployment readiness
- Recommend follow-up tasks

## Plan Integration

Works directly with `/plan` output:
- **Direct execution**: Start processing plan immediately after creation
- **Sequential order**: Follow exact task sequence from plan
- **Status updates**: Mark tasks complete in original plan structure
- **Plan continuity**: Maintain connection to original planning context

## Example Workflow

```bash
# 1. Create a plan
/plan "Implement user authentication"

# 2. Execute the plan sequentially  
/do-plan
```

The system will:
- Load the generated task list
- Start with task #1
- Complete it fully before moving to task #2
- Continue until all tasks are done
- Maintain focus on one task at a time
