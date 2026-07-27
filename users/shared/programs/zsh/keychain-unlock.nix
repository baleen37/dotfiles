# Unlock the macOS login keychain when Claude Code needs it over SSH
#
# Over SSH the login keychain is not unlocked automatically (unlike a GUI
# login), so tools that read credentials from it (e.g. Claude Code) report
# "Not logged in". FileVault disables the regular autoLoginUser path, and
# unlocking without a prompt would require storing the login password. Instead,
# the cc wrapper calls this function lazily so an ordinary SSH login never
# prompts for it.
#
# Guards:
# - macOS only (caller passes isDarwin)
# - SSH sessions only ($SSH_CONNECTION) -- never touches local GUI shells
# - already-unlocked keychains are skipped silently (show-keychain-info
#   succeeds only when unlocked), so later cc calls do not re-prompt
#
# On success the keychain timeout is cleared (set-keychain-settings with no -t)
# so it stays unlocked for the rest of the boot instead of relocking mid-session
# and prompting again.

{ isDarwin, lib }:

lib.optionalString isDarwin ''
  _claude_unlock_login_keychain() {
    [[ -n "''${SSH_CONNECTION:-}" ]] || return 0

    local keychain="$HOME/Library/Keychains/login.keychain-db"
    if ! security show-keychain-info "$keychain" &>/dev/null; then
      echo "🔐 Claude Code needs the locked login keychain, unlocking..." >&2
      if ! security unlock-keychain "$keychain"; then
        echo "⚠️  Keychain unlock failed -- Claude Code was not started." >&2
        echo "   Retry with: security unlock-keychain \"$keychain\"" >&2
        return 1
      fi

      # Drop the inactivity timeout so later calls reuse this unlock.
      security set-keychain-settings "$keychain"
    fi

    return 0
  }
''
