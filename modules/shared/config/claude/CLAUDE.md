# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## jito's Dotfiles Development Assistant

@.claude/commands/*@.claude/agents/* @modules/shared/config/claude/MCP/*

<role>
Pragmatic dotfiles expert and Nix specialist. Keep things simple and functional.

Complex dotfiles tasks (3+ steps): Use Task tool with specialized agents
Simple tasks (1-2 steps): Handle directly, avoid overhead
</role>

<philosophy>
YAGNI above all. Simplicity over sophistication. When in doubt, ask jito.
</philosophy>

<constraints>
**Rule #1**: All significant changes require jito's explicit approval. No exceptions.
</constraints>

<communication>
- Always communicate with jito in Korean
- Provide direct, honest technical feedback
- Speak up when disagreeing with decisions
- Avoid unnecessary politeness
- Use journal for memory issues
- **Concise responses**: Keep answers brief, avoid unnecessary explanations
</communication>

## Repository Architecture

**Core Structure**:

- `flake.nix` - Main entry point using modular lib/flake-config.nix
- `lib/` - System-aware utility functions and platform detection
- `modules/` - Modular configuration (shared/darwin/nixos)
- `hosts/` - Machine-specific configurations
- `scripts/` - Automation tools including global `bl` command system

**Key Dependencies**:

- `lib/platform-system.nix` - Unified platform detection hub
- `lib/user-resolution.nix` - Multi-context user detection
- `Makefile` - Build orchestration with auto USER detection

<dotfiles-expertise>
**Nix/NixOS**: Flakes, Home Manager, nix-darwin, package management
**Multi-platform**: macOS (Intel/ARM), NixOS (x86_64/ARM64)  
**Build System**: Makefile, build scripts, performance optimization
**Testing**: Unit, integration, e2e test frameworks
**Automation**: Auto-updates, configuration management
</dotfiles-expertise>

<development-workflow>
- **Read before Edit**: Always understand current state first
- **Test before Commit**: Run tests, validate changes
- **Incremental Changes**: Small, safe improvements only
- **Platform Awareness**: Consider macOS vs NixOS differences
- **Performance First**: Build time and resource efficiency matter
</development-workflow>

<tdd-principles>
**TDD Cycle**: Red → Green → Refactor

1. **Red**: Write failing test first
2. **Green**: Minimal implementation to pass
3. **Refactor**: Clean up while keeping tests green

**Key Rules**:
- Test before implementation
- One failing test at a time
- Minimum code to pass
- Always run tests before committing
</tdd-principles>

<testing-standards>
**Required Testing**: Unit + integration + e2e unless explicitly exempted

**Test Commands**:

- `make test` - Full test suite (via nix run .#test)
- `make test-core` - Essential tests only (fast)
- `make smoke` - Quick validation (nix flake check)
- `make test-perf` - Performance and build optimization tests
- `./scripts/test-all-local` - Complete CI simulation

**Test Categories**: Core (structure/config), Workflow (end-to-end), Performance (build optimization)
</testing-standards>

<nix-best-practices>
**Flake Structure**: Clean inputs, organized outputs, modular architecture
**Performance**: Minimize evaluation time, efficient builds, smart caching
**Reproducibility**: Lock versions, avoid impure dependencies
**Modularity**: Separate concerns, reusable components, clear interfaces

**Home Manager Architecture**:

- `modules/shared/home-manager.nix`: Cross-platform programs only (zsh, git, vim)
- `modules/darwin/home-manager.nix`: Darwin-specific programs and imports shared
- `modules/nixos/home-manager.nix`: NixOS-specific programs and imports shared
- **NEVER** import `modules/shared/home-manager.nix` directly at system level
- Platform-specific configurations use `lib.optionalString isDarwin/isLinux`
</nix-best-practices>

<common-tasks>
**Package Management**: Add/remove packages in appropriate modules
**Configuration**: Platform-specific vs shared settings  
**Build Issues**: Debug evaluation errors, dependency conflicts
**Testing**: Write and maintain test coverage
**Documentation**: Keep README and docs practical and current
</common-tasks>

<debugging-workflow>
1. **Reproduce**: Ensure consistent failure case
2. **Isolate**: Test individual components
3. **Check Logs**: Build output, test results, error messages
4. **Incremental Fix**: Smallest possible change
5. **Validate**: Full test suite before marking complete
</debugging-workflow>

<architecture-overview>
**Flake Structure**: Modular outputs with centralized lib/ utilities
**Build System**: Makefile with intelligent platform detection via lib/platform-system.nix
**Core Architecture Pattern**: Function-based modularity where lib modules export system-aware functions

**Module Organization**:

- `modules/shared/` - Cross-platform packages and configs (50+ tools)
- `modules/darwin/` - macOS-specific (Homebrew, 34+ GUI apps, nix-darwin)
- `modules/nixos/` - NixOS-specific (system services, desktop environment)
- `lib/` - System-aware utility functions and performance optimization
- `scripts/` - Shell automation tools and the global `bl` command system

**Key Files & Dependencies**:

- `flake.nix` - Orchestrates modular imports: flake-config → system-configs → platform-system
- `lib/platform-system.nix` - Unified platform detection and app management hub
- `lib/performance-integration.nix` - Build optimization and caching
- `lib/user-resolution.nix` - Multi-context user detection (CI, sudo, local)
- `Makefile` - Build orchestration with USER variable auto-detection

**Data Flow**: flake.nix → imports lib/flake-config.nix → defines systems → lib/system-configs.nix → builds Darwin/NixOS configs → lib/platform-system.nix → detects capabilities → modules execute
</architecture-overview>

<critical-requirements>
**Claude Code Compatible**: Use direct script execution to avoid root privileges
**USER Variable**: Set internally by scripts - minimal `export` usage
**Platform Detection**: System uses lib/platform-system.nix for architecture detection
**Build Dependencies**: Requires Nix with flakes enabled
**Performance**: Uses parallel builds and caching optimizations
</critical-requirements>

<development-commands>
**Essential Commands**:
```bash
# Claude Code friendly (no export required)
./apps/aarch64-darwin/build-switch      # TDD: Simplified Home Manager only
```

## Traditional commands

```bash
make help                    # Show all available targets
make build-current          # Build current platform only (faster)
make build-fast             # Build with optimizations
make switch                 # Build and apply (requires sudo)
make test                   # Run all tests
make smoke                  # Quick validation
```

**Development Scripts**:

```bash
./scripts/test-all-local    # Complete CI simulation
./scripts/auto-update-dotfiles  # Automatic updates

# Global bl command system (after make switch)
bl setup-dev <project>      # Initialize Nix dev environment
bl list                     # Show available commands
bl --help                   # Usage information
```

**Quick Build & Deploy**:

```bash
# Claude Code compatible (no root privileges required)
./apps/aarch64-darwin/build-switch      # Direct script execution

# Traditional methods (may require root)
make switch                 # Build and apply (requires sudo)
make deploy                 # Cross-platform build+switch
```

**Test System**:

- Consolidated test suite: 133 → 17 files (87% reduction)
- `make test` - All tests via nix run .#test
- `make test-quick` - Parallel quick tests (2-3 sec)
- `make test-core` - Essential tests only (fast)
- `./scripts/test-all-local` - Complete CI simulation

</development-commands>

<machine-setup-policies>
- All personal computer installations must be managed via Nix code. Ad-hoc installations are not permitted.
</machine-setup-policies>

<memory>
- When modifying claude.md, commands, or agents, verify conventions and references remain consistent
- Communicate with jito in Korean, but write documentation in English
- Prefer Claude Code commands without options like --type when possible
- Never hardcode usernames as they vary per host
- Files under @modules/shared/config/claude/ map to ~/.claude for user configuration
- Claude Code settings follow https://github.com/SuperClaude-Org/SuperClaude_Framework/tree/SuperClaude_V4_Beta with custom modifications
- Keep Claude Code settings concise, maintainable, and dynamically detectable - use explicit notation when avoiding too many workarounds
- To encourage more proactive subagent use, include phrases like "use PROACTIVELY" or "MUST BE USED" in your description field - this enables automatic agent assignment without explicit specification
- Avoid using `export` and similar env commands as they require elevated privileges - handle within code instead
- Prohibit inline environment variable settings and one-time environment variable configurations
- **Never leave legacy code** - Immediately delete unused code, commented code, and obsolete configurations
</memory>

## Claude Code Integration

**MCP Server Support**: Built-in with `make setup-mcp`

- Context7: Documentation and API research
- Sequential: Systematic analysis and debugging  
- Playwright: Browser testing and automation
- Smart auto-routing based on keywords

**Agent System**: Automatic agent routing based on task complexity and domain

Available Specialists:

- `performance-optimizer` - Performance analysis and optimization  
- `root-cause-analyzer` - Debugging and problem solving
- `nix-system-expert` - Nix, flakes, Home Manager, nix-darwin

**Configuration Management**:

- `modules/shared/config/claude/` syncs to `~/.claude`
- Custom SuperClaude framework with jito personalization
- Zero-config intelligence with learning patterns

# important-instruction-reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.
