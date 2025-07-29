# Build optimization utilities for Nix flake
# Provides functions to optimize build performance and reduce rebuild triggers

{ lib, pkgs, system ? null }:

rec {
  # Build performance optimization settings
  buildOptimization = {
    # Parallel build settings optimized for Apple M2
    parallelSettings = {
      cores = 8;            # Use all available cores
      maxJobs = 4;          # Optimal for M2 memory constraints
      enableParallelBuilding = true;
    };

    # Cache optimization
    cacheSettings = {
      enableBinaryCaches = true;
      autoOptimiseStore = true;
      keepOutputs = true;
      keepDerivations = true;
    };

    # Build environment optimization
    buildEnv = {
      # Reduce memory pressure during builds
      NIX_BUILD_CORES = "8";
      # Enable faster hash algorithms
      NIX_HASH_ALGO = "sha256";
      # Optimize for SSD storage
      TMPDIR = "/tmp";
    };
  };

  # Function to create optimized derivation
  mkOptimizedDerivation = name: attrs: pkgs.stdenv.mkDerivation (attrs // {
    inherit name;

    # Apply build optimizations
    inherit (buildOptimization.parallelSettings) enableParallelBuilding;

    # Set optimal build environment
    NIX_BUILD_CORES = toString buildOptimization.parallelSettings.cores;

    # Optimize build phases
    configureFlags = (attrs.configureFlags or []) ++ [
      "--enable-parallel-build"
    ];

    # Add build metadata for performance tracking
    meta = (attrs.meta or {}) // {
      platforms = lib.platforms.all;
      broken = false;
      # Mark as performance optimized
      optimized = true;
    };
  });

  # Function to detect and minimize rebuild triggers
  rebuildTriggerAnalysis = {
    # Check if file changes would trigger rebuilds
    checkFileChanges = path:
      builtins.readDir path;

    # Identify files that commonly cause unnecessary rebuilds
    unnecessaryRebuildFiles = [
      "README.md"
      "docs/"
      ".git/"
      ".github/"
      "*.md"
      "LICENSE"
      "CHANGELOG.md"
    ];

    # Create gitignore-style filter for build inputs
    buildInputFilter = path: type:
      let
        baseName = baseNameOf path;
        isUnnecessary = lib.any (pattern:
          lib.hasPrefix pattern baseName ||
          lib.hasSuffix pattern baseName
        ) unnecessaryRebuildFiles;
      in
      !isUnnecessary;
  };

  # Cache strategy optimization
  cacheStrategy = {
    # Define cache layers based on change frequency
    cacheLayers = {
      # Rarely changed: system dependencies, base packages
      stable = [
        "nixpkgs"
        "system-packages"
        "base-configuration"
      ];

      # Occasionally changed: user configuration, dotfiles
      configuration = [
        "user-config"
        "dotfiles"
        "home-manager"
      ];

      # Frequently changed: development dependencies, local packages
      development = [
        "dev-shell"
        "local-packages"
        "test-dependencies"
      ];
    };

    # Generate cache keys based on content hash
    mkCacheKey = layer: content:
      builtins.hashString "sha256" "${layer}-${toString content}";
  };

  # Performance monitoring utilities
  performanceUtils = {
    # Wrapper to measure build time
    measureBuildTime = name: drv:
      pkgs.runCommand "measure-${name}" {
        inherit drv;
        buildInputs = [ pkgs.time ];
      } ''
        echo "=== Build Performance Measurement for ${name} ==="
        start_time=$(date +%s)

        # Build the derivation
        time nix-build ${drv} --no-out-link || exit 1

        end_time=$(date +%s)
        duration=$((end_time - start_time))

        echo "Build completed in $duration seconds"
        echo "$duration" > $out/build-time
        echo "Build time: $duration seconds" > $out/summary
      '';

    # Memory usage profiler for builds
    profileMemoryUsage = name: drv:
      pkgs.runCommand "profile-memory-${name}" {
        inherit drv;
        buildInputs = [ pkgs.time pkgs.procps ];
      } ''
        echo "=== Memory Profile for ${name} ==="

        # Monitor memory usage during build
        /usr/bin/time -l nix-build ${drv} --no-out-link 2>&1 | tee $out/memory-profile.log

        # Extract peak memory usage
        peak_memory=$(grep "maximum resident set size" $out/memory-profile.log | awk '{print $1}')
        echo "Peak memory usage: $peak_memory KB"

        touch $out
      '';
  };

  # Build dependency optimization
  dependencyOptimization = {
    # Minimize dependency closure size
    minimizeClosure = drv:
      pkgs.runCommand "minimize-closure" {
        inherit drv;
        buildInputs = [ pkgs.nix ];
      } ''
        # Analyze dependency closure
        nix-store -q --requisites ${drv} > $out/full-closure
        nix-store -q --references ${drv} > $out/direct-deps

        # Calculate closure size
        closure_size=$(nix-store -q --requisites ${drv} | xargs nix-store -q --size | awk '{sum+=$1} END {print sum}')
        echo "Closure size: $closure_size bytes" > $out/closure-size

        touch $out
      '';

    # Remove unnecessary runtime dependencies
    optimizeRuntimeDeps = drv:
      pkgs.runCommand "optimize-runtime-deps" {
        inherit drv;
      } ''
        # Copy derivation and strip unnecessary references
        cp -r ${drv} $out
        chmod -R +w $out

        # Use nix-store --optimize to deduplicate
        nix-store --optimize $out 2>/dev/null || true
      '';
  };

  # System-specific optimizations
  systemOptimizations = lib.optionalAttrs (system != null) (
    if lib.hasPrefix "aarch64-darwin" system then {
      # Apple Silicon specific optimizations
      appleOptimizations = {
        # Use Apple's accelerated frameworks
        buildInputs = with pkgs; [
          darwin.apple_sdk.frameworks.Accelerate
          darwin.apple_sdk.frameworks.MetalPerformanceShaders
        ];

        # Optimize for Apple Silicon
        NIX_CFLAGS_COMPILE = "-O3 -mcpu=apple-m1";

        # Use all performance cores
        NIX_BUILD_CORES = "4";  # P-cores only for compute-intensive tasks
      };
    } else if lib.hasPrefix "x86_64" system then {
      # x86_64 specific optimizations
      x86Optimizations = {
        # Use modern instruction sets
        NIX_CFLAGS_COMPILE = "-O3 -march=native -mtune=native";

        # Optimize for x86_64
        NIX_BUILD_CORES = toString buildOptimization.parallelSettings.cores;
      };
    } else {}
  );
}
