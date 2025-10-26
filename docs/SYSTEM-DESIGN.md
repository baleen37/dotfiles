# System Design & Technical Architecture

> **Deep dive into the technical architecture, design patterns, and implementation details**

## System Architecture Overview

The dotfiles system is built on a **layered, modular architecture** that provides maximum flexibility while maintaining system integrity and performance.

### Core Architectural Patterns

#### 1. **Layered Architecture Pattern**

```text
┌─────────────────────────────────────────────────────────────────┐
│                       PRESENTATION LAYER                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │  Makefile   │  │  CLI Tools  │  │     Claude Code         │ │
│  │  Commands   │  │   (`bl`)    │  │    Integration          │ │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│                      APPLICATION LAYER                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │   Build     │  │   Testing   │  │    Configuration        │ │
│  │   Scripts   │  │ Framework   │  │     Management          │ │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│                       DOMAIN LAYER                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │  Platform   │  │   Module    │  │     Performance         │ │
│  │ Detection   │  │ Resolution  │  │    Optimization         │ │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│                    INFRASTRUCTURE LAYER                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │     Nix     │  │    Home     │  │       Operating         │ │
│  │   System    │  │  Manager    │  │        System           │ │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

#### 2. **Module System Architecture**

The system uses a **hierarchical module system** with clear separation of concerns:

```text
flake.nix
    ├── lib/flake-config.nix          # Core flake structure
    ├── lib/system-configs.nix        # System builders
    └── lib/platform-system.nix       # Platform detection
        │
        ├── users/                     # User-centric organization (Mitchell-style)
        │   └── baleen/
        │       ├── darwin.nix       # ALL macOS system settings
        │       ├── nixos.nix        # ALL NixOS system settings
        │       ├── home.nix         # Home Manager entry point
        │       └── programs/        # Program-specific configs (flat structure)
        │           ├── git.nix
        │           ├── zsh.nix
        │           ├── vim.nix
        │           └── ...
```

#### 3. **Configuration Management Pattern**

Uses **externalized configuration** with intelligent defaults:

```text
Configuration Resolution Order:
1. Environment Variables      (Runtime overrides)
2. YAML Configuration Files   (Persistent settings)
3. Module Defaults           (Fallback values)
4. System Detection          (Auto-configuration)
```

## Core Components Deep Dive

### 🔧 Platform Detection System

#### `lib/platform-system.nix`

The platform detection system provides intelligent, multi-layered platform identification:

**Architecture Detection Flow:**

```nix
{
  detectSystem = system:
    let
      # Parse system string (e.g., "aarch64-darwin")
      systemParts = lib.splitString "-" system;
      architecture = lib.elemAt systemParts 0;  # aarch64, x86_64
      platform = lib.elemAt systemParts 1;     # darwin, linux

      # Capability detection
      capabilities = {
        hasHomebrew = platform == "darwin";
        hasSystemd = platform == "linux";
        supportsContainers = architecture == "x86_64" || platform == "linux";
        hasGUI = true; # Configurable per host
      };

      # Performance characteristics
      performance = {
        buildJobs = if architecture == "aarch64" then "auto" else 4;
        memoryLimit = if platform == "darwin" then "8GB" else "4GB";
        cacheSize = "5GB"; # Configurable
      };
    in {
      inherit system architecture platform capabilities performance;
      # Additional metadata...
    };
}
```

**Key Features:**

- **Automatic architecture detection** (Intel vs ARM)
- **Platform capability mapping** (Homebrew, systemd, etc.)
- **Performance characteristic detection** (optimal build settings)
- **Extensible metadata system** for custom properties

### 🏗️ Build System Architecture

#### Multi-Stage Build Process

The build system follows a **multi-stage, dependency-aware** approach:

```bash
# Stage 1: Environment Preparation
export USER=$(whoami)                    # User context
source apps/$PLATFORM_SYSTEM/config.sh  # Platform config
load_all_configs                        # External configuration

# Stage 2: Dependency Resolution
nix flake lock --update-input nixpkgs   # Lock dependencies
nix flake show                          # Validate structure

# Stage 3: Build Execution
nix build ".#$FLAKE_TARGET" \
  --max-jobs "$MAX_JOBS" \
  --cores "$BUILD_CORES" \
  --substitute-on-destination \
  --keep-going

# Stage 4: System Application
$REBUILD_COMMAND switch --flake . \
  --show-trace \
  --verbose
