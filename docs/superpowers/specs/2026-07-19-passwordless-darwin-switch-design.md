# Passwordless nix-darwin Switch Design

- Date: 2026-07-19
- Status: approved
- Target: `kakaostyle-jito` / `jito.hello`

## Goal

Allow `make switch` on `kakaostyle-jito` without a sudo password while keeping
password authentication for unrelated sudo commands and other Darwin hosts.

## Selected design

The Darwin branch of `make switch` will invoke the root-managed executable
`/run/current-system/sw/bin/darwin-rebuild` directly. It will no longer sudo
`/usr/bin/env`, because allowing that command would permit arbitrary root
commands.

`machines/darwin/common.nix` will append a host-conditional sudoers rule only
when `currentSystemName == "kakaostyle-jito"`:

```sudoers
jito.hello ALL = (root) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild ^switch --flake \.\#kakaostyle-jito$
```

The regular expression matches the complete argument string, so other
`darwin-rebuild` actions, flags, and flake selectors still require a password.
The syntax has been checked with the installed `visudo` 1.9.13p2.

## Security boundary

This rule narrows accidental passwordless sudo use to one executable and one
argument sequence. It is not a defense against an intentional privilege
escalation: the user controls the selected flake, and nix-darwin activation
runs that flake's system configuration as root. This limitation is inherent in
passwordless system rebuilds.

## Alternatives considered

- `jito.hello ALL=(ALL) NOPASSWD: ALL`: simplest, but removes password checks
  from every sudo command; rejected as unnecessarily broad.
- Keep `sudo -H env PATH=... darwin-rebuild`: incompatible with a narrow rule,
  because sudo authorizes `/usr/bin/env`, which can launch arbitrary commands;
  rejected.
- `sudo -v && make switch`: retains authentication and is safest, but does not
  meet the requested non-interactive workflow; rejected by scope.

## Changes

- `Makefile`: declare the absolute Darwin rebuild path and use it directly in
  the Darwin `switch` recipe.
- `machines/darwin/common.nix`: add the host-conditional exact sudoers rule.
- `tests/unit/makefile-switch-commands-test.nix`: verify the Darwin recipe uses
  the allowlisted executable and does not sudo `env`.
- Add a focused Nix evaluation test for host isolation and exact rule content.

## Verification and rollout

1. Test-first assertions fail against the current Makefile and Darwin configs.
2. The updated focused tests, formatter, and relevant flake checks pass.
3. Build and run `make switch` once with the existing sudo password to install
   the rule.
4. Invalidate the sudo timestamp, then verify `make switch` succeeds without a
   prompt.
5. Verify `sudo -n true` and a non-matching `darwin-rebuild` command still fail.
6. Create a PR, require CI success, and squash merge.
