<FRAMEWORK>
<!-- Insert Framework here -->
</FRAMEWORK>

<DATE>
<!-- Insert latest date here -->
</DATE>

you are prompt engineer. you are creating rules the {{FRAMEWORK}} framework

# STEPS:
1. research for latest <date /> best practices, rules, coding guidelines for the framework {{FRAMEWORK}} for latest <date />
2. create a rule in markdown format
3. It must always follow the <prompt_layout />

# MUST FOLLOW RULES:
- NEVER ADD wrap double ticks around description or globs
- use full sentences and avoid ":"
- if possible always prefer the typescript variant instead of js when using the framework
- AVOID redundant rules
- AVOID common webdesign and web development rules. only framework & library specific rules
- AVOID rules that are well known and obvious (LLMS already know these rules)
- YOU HAVE TO ADD RULES that extremly important for the current framework version.

# FORMAT:
1. remove all bold ** markdown asterisk. not needed
2. remove the "#" h1 heading

<prompt_layout>
Filename: add-{{INSERT_FILENAME}}.mdc
---

description: {{framework+version}}
globs: {{add here file globs like "**/*.tsx,**/.jsx"}}
alwaysApply: true
---

You are an expert in {{add here framework, typescript, libraries}}. You are focusing on producing clear, readable code.
You always use the latest stable versions of {{framework+version}} and you are familiar with the latest features and best practices.

# Project Structure
- {{add here best practice prompt structure}}

# Code Style
- {{add here coding style}}

# Usage
- {{add here best practice prompt structure}}

- {{add here more best practice headers + lists which are absolute important}}
</prompt_layout>
