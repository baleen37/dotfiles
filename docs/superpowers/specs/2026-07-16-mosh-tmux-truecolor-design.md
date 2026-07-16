# Mosh + tmux Truecolor Design

## Context

Ghostty starts mosh with truecolor support, but mosh presents the remote tmux
client as `xterm-256color`. The current tmux configuration only enables `RGB`
for `xterm-ghostty`, so tmux reduces 24-bit SGR colors to the 256-color palette.

The behavior was reproduced through an isolated mosh and tmux session:

- Before the override, `48;2;1;2;3` became `48;5;16`.
- With `xterm-256color:RGB`, `48;2;1;2;3` passed through unchanged.
- The remote pane already received `COLORTERM=truecolor`.

## Decision

Add `xterm-256color:RGB` to tmux `terminal-features` while retaining the
existing `xterm-ghostty:RGB` entry. Do not add `extkeys` for
`xterm-256color`; the observed defect is color capability detection, and mosh
did not advertise extended-key support.

## Scope

- Update `users/shared/programs/tmux.nix` with the mosh-facing RGB capability.
- Add a focused integration assertion for the new terminal feature.
- Apply the Home Manager configuration on the remote MacBook.
- Reconnect through mosh and verify that the attached tmux client reports
  `RGB` and preserves a truecolor SGR sequence.

## Non-goals

- Changing mosh prediction behavior.
- Changing tmux extended-key handling.
- Upgrading mosh, tmux, or Ghostty.
- Refactoring unrelated tmux configuration.

## Verification

1. The focused tmux integration test fails before the config change and passes
   afterward.
2. Darwin smoke evaluation remains successful.
3. After remote Home Manager activation and a fresh mosh attach,
   `client_termfeatures` includes `RGB`.
4. A truecolor SGR input remains `38;2` or `48;2` instead of being reduced to
   `38;5` or `48;5`.
