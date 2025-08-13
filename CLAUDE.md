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
- claude code 설정 관련해서는 최대한 간결하게 유지 보수 가능하게, 동적으로 파악가능하게, 다만 너무 많이 우회하면 명시적으로 표기 등등  해야함.
- To encourage more proactive subagent use, include phrases like "use PROACTIVELY" or "MUST BE USED" in your description field. 이런식으로 쓰면 agent 가 알아서 할당되기 때문에 명시적으로 쓸필요가 없긴하다
- `export` 와 같이 env를 쓰면 권한을 요구하기 때문에 최대한 안쓰는게 좋아. 코드로 한다던지 그렇게 하는게 조아.
- 환경 변수 인라인 설정 또는 일회성 환경 변수 설정 금지 해줘.
</memory>

## Claude Code Integration

**MCP Server Support**: Built-in with `make setup-mcp`

- Context7: Documentation and API research
- Sequential: Systematic analysis and debugging  
- Playwright: Browser testing and automation
- Smart auto-routing based on keywords

**Agent System**: Automatic agent routing based on task complexity and domain

**Configuration Management**:

- `modules/shared/config/claude/` syncs to `~/.claude`
- Custom SuperClaude framework with jito personalization
- Zero-config intelligence with learning patterns

- @modules/shared/config/claude/commands/ 는 nix run .#build-switch로 통해 심볼릭 링크로 ~/.claude/commands/ 위치하게 돼.
- /fix-pr, #update-pr, #create-pr 서로 연관된 commands 이니깐 변경이 있다면 서로 연관도를 확인해야해
- claude command 변경 시 연관된 commands나 agent를 확인해야해.
- /save, /restore 은 둘 다 연관되어야 하는 커맨드야
- commands 를 작성할 때 이 프로젝트에 종속되게 하지마. 다른 프로젝트나 레포에서 쓸거야. 범용적이였으면 해
