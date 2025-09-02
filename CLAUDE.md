# CLAUDE.md

Nix-based dotfiles for macOS/NixOS using flakes, Home Manager, nix-darwin.

## Commands

```bash
# Build & Apply (set USER first)
export USER=$(whoami)
./apps/[platform]/build-switch    # Direct platform build
make build-switch                 # Alternative approach

# Testing
make test-core                    # Essential tests  
make test                         # Full test suite
make smoke                        # Quick validation

# Direct Nix
nix run --impure .#build-switch   # Build with sudo handling
```

## Architecture

**Structure:** `flake.nix` → `lib/` (platform detection) → `modules/` (shared/darwin/nixos) → `hosts/`

**Home Manager Rules:**

- `shared/home-manager.nix`: Cross-platform only
- Platform modules: Import shared, add platform-specific
- Never import shared directly at system level
- Use `lib.optionalString isDarwin/isLinux` for conditionals

**Packages:** All via Nix (`modules/shared/packages.nix`), macOS apps via `modules/darwin/casks.nix`, Python via `uv`

## Claude Code

**MCP:** Context7, Sequential, Playwright (`make setup-mcp`)

**Configuration:** Located `modules/shared/config/claude/` → symlinked to `~/.claude/`

- Commands: `/analyze`, `/build`, `/commit`, `/create-pr`, `/debug`, `/implement`, etc.
- Agents: `backend-engineer`, `frontend-specialist`, `system-architect`, `test-automator`, etc.
- Settings: Permission, environment, MCP configuration

**Design Principles:**

- Use Context7 for documentation/settings changes
- Flag minimalism: Only `-u` (update) and `-tdd` flags allowed
- Natural language commands, avoid cryptic abbreviations
- Token efficiency: Concise prompts, meta-prompting over direct instructions
- Require approval for command/instruction changes
- **Reference Direction**: Commands may reference agents, agents must not reference commands
- **Command Isolation**: Commands must not reference other commands to maintain modularity and avoid circular dependencies

## Development

**Testing:** Unit + integration + E2E required. `make smoke` before commits, `make test` before PRs.

**Policies:**

- All installations via Nix (declarative configuration)
- Platform-specific → respective modules (darwin/nixos)  
- Cross-platform → shared modules with conditionals
- Context7 first for Nix/Home Manager API updates
- Use modern `run`, avoid deprecated `$DRY_RUN_CMD`

**Global Commands:** `bl` dispatcher system (`~/.bl/commands/`), extensible via Nix.

**Path Convention:** Use relative paths (`~/`, `./`) not absolute paths.
