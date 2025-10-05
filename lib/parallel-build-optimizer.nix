# Parallel build optimization for Nix flake
# Maximizes multi-core utilization and optimizes build parallelization

{
  lib,
  pkgs,
  system ? "aarch64-darwin",
}:

rec {
  # Constants for build calculation rationale
  constants = {
    # Memory allocation
    memoryUsageRatio = 0.8; # Use 80% of available RAM for builds
    memoryPerJobMB = 2048; # Assume ~2GB per parallel job
    minMemoryMB = 4096; # Minimum 4GB for any build

    # Core allocation
    coreEfficiencyRatio = 0.75; # Use 75% of cores for jobs (leave room for system)
    minCores = 2; # Minimum cores to use
    maxJobsPerCore = 1.0; # Maximum 1 job per core

    # Build timeouts
    defaultTimeoutSeconds = 3600; # 1 hour default
    heavyBuildTimeoutSeconds = 7200; # 2 hours for heavy builds

    # Linking limits
    maxLinkPoolDepth = 4; # Limit parallel linking to avoid OOM

    # Ccache configuration
    ccacheSizeGB = 2; # Default ccache size
  };

  # Dynamic system detection
  # Note: Nix evaluation happens at build time, so we use heuristics based on system type
  # For more accurate detection, set NIX_BUILD_CORES environment variable
  systemDetection =
    let
      # Platform-based reasonable defaults (can be overridden by environment)
      platformDefaults =
        if lib.hasPrefix "aarch64-darwin" system then
          {
            # Apple Silicon: Most M1/M2 have 8 cores, M3 has 8-12
            # Conservative estimate for wide compatibility
            cores = 8;
            memory = 16;
          }
        else if lib.hasPrefix "x86_64-darwin" system then
          {
            # Intel Mac: Typically 4-8 cores
            cores = 8;
            memory = 16;
          }
        else if lib.hasPrefix "x86_64-linux" system then
          {
            # x86_64 Linux: Wide range, conservative estimate
            cores = 8;
            memory = 16;
          }
        else if lib.hasPrefix "aarch64-linux" system then
          {
            # ARM64 Linux: Server/workstation range
            cores = 8;
            memory = 16;
          }
        else
          {
            # Unknown platform fallback
            cores = 4;
            memory = 8;
          };

      # Try to get cores from environment variable (set by user or Nix daemon)
      envCores =
        let
          nixBuildCores = builtins.getEnv "NIX_BUILD_CORES";
        in
        if nixBuildCores != "" && nixBuildCores != "0" then
          lib.toInt nixBuildCores
        else
          platformDefaults.cores;

      # Try to get memory hint from environment (not standard, but useful)
      envMemory =
        let
          nixBuildMemory = builtins.getEnv "NIX_BUILD_MEMORY_GB";
        in
        if nixBuildMemory != "" then lib.toInt nixBuildMemory else platformDefaults.memory;
    in
    {
      # Detected/estimated hardware values
      totalCores = envCores;
      memoryGB = envMemory;
    };

  # Build calculation functions with documented rationale
  buildCalculations = {
    # Calculate optimal number of parallel jobs
    # Rationale: Balance parallelism with memory constraints
    # - Use 75% of cores to leave room for system processes
    # - Ensure we don't exceed 1 job per core
    # - Ensure we have enough memory (2GB per job)
    calculateMaxJobs =
      cores: memoryGB:
      let
        # Jobs based on cores (75% of available cores)
        coreBasedJobs = builtins.ceil (cores * constants.coreEfficiencyRatio);
        # Jobs based on memory (assume 2GB per job)
        memoryBasedJobs = builtins.floor (memoryGB * 1024 / constants.memoryPerJobMB);
        # Use the minimum to avoid overload
        maxJobs = lib.min coreBasedJobs memoryBasedJobs;
      in
      lib.max 1 maxJobs; # At least 1 job

    # Calculate cores to use for compilation
    # Rationale: Use all available cores for compilation (not the same as jobs)
    calculateBuildCores = cores: lib.max constants.minCores cores;

    # Calculate memory limit for builds
    # Rationale: Use 80% of available RAM to leave room for system
    calculateMemoryLimitMB = memoryGB: builtins.floor (memoryGB * 1024 * constants.memoryUsageRatio);

    # Calculate link pool depth
    # Rationale: Limit parallel linking to avoid OOM (linking is memory-intensive)
    calculateLinkPoolDepth = cores: lib.min constants.maxLinkPoolDepth (builtins.ceil (cores / 2));
  };

  # Hardware-specific optimizations based on system
  hardwareOptimization =
    let
      inherit (systemDetection) totalCores memoryGB;
      cores = totalCores;
    in
    if lib.hasPrefix "aarch64-darwin" system then
      {
        # Apple Silicon (M1/M2/M3) - dynamically detected
        totalCores = cores;
        inherit memoryGB;

        # Calculate optimal settings
        optimalJobs = buildCalculations.calculateMaxJobs cores memoryGB;
        optimalCores = buildCalculations.calculateBuildCores cores;

        # Build environment
        buildEnv = {
          NIX_BUILD_CORES = toString cores;
          MAKEFLAGS = "-j${toString cores}";
          # Apple-specific optimizations
          CC = "clang";
          CXX = "clang++";
          # Use Apple's optimized libraries
          NIX_CFLAGS_COMPILE = "-O3 -mcpu=apple-m1 -mtune=apple-m1";
          NIX_LDFLAGS = "-L${pkgs.darwin.apple_sdk.frameworks.Accelerate}/lib";
        };
      }
    else if lib.hasPrefix "x86_64-darwin" system then
      {
        # Intel Mac - dynamically detected
        totalCores = cores;
        inherit memoryGB;

        optimalJobs = buildCalculations.calculateMaxJobs cores memoryGB;
        optimalCores = buildCalculations.calculateBuildCores cores;

        buildEnv = {
          NIX_BUILD_CORES = toString cores;
          MAKEFLAGS = "-j${toString cores}";
          CC = "clang";
          CXX = "clang++";
          NIX_CFLAGS_COMPILE = "-O3 -march=native -mtune=native";
        };
      }
    else if lib.hasPrefix "x86_64-linux" system || lib.hasPrefix "aarch64-linux" system then
      {
        # Linux (x86_64 or ARM64) - dynamically detected
        totalCores = cores;
        inherit memoryGB;

        optimalJobs = buildCalculations.calculateMaxJobs cores memoryGB;
        optimalCores = buildCalculations.calculateBuildCores cores;

        buildEnv = {
          NIX_BUILD_CORES = toString cores;
          MAKEFLAGS = "-j${toString cores}";
          CC = "gcc";
          CXX = "g++";
          NIX_CFLAGS_COMPILE = "-O3 -march=native -mtune=native";
        };
      }
    else
      {
        # Generic fallback - use detected values or minimums
        totalCores = lib.max constants.minCores cores;
        memoryGB = lib.max 8 memoryGB;
        optimalJobs = buildCalculations.calculateMaxJobs (lib.max constants.minCores cores) (
          lib.max 8 memoryGB
        );
        optimalCores = buildCalculations.calculateBuildCores (lib.max constants.minCores cores);
        buildEnv = {
          NIX_BUILD_CORES = toString (lib.max constants.minCores cores);
          MAKEFLAGS = "-j${toString (lib.max constants.minCores cores)}";
        };
      };

  # Parallel build configuration
  parallelBuildConfig = {
    # Core settings
    cores = hardwareOptimization.optimalCores;
    maxJobs = hardwareOptimization.optimalJobs;

    # Advanced parallel settings
    parallelInstalling = true;
    enableParallelBuilding = true;

    # Build resource limits (using calculated values)
    buildTimeoutSeconds = constants.defaultTimeoutSeconds;
    memoryLimitMB = buildCalculations.calculateMemoryLimitMB hardwareOptimization.memoryGB;

    # Parallel-specific environment
    environment = hardwareOptimization.buildEnv // {
      # Optimize for parallel compilation
      CARGO_BUILD_JOBS = toString hardwareOptimization.optimalCores;
      GOMAXPROCS = toString hardwareOptimization.optimalCores;
      PYTHON_BUILD_JOBS = toString hardwareOptimization.optimalCores;

      # Memory optimization for parallel builds (using calculated value)
      LINK_POOL_DEPTH = toString (
        buildCalculations.calculateLinkPoolDepth hardwareOptimization.totalCores
      );

      # Temporary directory optimization
      TMPDIR = "/tmp";

      # ccache configuration for faster rebuilds (using constant)
      CCACHE_DIR = "\${HOME}/.cache/ccache";
      CCACHE_MAXSIZE = "${toString constants.ccacheSizeGB}G";
      CCACHE_COMPILERCHECK = "content";
    };
  };

  # Build optimization utilities
  buildOptimizations = {
    # Create optimized derivation with parallel settings
    mkOptimizedDerivation =
      name: attrs:
      pkgs.stdenv.mkDerivation (
        attrs
        // {
          inherit name;

          # Apply parallel build settings
          inherit (parallelBuildConfig) enableParallelBuilding;

          # Set build environment
          NIX_BUILD_CORES = toString parallelBuildConfig.cores;
          MAX_JOBS = toString parallelBuildConfig.maxJobs;

          # Apply environment optimizations
          buildInputs = (attrs.buildInputs or [ ]) ++ [
            pkgs.ccache # For faster C/C++ compilation
          ];

          # Optimized build phases
          configurePhase = ''
            # Setup parallel build environment
            export NIX_BUILD_CORES=${toString parallelBuildConfig.cores}
            export MAKEFLAGS="-j$NIX_BUILD_CORES"
            export CARGO_BUILD_JOBS="$NIX_BUILD_CORES"
            export GOMAXPROCS="$NIX_BUILD_CORES"

            # Setup ccache if available
            if command -v ccache >/dev/null; then
              export CC="ccache $CC"
              export CXX="ccache $CXX"
              ccache --max-size=2G
              ccache --set-config=compiler_check=content
            fi

            ${attrs.configurePhase or ""}
          '';

          buildPhase = ''
            # Maximize parallel execution
            export MAKEFLAGS="-j$NIX_BUILD_CORES"

            # Monitor memory usage during build
            echo "Starting parallel build with $NIX_BUILD_CORES cores"

            # Use ramdisk for temporary files if available
            if [ -w /tmp ] && [ "$(df -h /tmp | tail -1 | awk '{print $4}' | sed 's/G//')" -gt 1 ]; then
              export TMPDIR="/tmp/nix-build-$$"
              mkdir -p "$TMPDIR"
            fi

            ${attrs.buildPhase or ""}

            # Clean up parallel build artifacts
            find . -name "*.o" -o -name "*.lo" | head -1000 | xargs rm -f 2>/dev/null || true
          '';

          # Add metadata for performance tracking
          meta = (attrs.meta or { }) // {
            optimizedForParallel = true;
            buildCores = parallelBuildConfig.cores;
            inherit (parallelBuildConfig) maxJobs;
          };
        }
      );

    # Optimize existing package for parallel build
    optimizePackageForParallel =
      pkg:
      pkg.overrideAttrs (oldAttrs: {
        # Enable parallel building if not already set
        enableParallelBuilding = true;

        # Add parallel build environment
        NIX_BUILD_CORES = toString parallelBuildConfig.cores;
        MAKEFLAGS = "-j${toString parallelBuildConfig.cores}";

        # Add ccache support for C/C++ packages
        buildInputs =
          (oldAttrs.buildInputs or [ ])
          ++ lib.optionals (lib.any (
            input: lib.hasPrefix "gcc" input.name || lib.hasPrefix "clang" input.name
          ) (oldAttrs.buildInputs or [ ])) [ pkgs.ccache ];
      });
  };

  # Language-specific parallel optimizations
  languageOptimizations = {
    # Rust parallel build optimization
    rust = {
      cargoParallelJobs = parallelBuildConfig.cores;
      environment = {
        CARGO_BUILD_JOBS = toString parallelBuildConfig.cores;
        CARGO_BUILD_RUSTFLAGS = "-C target-cpu=native -C opt-level=3";
        # Use lld for faster linking
        CARGO_TARGET_AARCH64_APPLE_DARWIN_LINKER = lib.optionalString (system == "aarch64-darwin") "lld";
      };

      # Rust-specific build phase optimization
      buildPhase = ''
        export CARGO_BUILD_JOBS=$NIX_BUILD_CORES
        cargo build --release --jobs $NIX_BUILD_CORES
      '';
    };

    # Go parallel build optimization
    go = {
      environment = {
        GOMAXPROCS = toString parallelBuildConfig.cores;
        CGO_ENABLED = "1";
        GO_BUILD_FLAGS = "-p ${toString parallelBuildConfig.cores}";
      };

      buildPhase = ''
        export GOMAXPROCS=$NIX_BUILD_CORES
        go build -p $NIX_BUILD_CORES -v ./...
      '';
    };

    # Node.js parallel build optimization
    nodejs = {
      environment = {
        UV_THREADPOOL_SIZE = toString parallelBuildConfig.cores;
        NODE_OPTIONS = "--max-old-space-size=${toString (parallelBuildConfig.memoryLimitMB / 2)}";
      };

      buildPhase = ''
        export UV_THREADPOOL_SIZE=$NIX_BUILD_CORES
        npm run build --parallel=$NIX_BUILD_CORES || npm run build
      '';
    };

    # Python parallel build optimization
    python = {
      environment = {
        PYTHON_BUILD_JOBS = toString parallelBuildConfig.cores;
        SETUPTOOLS_USE_DISTUTILS = "stdlib";
      };

      buildPhase = ''
        export PYTHON_BUILD_JOBS=$NIX_BUILD_CORES
        python setup.py build -j $NIX_BUILD_CORES || python setup.py build
      '';
    };
  };

  # Dependency-aware parallel building
  dependencyOptimization = {
    # Analyze build dependencies to optimize parallel execution
    analyzeBuildDeps = buildInputs: {
      # Categorize dependencies by build complexity
      lightDeps = lib.filter (
        dep:
        lib.elem (dep.pname or "") [
          "bash"
          "coreutils"
          "findutils"
          "grep"
        ]
      ) buildInputs;

      mediumDeps = lib.filter (
        dep:
        lib.elem (dep.pname or "") [
          "git"
          "curl"
          "wget"
          "cmake"
          "pkg-config"
        ]
      ) buildInputs;

      heavyDeps = lib.filter (
        dep:
        lib.elem (dep.pname or "") [
          "llvm"
          "gcc"
          "rust"
          "go"
          "nodejs"
          "python3"
        ]
      ) buildInputs;
    };

    # Create dependency-aware build plan
    mkParallelBuildPlan =
      buildInputs:
      let
        depAnalysis = dependencyOptimization.analyzeBuildDeps buildInputs;
      in
      {
        # Build light dependencies first (fast, parallel)
        phase1 = {
          dependencies = depAnalysis.lightDeps;
          parallelism = parallelBuildConfig.maxJobs;
          inherit (parallelBuildConfig) cores;
        };

        # Build medium dependencies (moderate parallelism)
        phase2 = {
          dependencies = depAnalysis.mediumDeps;
          parallelism = parallelBuildConfig.maxJobs / 2;
          inherit (parallelBuildConfig) cores;
        };

        # Build heavy dependencies (limited parallelism to avoid OOM)
        phase3 = {
          dependencies = depAnalysis.heavyDeps;
          parallelism = 1;
          inherit (parallelBuildConfig) cores;
        };
      };
  };

  # Build monitoring and profiling
  buildMonitoring = {
    # Wrap build with performance monitoring
    withBuildProfiling =
      name: drv:
      pkgs.runCommand "profiled-${name}"
        {
          inherit drv;
          buildInputs = [
            pkgs.time
            pkgs.htop
          ];
        }
        ''
                  echo "=== Parallel Build Profile: ${name} ==="

                  # Start system monitoring
                  top -l 1 -n 0 > $out/system-before.txt &

                  # Profile the build
                  start_time=$(date +%s.%N)
                  ${pkgs.time}/bin/time -v ${drv} 2>&1 | tee $out/build-profile.log
                  build_result=$?
                  end_time=$(date +%s.%N)

                  # Calculate metrics
                  duration=$(echo "$end_time - $start_time" | ${pkgs.bc}/bin/bc)
                  echo "Build duration: $duration seconds" >> $out/build-profile.log

                  # Extract parallel build metrics
                  cpu_usage=$(grep "Percent of CPU" $out/build-profile.log | sed 's/.*: //' || echo "Unknown")
                  max_memory=$(grep "Maximum resident set size" $out/build-profile.log | sed 's/.*: //' || echo "Unknown")

                  # Generate summary
                  cat > $out/summary.json << EOF
          {
            "name": "${name}",
            "duration_seconds": $duration,
            "cpu_usage_percent": "$cpu_usage",
            "max_memory_kb": "$max_memory",
            "parallel_cores": ${toString parallelBuildConfig.cores},
            "max_jobs": ${toString parallelBuildConfig.maxJobs},
            "build_result": $build_result
          }
          EOF

                  exit $build_result
        '';

    # Generate parallel build efficiency report
    analyzeBuildEfficiency =
      buildLogs:
      pkgs.runCommand "build-efficiency-analysis"
        {
          inherit buildLogs;
        }
        ''
                  echo "=== Parallel Build Efficiency Analysis ==="

                  # Analyze CPU utilization patterns
                  total_builds=0
                  efficient_builds=0

                  for log in ${lib.concatStringsSep " " buildLogs}; do
                    if [ -f "$log/summary.json" ]; then
                      total_builds=$((total_builds + 1))

                      cpu_usage=$(jq -r '.cpu_usage_percent' "$log/summary.json" | sed 's/%//')
                      if [ "$cpu_usage" -gt 300 ]; then  # Good parallel utilization
                        efficient_builds=$((efficient_builds + 1))
                      fi
                    fi
                  done

                  efficiency_ratio=$(echo "scale=2; $efficient_builds * 100 / $total_builds" | ${pkgs.bc}/bin/bc)

                  cat > $out << EOF
          Parallel Build Efficiency Report
          ================================

          Total builds analyzed: $total_builds
          Efficiently parallelized: $efficient_builds
          Efficiency ratio: $efficiency_ratio%

          Recommendations:
          - Target CPU utilization: >300% (indicates good parallelization)
          - Monitor memory usage to avoid OOM with high parallelism
          - Adjust max-jobs based on build complexity
          EOF
        '';
  };

  # Integration with flake configuration
  flakeIntegration = {
    # Apply parallel optimizations to flake outputs
    optimizeFlakeOutputs =
      outputs: system:
      outputs
      // {
        # Optimize packages for parallel building
        packages = lib.mapAttrs (_name: pkg: buildOptimizations.optimizePackageForParallel pkg) (
          outputs.packages.${system} or { }
        );

        # Optimize development shell for parallel builds
        devShells = lib.mapAttrs (
          _name: shell:
          shell.overrideAttrs (oldAttrs: {
            inherit (parallelBuildConfig.environment) NIX_BUILD_CORES MAKEFLAGS;
            shellHook = (oldAttrs.shellHook or "") + ''
              echo "Parallel build environment configured:"
              echo "  Cores: ${toString parallelBuildConfig.cores}"
              echo "  Max jobs: ${toString parallelBuildConfig.maxJobs}"
              echo "  Build flags: $MAKEFLAGS"
            '';
          })
        ) (outputs.devShells.${system} or { });
      };
  };
}
