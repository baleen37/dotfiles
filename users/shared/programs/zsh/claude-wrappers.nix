# Claude Code wrapper function for Zsh

{ isDarwin, lib }:

''
  ${import ./keychain-unlock.nix { inherit isDarwin lib; }}

  cc() {
    ${lib.optionalString isDarwin ''
      _claude_unlock_login_keychain || return
    ''}
    ENABLE_TOOL_SEARCH=true command claude --dangerously-skip-permissions "$@"
  }
''
