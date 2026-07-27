# Claude Code wrapper function for Zsh

''
  cc() {
    ENABLE_TOOL_SEARCH=true command claude --dangerously-skip-permissions "$@"
  }
''
