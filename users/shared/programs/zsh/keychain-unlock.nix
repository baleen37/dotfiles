# Auto-unlock the macOS login keychain in SSH sessions
#
# Over SSH the login keychain is not unlocked automatically (unlike a GUI
# login), so tools that read credentials from it (e.g. Claude Code) report
# "Not logged in". This prompts once per session to unlock it.
#
# Guards:
# - macOS only (caller passes isDarwin)
# - SSH sessions only ($SSH_CONNECTION) -- never touches local GUI shells
# - interactive shells only ([[ -o interactive ]]) -- avoids hanging
#   non-interactive calls like `ssh host cmd`, scp, or rsync on a prompt
# - already-unlocked keychains are skipped silently (show-keychain-info
#   succeeds only when unlocked), so re-sourcing never re-prompts

{ isDarwin, lib }:

lib.optionalString isDarwin ''
  if [[ -n "''${SSH_CONNECTION:-}" ]] && [[ -o interactive ]]; then
    if ! security show-keychain-info ~/Library/Keychains/login.keychain-db &>/dev/null; then
      echo "🔐 SSH session: login keychain is locked, unlocking..." >&2
      security unlock-keychain ~/Library/Keychains/login.keychain-db
    fi
  fi
''
