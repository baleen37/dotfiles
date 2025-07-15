<pre_condition>
Make sure there is a claude.md. If there isn't, exit this prompt, and instruct the user to run /init
</pre_condition>

<python_setup>
- we use uv for python package management
- you don't need to use a requirements.txt
- run a script by `uv run <script.py>`
- add packages by `uv add <package>`
- packages are stored in pyproject.toml
</python_setup>

<workflow_setup>
- if there is a todo.md, then check off any work you have completed.
</workflow_setup>

<quality_gates>
- Make sure testing always passes before the task is done
- Make sure linting passes before the task is done
</quality_gates>
