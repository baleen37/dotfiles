# Parallel build optimization for Nix flake
# Maximizes multi-core utilization and optimizes build parallelization

{
  lib,
  pkgs,
  system ? "aarch64-darwin",
}:

rec {
  # Hardware-specific optimizations based on system
  hardwareOptimization =
    if lib.hasPrefix "aarch64-darwin" system then
      {
        # Apple M2 optimization
        totalCores = 8;
        performanceCores = 4; # P-cores for compute-intensive tasks
        efficiencyCores = 4; # E-cores for background tasks
        memoryGB = 16;

        # Optimal settings for Apple Silicon
        optimalJobs = 4; # Conservative for memory constraints
        optimalCores = 8; # Use all cores for compilation

        # Build environment
        buildEnv = {
          NIX_BUILD_CORES = "8";
          MAKEFLAGS = "-j8";
          # Apple-specific optimizations
          CC = "clang";
          CXX = "clang++";
          # Use Apple's optimized libraries
          NIX_CFLAGS_COMPILE = "-O3 -mcpu=apple-m1 -mtune=apple-m1";
          NIX_LDFLAGS = "-L${pkgs.darwin.apple_sdk.frameworks.Accelerate}/lib";
        };
      }
    else if lib.hasPrefix "x86_64" system then
      {
        # x86_64 optimization
        totalCores = 8; # Assume typical 8-core system
        memoryGB = 16;

        optimalJobs = 6; # More aggressive parallelization
        optimalCores = 8;

        buildEnv = {
          NIX_BUILD_CORES = "8";
          MAKEFLAGS = "-j8";
          CC = "gcc";
          CXX = "g++";
          NIX_CFLAGS_COMPILE = "-O3 -march=native -mtune=native";
        };
      }
    else
      {
        # Generic fallback
        totalCores = 4;
        memoryGB = 8;
        optimalJobs = 2;
        optimalCores = 4;
        buildEnv = {
          NIX_BUILD_CORES = "4";
          MAKEFLAGS = "-j4";
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

    # Build resource limits
    buildTimeoutSeconds = 3600; # 1 hour max per build
    memoryLimitMB = hardwareOptimization.memoryGB * 1024 * 0.8; # 80% of RAM

    # Parallel-specific environment
    environment = hardwareOptimization.buildEnv // {
      # Optimize for parallel compilation
      CARGO_BUILD_JOBS = toString hardwareOptimization.optimalCores;
      GOMAXPROCS = toString hardwareOptimization.optimalCores;
      PYTHON_BUILD_JOBS = toString hardwareOptimization.optimalCores;

      # Memory optimization for parallel builds
      LINK_POOL_DEPTH = "4"; # Limit parallel linking to avoid OOM

      # Temporary directory optimization
      TMPDIR = "/tmp";

      # ccache configuration for faster rebuilds
      CCACHE_DIR = "\${HOME}/.cache/ccache";
      CCACHE_MAXSIZE = "2G";
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
        packages = lib.mapAttrs (name: pkg: buildOptimizations.optimizePackageForParallel pkg) (
          outputs.packages.${system} or { }
        );

        # Optimize development shell for parallel builds
        devShells = lib.mapAttrs (
          name: shell:
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