```

#### Performance Optimization Strategies

1. **Build Parallelization**

   ```bash
   # Intelligent job count detection
   if [[ "$CI" == "true" ]]; then
     MAX_JOBS=2  # Conservative for CI
   else
     MAX_JOBS="auto"  # Use all available cores
   fi
   ```

2. **Cache Management**

   ```bash
   # Multi-tier caching strategy
   BINARY_CACHES=(
     "https://cache.nixos.org"
     "https://nix-community.cachix.org"
     "https://dotfiles.cachix.org"  # Custom cache
   )
   ```

3. **Incremental Builds**

   ```bash
   # Build only changed components
   nix build --check ".#$TARGET" || {
     echo "Rebuilding changed components..."
     nix build ".#$TARGET"
   }
   ```

### 🧪 Testing Framework Architecture

#### Test Organization Pattern

The testing system uses a **pyramid testing strategy**:

```text
                    ┌─────────────────┐
                    │  Performance    │  ←─ 8 tests (Build optimization)
                    │     Tests       │     Execution: ~3min
                    └─────────────────┘
                          ▲
                    ┌─────────────────┐
                    │   End-to-End    │  ←─ 12 tests (Full workflows)
                    │     Tests       │     Execution: ~5min
                    └─────────────────┘
                          ▲
                    ┌─────────────────┐
                    │  Integration    │  ←─ 15 tests (Module interaction)
                    │     Tests       │     Execution: ~2min
                    └─────────────────┘
                          ▲
                    ┌─────────────────┐
                    │   Unit Tests    │  ←─ 17 tests (Function isolation)
                    │                 │     Execution: ~30s
                    └─────────────────┘
```

#### Test Implementation Pattern

All tests follow a **consistent structure**:

```nix
{ pkgs, flake ? null, src ? ../. }:

pkgs.runCommand "test-name"
{
  buildInputs = with pkgs; [ bash coreutils findutils ];
  # Test metadata
  meta = {
    description = "Test description";
    category = "unit|integration|e2e|performance";
    platforms = [ "darwin" "linux" ];
    timeout = 300; # seconds
  };
} ''
  # Test setup
  export HOME="$TMPDIR"
  export USER="test-user"

  # Test execution
  echo "🧪 Running ${test-name}"

  # Assertions with descriptive output
  if [[ condition ]]; then
    echo "✅ Test assertion passed"
  else
    echo "❌ Test assertion failed: details"
    exit 1
  fi

  # Cleanup and success marker
  touch $out
''
```

### 🤖 Claude Code Integration Architecture

#### MCP Server Integration Pattern

The Claude Code integration uses **Model Context Protocol** for enhanced capabilities:

```text
Claude Code
    │
    ├── MCP Server: Filesystem     ←─ File operations
    ├── MCP Server: Context7       ←─ Documentation search
    ├── MCP Server: Sequential     ←─ Multi-step analysis
    └── MCP Server: Playwright     ←─ Browser automation
            │
            └── Dotfiles Context   ←─ .claude/ configuration
                    │
                    ├── Commands/  ←─ 20+ specialized commands
                    ├── Agents/    ←─ Specialized AI agents
                    └── Memory/    ←─ Persistent learning
```

#### Command System Architecture

Commands follow a **plugin-based architecture**:

```markdown
# Command Structure
.claude/commands/{command-name}.md
    ├── metadata:          # Command description
    ├── parameters:        # Input validation
    ├── implementation:    # Core logic
    └── integration:       # System hooks
```

**Example Command Implementation:**

```markdown
# /build - Build and validate system

## Description
Builds the current platform configuration with validation and testing.

## Implementation
- Detect current platform and architecture
- Run appropriate build command with optimizations
- Execute test suite for validation
- Report build metrics and any issues

## Integration Points
- Uses `lib/platform-system.nix` for platform detection
- Integrates with testing framework via `make test`
- Provides performance metrics via build optimization system
```

## Design Patterns & Principles

### 🎯 SOLID Principles Implementation

#### Single Responsibility Principle

- **Modules**: Each module has one configuration concern
- **Scripts**: Each script handles one specific operation
- **Functions**: Each Nix function has a single, well-defined purpose

#### Open/Closed Principle

- **Extension Points**: New platforms via module addition
- **Plugin System**: Custom modules without core changes
- **Override Pattern**: User customizations via host configs

#### Liskov Substitution Principle

- **Platform Abstraction**: All platforms implement same interface
- **Module Interfaces**: Consistent module signatures
- **Test Implementations**: Platform-specific tests follow same contract

#### Interface Segregation Principle

- **Modular Interfaces**: Small, focused module interfaces
- **Configuration APIs**: Specific configuration functions
- **Platform APIs**: Platform-specific capabilities exposed separately

#### Dependency Inversion Principle

- **Abstraction Layers**: High-level modules don't depend on low-level details
- **Configuration Injection**: External configuration injection
- **Platform Independence**: Core logic independent of specific platforms

### 🔄 Functional Programming Patterns

#### Immutability

```nix
# All configurations are immutable
config = {
  packages = [ pkgs.git pkgs.vim ];
  # Cannot be modified after definition
};
```

#### Pure Functions

```nix
# Platform detection is deterministic
detectPlatform = system:
  # Pure function - same input always produces same output
  { platform = parseSystemString system; };
```

#### Composition

```nix
# Module composition pattern
systemConfig = lib.mkMerge [
  baseConfig
  platformConfig
  hostConfig
  userOverrides
];
```

#### Higher-Order Functions

```nix
# Module builders as higher-order functions
mkPlatformConfig = platform: modules:
  lib.foldr (module: config: module config) {} modules;
