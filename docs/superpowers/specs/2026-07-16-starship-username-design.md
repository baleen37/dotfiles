# Starship Username Prompt Design

## Goal

Change the compact Starship prompt from:

```text
~/dotfiles fix/ghostty-xterm-256color ≡1 nix ➜
```

to:

```text
jito.hello ~/dotfiles fix/ghostty-xterm-256color ≡1 ➜
```

The username must always be visible, without a hostname, and the Nix shell
indicator must not be shown.

## Design

Use Starship's built-in `username` module. Put `$username` first in the custom
prompt format, set `show_always = true`, and format it with one trailing space.
This keeps the value dynamic across machines and users.

Remove `$nix_shell` from the custom format and remove its dedicated display
configuration. Do not change the directory, Git, Python, command-duration, or
character modules.

## Alternatives Considered

- A custom environment-variable module would duplicate Starship's username
  support.
- Hardcoding `jito.hello` would break the repository's multi-user behavior.
- Showing `username@hostname` would add information the requested compact
  prompt does not need.

## Verification

Update the focused Starship unit test to verify that:

- `$username` is present in the prompt format.
- `$nix_shell` is absent from the prompt format.
- the username module is enabled and always visible.
- the hostname remains disabled.

Run the focused Starship unit check and the repository formatter check.
