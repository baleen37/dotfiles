# Auto-unlock the macOS login keychain in SSH sessions
#
# Over SSH the login keychain is not unlocked automatically (unlike a GUI
# login), so tools that read credentials from it (e.g. Claude Code) report
# "Not logged in". This prompts once per session to unlock it.
#
# Normally this never fires: darwin/default.nix sets loginwindow.autoLoginUser,
# so a reboot brings up a GUI session that unlocks the keychain the standard
# way. This stays as the fallback for when that path is unavailable -- no
# /etc/kcpassword yet, or the keychain was locked by hand.
#
# Guards:
# - macOS only (caller passes isDarwin)
# - SSH sessions only ($SSH_CONNECTION) -- never touches local GUI shells
# - interactive shells only ([[ -o interactive ]]) -- avoids hanging
#   non-interactive calls like `ssh host cmd`, scp, or rsync on a prompt
# - already-unlocked keychains are skipped silently (show-keychain-info
#   succeeds only when unlocked), so re-sourcing never re-prompts
#
# On success the keychain timeout is cleared (set-keychain-settings with no -t)
# so it stays unlocked for the rest of the boot instead of relocking mid-session
# and prompting again.

{ isDarwin, lib }:

lib.optionalString isDarwin ''
  if [[ -n "''${SSH_CONNECTION:-}" ]] && [[ -o interactive ]]; then
    if ! security show-keychain-info ~/Library/Keychains/login.keychain-db &>/dev/null; then
      echo "🔐 SSH session: login keychain is locked, unlocking..." >&2
      if security unlock-keychain ~/Library/Keychains/login.keychain-db; then
        # Drop the inactivity timeout so later sessions reuse this unlock.
        security set-keychain-settings ~/Library/Keychains/login.keychain-db
      else
        echo "⚠️  Keychain unlock failed -- keychain-backed logins (e.g. Claude Code) will fail." >&2
        echo "   Retry with: security unlock-keychain ~/Library/Keychains/login.keychain-db" >&2
      fi
    fi
  fi
''