```

## Error Handling & Recovery

### 🛡️ Error Handling Strategy

#### 1. **Fail-Fast Pattern**

```bash
set -euo pipefail  # Immediate failure on any error
trap 'error_handler $? $LINENO' ERR
```

#### 2. **Graceful Degradation**

```nix
packages = lib.optionals (platform == "darwin") [
  # macOS-specific packages with fallbacks
] ++ lib.optionals (platform == "linux") [
  # Linux alternatives
];
```

#### 3. **Rollback Capabilities**

```bash
# Atomic system updates with rollback
nix-env --rollback  # Nix generations
darwin-rebuild --rollback  # Darwin generations
nixos-rebuild --rollback   # NixOS generations
```

#### 4. **Validation & Testing**

```bash
# Pre-deployment validation
nix flake check    # Syntax and type checking
make test         # Comprehensive test suite
make smoke        # Quick validation
```

### 🔧 Recovery Mechanisms

#### System Recovery

1. **Generation Rollback**: Revert to previous working configuration
2. **Cache Cleanup**: Clear corrupted build artifacts
3. **Dependency Reset**: Reset flake locks to known-good state
4. **Emergency Shell**: Nix shell with recovery tools

#### Configuration Recovery

1. **Git Reset**: Revert configuration changes
2. **Backup Restore**: Restore from automated backups
3. **Default Reset**: Return to system defaults
4. **Selective Recovery**: Recover specific modules only

## Performance Engineering

### ⚡ Performance Optimization Strategies

#### 1. **Build Performance**

```bash
# Parallel build optimization
MAX_JOBS=$(nproc)                    # Use all CPU cores
CORES=$(($(nproc) / 2))             # Reserve cores for system
NIX_BUILD_CORES=$CORES               # Nix-specific parallelization
```

#### 2. **Cache Optimization**

```nix
# Multi-level caching strategy
nix.settings = {
  substituters = [
    "https://cache.nixos.org"         # Official cache
    "https://nix-community.cachix.org" # Community cache
    "https://dotfiles.cachix.org"     # Custom cache
  ];

  # Cache configuration
  max-jobs = "auto";
  cores = 0;  # Use available cores
  keep-outputs = true;    # Cache build outputs
  keep-derivations = true; # Cache build plans
};
```

#### 3. **Evaluation Performance**

```nix
# Lazy evaluation optimization
config = lib.mkIf (enable) {
  # Only evaluate when needed
  expensive-computation = lib.mkMerge [
    # Defer expensive operations
  ];
};
```

#### 4. **Memory Management**

```bash
# Memory-aware builds
if [[ $(free -m | awk '/^Mem:/{print $2}') -lt 4096 ]]; then
  MAX_JOBS=1  # Conservative on low-memory systems
  export NIX_CONFIG="max-jobs = 1"
fi
```

### 📊 Performance Monitoring

#### Build Metrics Collection

```bash
# Performance data collection
start_time=$(date +%s)
build_size_before=$(du -sh /nix/store | cut -f1)

# Build operation
nix build ".#target"

# Metrics calculation
end_time=$(date +%s)
build_time=$((end_time - start_time))
build_size_after=$(du -sh /nix/store | cut -f1)

# Metrics reporting
echo "Build completed in ${build_time}s"
echo "Store size: ${build_size_before} → ${build_size_after}"
```

#### Resource Usage Tracking

```bash
# System resource monitoring during builds
monitor_resources() {
  while true; do
    echo "$(date): CPU=$(top -n1 | grep Cpu | awk '{print $2}') Memory=$(free | grep Mem | awk '{print ($3/$2)*100}')"
    sleep 5
  done
}
```

## Security Architecture

### 🔐 Security Design Principles

#### 1. **Principle of Least Privilege**

- **Build Process**: Runs with minimal required permissions
- **User Separation**: Build user separate from system user
- **Service Isolation**: Each service runs with minimal capabilities

#### 2. **Defense in Depth**

- **Input Validation**: All external inputs validated
- **Sandboxing**: Nix builds run in isolated sandboxes
- **Network Isolation**: Build processes have limited network access
- **Filesystem Isolation**: Restricted filesystem access during builds

#### 3. **Secrets Management**

```bash
# Age encryption for secrets
age --encrypt --recipient $(cat ~/.ssh/id_ed25519.pub) \
    --output secrets.age \
    plaintext-secret

# Automatic secret decryption in configurations
secrets.secretfile = {
  file = ./secrets.age;
  owner = config.user.name;
};
```

#### 4. **Secure Defaults**

```nix
# Security-focused default configurations
security = {
  # Disable unnecessary services
  sudo.wheelNeedsPassword = true;

  # Secure SSH configuration
  openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      PubkeyAuthentication = true;
    };
  };
};
```

This system design provides a robust, scalable, and maintainable architecture for cross-platform dotfiles management while maintaining security, performance, and extensibility.
