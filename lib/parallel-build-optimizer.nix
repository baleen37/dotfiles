# Parallel Build Optimization for Nix Flake
# Environment-variable-based configuration for multi-core builds
#
# Design: Simplified from hardware detection approach (which doesn't work at
# Nix evaluation time) to explicit environment variable configuration.
#
# Configuration via environment variables:
#   NIX_BUILD_CORES: Number of cores for compilation (default: 8)
#   NIX_BUILD_MEMORY_GB: Available memory in GB (default: 16)
#
# Usage:
#   export NIX_BUILD_CORES=12
#   export NIX_BUILD_MEMORY_GB=32
#   make build-current

{
  lib,
  pkgs,
  system ? "aarch64-darwin",
}:

let
  # Configuration constants
  constants = {
    # Defaults (user should override via env vars for their hardware)
    defaultCores = 8;
    defaultMemoryGB = 16;

    # Build calculation ratios
    coreEfficiencyRatio = 0.75; # Use 75% of cores for jobs
    memoryUsageRatio = 0.8; # Use 80% of RAM
    memoryPerJobMB = 2048; # ~2GB per parallel job
    maxLinkPoolDepth = 4; # Limit parallel linking

    # Defaults for unknown values
    minCores = 2;
    minMemoryGB = 4;
  };

  # Read configuration from environment variables
  envCores =
    let
      value = builtins.getEnv "NIX_BUILD_CORES";
    in
    if value != "" && value != "0" then lib.toInt value else constants.defaultCores;

  envMemoryGB =
    let
      value = builtins.getEnv "NIX_BUILD_MEMORY_GB";
    in
    if value != "" then lib.toInt value else constants.defaultMemoryGB;

  # Build calculation functions
  calculateMaxJobs =
    cores: memoryGB:
    let
      coreBasedJobs = builtins.ceil (cores * constants.coreEfficiencyRatio);
      memoryBasedJobs = builtins.floor (memoryGB * 1024 / constants.memoryPerJobMB);
      maxJobs = lib.min coreBasedJobs memoryBasedJobs;
    in
    lib.max 1 maxJobs;

  calculateMemoryLimitMB = memoryGB: builtins.floor (memoryGB * 1024 * constants.memoryUsageRatio);

  calculateLinkPoolDepth = cores: lib.min constants.maxLinkPoolDepth (builtins.ceil (cores / 2));

  # Platform-specific compiler settings
  platformCompiler =
    if lib.hasPrefix "aarch64-darwin" system then
      {
        CC = "clang";
        CXX = "clang++";
        NIX_CFLAGS_COMPILE = "-O3 -mcpu=apple-m1";
      }
    else if lib.hasPrefix "x86_64-darwin" system then
      {
        CC = "clang";
        CXX = "clang++";
        NIX_CFLAGS_COMPILE = "-O3 -march=native";
      }
    else if lib.hasPrefix "x86_64-linux" system || lib.hasPrefix "aarch64-linux" system then
      {
        CC = "gcc";
        CXX = "g++";
        NIX_CFLAGS_COMPILE = "-O3 -march=native";
      }
    else
      {
        CC = "gcc";
        CXX = "g++";
        NIX_CFLAGS_COMPILE = "-O3";
      };

  # Calculated build settings
  cores = lib.max constants.minCores envCores;
  memoryGB = lib.max constants.minMemoryGB envMemoryGB;
  maxJobs = calculateMaxJobs cores memoryGB;
  memoryLimitMB = calculateMemoryLimitMB memoryGB;
  linkPoolDepth = calculateLinkPoolDepth cores;

in
rec {
  # Export configuration constants
  inherit constants;

  # Hardware configuration (from environment)
  hardwareConfig = {
    inherit cores memoryGB;
    source = "environment-variables";
  };

  # Parallel build configuration
  parallelBuildConfig = {
    inherit cores maxJobs;
    inherit memoryLimitMB;

    # Build settings
    enableParallelBuilding = true;
    parallelInstalling = true;

    # Build environment
    environment = platformCompiler // {
      NIX_BUILD_CORES = toString cores;
      MAKEFLAGS = "-j${toString cores}";

      # Language-specific settings
      CARGO_BUILD_JOBS = toString cores;
      GOMAXPROCS = toString cores;
      PYTHON_BUILD_JOBS = toString cores;

      # Memory optimization
      LINK_POOL_DEPTH = toString linkPoolDepth;

      # Temporary directory
      TMPDIR = "/tmp";

      # ccache for faster C/C++ rebuilds
      CCACHE_DIR = "\${HOME}/.cache/ccache";
      CCACHE_MAXSIZE = "2G";
    };
  };

  # Build optimization utilities
  buildOptimizations = {
    # Create optimized derivation
    mkOptimizedDerivation =
      name: attrs:
      pkgs.stdenv.mkDerivation (
        attrs
        // {
          inherit name;
          inherit (parallelBuildConfig) enableParallelBuilding;

          NIX_BUILD_CORES = toString cores;
          MAX_JOBS = toString maxJobs;

          buildInputs = (attrs.buildInputs or [ ]) ++ [ pkgs.ccache ];

          configurePhase = ''
            export NIX_BUILD_CORES=${toString cores}
            export MAKEFLAGS="-j$NIX_BUILD_CORES"

            # Setup ccache
            if command -v ccache >/dev/null; then
              export CC="ccache $CC"
              export CXX="ccache $CXX"
              ccache --max-size=2G
            fi

            ${attrs.configurePhase or ""}
          '';

          meta = (attrs.meta or { }) // {
            optimizedForParallel = true;
            inherit (parallelBuildConfig) cores maxJobs;
          };
        }
      );

    # Optimize existing package
    optimizePackageForParallel =
      pkg:
      pkg.overrideAttrs (_oldAttrs: {
        enableParallelBuilding = true;
        NIX_BUILD_CORES = toString cores;
        MAKEFLAGS = "-j${toString cores}";
      });
  };

  # Language-specific optimizations
  languageOptimizations = {
    rust = {
      environment = {
        CARGO_BUILD_JOBS = toString cores;
        CARGO_BUILD_RUSTFLAGS = "-C target-cpu=native -C opt-level=3";
      };
    };

    go = {
      environment = {
        GOMAXPROCS = toString cores;
        GO_BUILD_FLAGS = "-p ${toString cores}";
      };
    };

    nodejs = {
      environment = {
        UV_THREADPOOL_SIZE = toString cores;
        NODE_OPTIONS = "--max-old-space-size=${toString (memoryLimitMB / 2)}";
      };
    };

    python = {
      environment = {
        PYTHON_BUILD_JOBS = toString cores;
      };
    };
  };

  # Version and metadata
  version = "2.0.0-simplified";
  description = "Environment-variable-based parallel build optimization";
}
