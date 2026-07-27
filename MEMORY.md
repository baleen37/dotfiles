# Technical memory

## macOS SSH and Claude Code authentication

- FileVault disables the regular `loginwindow.autoLoginUser` path. Its separate
  FDEAutoLogin flow follows an interactive disk unlock and is not a headless
  Keychain-unlock mechanism.
- Do not store the macOS login password to automate `security unlock-keychain`.
- Keep Claude Code subscription OAuth in the macOS Keychain so its refresh
  token remains managed. The one-year `claude setup-token` alternative works,
  but its manual renewal is not preferred.
- SSH shell startup must not unlock the keychain. Unlock it lazily when `cc`
  starts Claude Code, then clear the keychain inactivity timeout for later
  calls.
