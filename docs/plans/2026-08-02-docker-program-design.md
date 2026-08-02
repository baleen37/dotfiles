# Docker Program Module Design Document

## Overview

A Home Manager module that pins the Docker context to OrbStack and enables Docker CLI shell completion on macOS. Docker itself is provided by OrbStack (cask, already installed); the module only wires up CLI ergonomics.

## Requirements

- Pin Docker context to `orbstack` so commands always target OrbStack
- Enable Docker CLI zsh completion
- Follow the existing `modules.programs.<name>.enable` pattern used by `git.nix`, `ssh.nix`, etc.

## Architecture

```
users/shared/programs/docker.nix    # New module (modules.programs.docker.enable)
users/shared/home-manager.nix       # Import + enable registration
tests/unit/docker-program-test.nix  # Unit test following ssh-program-test.nix pattern
```

## Design Decisions

- `DOCKER_CONTEXT=orbstack` set as a session variable — prevents accidental context drift and matches the socket symlink layout already in place (`/var/run/docker.sock` → OrbStack)
- Docker CLI completion added via `programs.zsh.initContent` using `docker completion zsh`
- **No** `~/.docker/config.json` management — OrbStack owns `credsStore=osxkeychain` and `currentContext`; overwriting would break login
- **No** docker CLI package — OrbStack bundles its own binary
- **No** aliases (`dps`, etc.) — not requested; OrbStack shell integration differs

## Testing

- `docker-program-test.nix` asserts:
  - `DOCKER_CONTEXT` session variable equals `orbstack`
  - zsh init content includes docker completion
  - No Home Manager deprecation warnings
