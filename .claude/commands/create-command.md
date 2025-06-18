# Create Command

Systematic workflow for creating new Claude commands

## Overview

This command provides a structured workflow for creating new Claude commands. It ensures consistency with existing command patterns while maintaining a coherent structure across the command system.

## Workflow Steps

### Step 1: Command Analysis and Planning

**Objective:** Define the purpose and structure of the new command clearly

**Prompt Template:**
```
I want to create a new Claude command '[command-name]'.

Purpose: [Describe the command's purpose and functionality]

Please analyze the existing command structure and verify the following:
1. Common patterns and structure of existing commands
2. Naming conventions the new command should follow
3. Markdown format and section structure
4. Method for writing prompt examples

**Please provide analysis only - do not write any code yet.**
```

### Step 2: Command Structure Design

**Objective:** Establish detailed structure and content plan for the new command

**Prompt Template:**
```
Based on the analysis, please design the detailed structure for the '[command-name]' command.

The following elements must be included:
1. Command title and description
2. Overview section
3. Step-by-step workflow (Step 1, Step 2, ...)
4. Prompt examples for each step
5. Usage notes and considerations

Please propose a structure that maintains consistency with existing commands while reflecting the characteristics of the new command.
```

### Step 3: Review and Approval

**Objective:** Review the designed structure and obtain approval

**Prompt Template:**
```
The command structure design is complete. Please review the following aspects:

1. Does the structure maintain consistency with existing commands?
2. Is the workflow logical and practical?
3. Are the prompt examples clear and useful?
4. Are there any parts that need to be added or modified?

Once approved, I will create the actual file.
```

### Step 4: Command File Creation

**Objective:** Create the actual markdown file based on the approved structure

**Prompt Template:**
```
Please create the actual command file based on the approved structure.

File location: modules/shared/config/claude/commands/[command-name].md

Please verify the following:
1. Is the file path correct?
2. Is the markdown format accurate?
3. Are all sections included?
4. Is consistency maintained with existing commands?
```

### Step 5: Testing and Documentation

**Objective:** Verify the created command's functionality and update documentation

**Prompt Template:**
```
The new command has been created. Please perform the following tasks:

1. Verify that the command file was created correctly
2. Check compatibility with other commands
3. Update README.md or documentation if necessary
4. Perform basic testing of command usage

Once all tasks are completed, I will prepare for commit.
```

## Command Writing Guidelines

### Required Sections
- Title (# Command Name)
- Brief description (one line)
- Overview section
- Step-by-step workflow

### Recommended Structure
1. **Analysis/Exploration Phase** - Understand current situation
2. **Planning/Design Phase** - Establish detailed plan
3. **Review/Approval Phase** - Secure user approval
4. **Implementation/Execution Phase** - Perform actual work
5. **Completion/Cleanup Phase** - Finalize and document

### Prompt Writing Principles
- Clear and specific instructions
- One clear objective per step
- Explicitly indicate where user input is required
- Describe expected deliverables
- Use imperative mood for actionable instructions
- Include context and constraints when relevant

### Naming Conventions
- Use lowercase letters and hyphens (e.g., create-command)
- Start with a verb when possible
- Choose clear and intuitive names
- Avoid abbreviations unless widely understood
- Keep names concise but descriptive

### Content Best Practices
- Use consistent terminology throughout
- Provide concrete examples where helpful
- Include error handling and edge cases
- Structure information hierarchically
- Use bullet points for lists and steps
- Include timing estimates for complex workflows

## Usage Example

This command itself serves as an example of creating a `create-command` command:

1. **Analysis:** Understanding existing command structures
2. **Design:** Planning the create-command command structure
3. **Approval:** Review and approval process
4. **Creation:** Actual file generation
5. **Testing:** Functionality verification and documentation

## Best Practices

### Consistency Maintenance
- Follow established patterns from existing commands
- Use consistent section headers and formatting
- Maintain the same level of detail across similar commands
- Apply uniform prompt template structures

### Quality Assurance
- Ensure all steps are actionable and clear
- Test prompts with realistic scenarios
- Verify markdown formatting renders correctly
- Check that examples are accurate and helpful

### User Experience
- Consider the user's mental model and workflow
- Provide clear success criteria for each step
- Include troubleshooting guidance where appropriate
- Make commands self-documenting and discoverable

## Important Notes

- Maintain consistency with existing commands
- Follow proper markdown formatting
- Ensure prompt examples are clear and actionable
- Consider user workflow and experience
- Adhere to English-only documentation principle
- Test thoroughly before finalizing%  
