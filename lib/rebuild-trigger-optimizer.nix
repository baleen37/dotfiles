# Rebuild trigger optimization utilities
# Minimizes unnecessary rebuilds by optimizing file dependencies and input handling

{ lib, pkgs }:

rec {
  # File filter utilities to reduce rebuild triggers
  fileFilters = {
    # Standard exclusions that should not trigger rebuilds
    excludePatterns = [
      # Documentation and metadata
      "README.md" "*.md" "docs/" "LICENSE" "CHANGELOG.*"

      # Version control and CI/CD
      ".git/" ".github/" ".gitignore" ".gitlab-ci.yml"

      # IDE and editor files
      ".vscode/" ".idea/" "*.swp" "*.swo" "*~" ".DS_Store"

      # Performance and monitoring logs
      ".perf-logs/" "*.log" "build-*.json"

      # Temporary and cache files
      ".tmp/" "tmp/" "cache/" ".cache/" "result*"

      # Test artifacts that don't affect production builds
      "test-results/" "coverage/" ".nyc_output/"

      # Language-specific temporary files
      "node_modules/" "__pycache__/" ".pytest_cache/" "target/"
    ];

    # Create a path filter function
    mkPathFilter = additionalExcludes: path: type:
      let
        allExcludes = excludePatterns ++ (additionalExcludes or []);
        pathStr = toString path;
        baseName = baseNameOf path;

        # Check if path matches any exclude pattern
        matchesExclude = lib.any (pattern:
          # Direct match
          baseName == pattern ||
          # Suffix match (for extensions)
          lib.hasSuffix pattern baseName ||
          # Prefix match (for directories)
          lib.hasPrefix pattern baseName ||
          # Contains match (for paths)
          lib.hasInfix pattern pathStr
        ) allExcludes;
      in
      !matchesExclude;

    # Optimized source filtering
    filterSource = src: additionalExcludes:
      builtins.filterSource
        (fileFilters.mkPathFilter additionalExcludes)
        src;
  };

  # Dependency optimization
  dependencyOptimization = {
    # Split dependencies by stability to enable better caching
    categorizeDeps = deps: {
      # Stable dependencies (rarely change)
      stable = lib.filter (dep:
        lib.hasPrefix "nixpkgs" (dep.name or "") ||
        lib.elem (dep.pname or "") [
          "glibc" "gcc" "bash" "coreutils" "gnumake"
        ]
      ) deps;

      # Configuration dependencies (change occasionally)
      config = lib.filter (dep:
        lib.hasInfix "config" (dep.name or "") ||
        lib.hasInfix "settings" (dep.name or "")
      ) deps;

      # Development dependencies (change frequently)
      development = lib.filter (dep:
        lib.hasInfix "dev" (dep.name or "") ||
        lib.elem (dep.pname or "") [
          "nodejs" "python3" "rust" "go"
        ]
      ) deps;
    };

    # Create layered build inputs to optimize caching
    mkLayeredInputs = buildInputs: nativeBuildInputs: {
      # System layer (most stable)
      systemInputs = lib.filter (pkg:
        lib.hasPrefix "glibc" pkg.name ||
        lib.hasPrefix "gcc" pkg.name ||
        lib.elem pkg.pname [ "bash" "coreutils" "findutils" ]
      ) (buildInputs ++ nativeBuildInputs);

      # Tools layer (moderately stable)
      toolInputs = lib.filter (pkg:
        lib.elem pkg.pname [ "git" "curl" "wget" "gnumake" "cmake" ]
      ) (buildInputs ++ nativeBuildInputs);

      # Runtime layer (less stable)
      runtimeInputs = lib.filter (pkg:
        !(lib.elem pkg.pname [ "bash" "coreutils" "findutils" "git" "curl" "wget" "gnumake" "cmake" ]) &&
        !lib.hasPrefix "glibc" pkg.name &&
        !lib.hasPrefix "gcc" pkg.name
      ) buildInputs;
    };
  };

  # Content-based caching utilities
  contentCaching = {
    # Generate content-based hash for better cache invalidation
    mkContentHash = content:
      builtins.hashString "sha256" (toString content);

    # Create reproducible build environment
    mkReproducibleEnv = baseEnv: extraVars:
      baseEnv // extraVars // {
        # Normalize common variables that cause unnecessary rebuilds
        HOME = "/homeless-shelter";
        TMPDIR = "/tmp";
        # Remove timestamp-based variables
        SOURCE_DATE_EPOCH = "1";
        # Ensure deterministic locale
        LC_ALL = "C";
        LANG = "C";
      };

    # Smart source selection based on file types
    selectBuildSources = src: {
      # Core build files that should trigger rebuilds
      buildSources = lib.sourceFilesBySuffices src [
        ".nix" ".json" ".yaml" ".yml" ".toml"
        ".c" ".cpp" ".h" ".hpp" ".rs" ".go" ".py" ".js" ".ts"
        ".sh" ".bash" ".zsh" ".makefile" "Makefile" "CMakeLists.txt"
      ];

      # Configuration files
      configSources = lib.sourceFilesBySuffices src [
        ".conf" ".config" ".ini" ".env" ".properties"
      ];

      # Documentation (typically doesn't affect builds)
      docSources = lib.sourceFilesBySuffices src [
        ".md" ".txt" ".rst" ".adoc" ".tex"
      ];
    };
  };

  # Build phase optimization
  buildPhaseOptimization = {
    # Optimize configure phase to reduce rebuilds
    optimizedConfigurePhase = basePhase: ''
      # Use build optimization settings
      export NIX_BUILD_CORES=${toString 8}
      export MAKEFLAGS="-j$NIX_BUILD_CORES"

      # Enable ccache if available
      if command -v ccache >/dev/null; then
        export CC="ccache gcc"
        export CXX="ccache g++"
      fi

      # Run base configure phase
      ${basePhase}

      # Cache configure results
      if [ -f config.log ]; then
        cp config.log $TMPDIR/config-cache-$(date +%s).log
      fi
    '';

    # Optimize build phase for parallel execution
    optimizedBuildPhase = basePhase: ''
      # Maximize parallel compilation
      export MAKEFLAGS="-j$NIX_BUILD_CORES"

      # Use tmpfs for build if available (faster I/O)
      if [ -w /tmp ] && [ -d /tmp ]; then
        export TMPDIR="/tmp/nix-build-$$"
        mkdir -p "$TMPDIR"
      fi

      # Run base build phase
      ${basePhase}

      # Clean up temporary build artifacts
      find . -name "*.o" -o -name "*.lo" -o -name "*.tmp" | head -1000 | xargs rm -f
    '';

    # Optimize install phase
    optimizedInstallPhase = basePhase: ''
      # Create output directories efficiently
      mkdir -p $out/{bin,lib,share}

      # Run base install phase
      ${basePhase}

      # Post-install optimization
      # Strip debug symbols to reduce closure size
      if [ -d $out/bin ]; then
        find $out/bin -type f -executable | xargs ${pkgs.binutils}/bin/strip --strip-debug 2>/dev/null || true
      fi

      # Remove empty directories
      find $out -type d -empty -delete 2>/dev/null || true
    '';
  };

  # Flake optimization utilities
  flakeOptimization = {
    # Optimize flake inputs to reduce evaluation time
    optimizeInputs = inputs: {
      # Pin stable inputs to reduce update frequency
      stableInputs = lib.filterAttrs (name: input:
        lib.elem name [ "nixpkgs" "home-manager" "darwin" ]
      ) inputs;

      # Allow flexible updates for development inputs
      flexibleInputs = lib.filterAttrs (name: input:
        !lib.elem name [ "nixpkgs" "home-manager" "darwin" ]
      ) inputs;
    };

    # Create optimized flake outputs
    mkOptimizedOutputs = baseOutputs: system: {
      # Cache expensive computations
      lib = baseOutputs.lib or {} // {
        # Memoize expensive library functions
        utilsSystemCached = lib.mkMemoized (system:
          import ../lib/utils-system.nix {
            pkgs = import inputs.nixpkgs { inherit system; };
            lib = inputs.nixpkgs.lib;
          }
        );
      };

      # Optimize package builds
      packages = lib.mapAttrs (name: pkg:
        pkg.overrideAttrs (oldAttrs: {
          # Apply rebuild optimizations
          src = if oldAttrs ? src then
            fileFilters.filterSource oldAttrs.src []
          else oldAttrs.src;

          # Optimize build phases
          configurePhase = buildPhaseOptimization.optimizedConfigurePhase
            (oldAttrs.configurePhase or "");
          buildPhase = buildPhaseOptimization.optimizedBuildPhase
            (oldAttrs.buildPhase or "");
          installPhase = buildPhaseOptimization.optimizedInstallPhase
            (oldAttrs.installPhase or "");
        })
      ) (baseOutputs.packages.${system} or {});
    };
  };

  # Performance monitoring integration
  monitoringIntegration = {
    # Wrap derivation with performance monitoring
    withPerformanceMonitoring = name: drv:
      pkgs.runCommand "monitored-${name}" {
        inherit drv;
        buildInputs = [ pkgs.time ];
      } ''
        echo "=== Performance Monitor: ${name} ==="
        start_time=$(date +%s.%N)

        # Monitor build with detailed timing
        ${pkgs.time}/bin/time -v ${drv} 2>&1 | tee $out/performance.log

        end_time=$(date +%s.%N)
        duration=$(echo "$end_time - $start_time" | ${pkgs.bc}/bin/bc)

        echo "Total build time: $duration seconds" >> $out/performance.log

        # Extract key metrics
        grep -E "(Maximum resident set size|User time|System time)" $out/performance.log > $out/metrics.txt

        touch $out
      '';

    # Generate rebuild analysis report
    analyzeRebuildTriggers = name: buildLog:
      pkgs.runCommand "rebuild-analysis-${name}" {
        inherit buildLog;
      } ''
        echo "=== Rebuild Trigger Analysis: ${name} ==="

        # Analyze what caused the rebuild
        if grep -q "building path" ${buildLog}; then
          echo "❌ Full rebuild triggered" > $out/status
          grep "building path" ${buildLog} | head -5 > $out/rebuild-causes
        else
          echo "✅ Used cached result" > $out/status
        fi

        # Extract timing information
        grep -E "(real|user|sys)" ${buildLog} > $out/timing.txt || true

        touch $out
      '';
  };
}
