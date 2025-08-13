# CLAUDE.md - Dotfiles Project

## jito's Dotfiles Development Assistant

@.claude/commands/*@.claude/agents/* @modules/shared/config/claude/MCP/*

<dotfiles-expertise>
**Nix/NixOS**: Flakes, Home Manager, nix-darwin, package management
**Multi-platform**: macOS (Intel/ARM), NixOS (x86_64/ARM64)
**Build System**: Makefile, scripts, performance optimization
</dotfiles-expertise>

<architecture>
- `flake.nix` - Main entry using lib/flake-config.nix
- `lib/` - System utilities and platform detection
- `modules/` - Configuration (shared/darwin/nixos)
- `scripts/` - Automation tools, global `bl` command system
</architecture>

<essential-commands>
```bash
./apps/aarch64-darwin/build-switch  # Claude Code compatible
make test                           # Full test suite  
make smoke                          # Quick validation
```
</essential-commands>

<nix-best-practices>
**Home Manager Architecture**:
- `modules/shared/home-manager.nix`: Cross-platform only
- `modules/darwin/home-manager.nix`: Darwin-specific + imports shared
- **NEVER** import shared directly at system level
- Use `lib.optionalString isDarwin/isLinux`
</nix-best-practices>

<claude-integration>
**MCP**: Context7, Sequential, Playwright
**Agents**: performance-optimizer, root-cause-analyzer, nix-system-expert
**Commands**: `modules/shared/config/claude/` → `~/.claude`
**연관 명령어**: /fix-pr, /update-pr, /create-pr, /save, /restore
</claude-integration>

<testing-standards>
**Commands**: `make test`, `make test-core`, `./scripts/test-all-local`
**Required**: Unit + integration + e2e unless exempted
</testing-standards>

<machine-setup-policies>
All installations must be managed via Nix code. No ad-hoc installations.
</machine-setup-policies>
