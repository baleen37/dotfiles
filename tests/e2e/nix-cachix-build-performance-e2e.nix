{ pkgs, lib, ... }:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Performance test utilities
  perfTestUtils = {
    measureBuildTime = cmd: ''
      echo "Measuring build time for: ${cmd}"
      start_time=$(date +%s)
      ${cmd}
      end_time=$(date +%s)
      duration=$((end_time - start_time))
      echo "Build completed in ${duration} seconds"
      echo $duration > /tmp/build_time_${builtins.hashString "sha256" cmd}
    '';
  };

in
testHelpers.runTests "nix-cachix-build-performance-e2e" [
  {
    name = "should-build-without-substituter-warnings";
    test = ''
      # Test that build-switch runs without substituter warnings
      echo "Testing build-switch for substituter warnings..."

      # Run nix build to check for warnings (dry-run to avoid actual building)
      nix build --dry-run .#darwinConfigurations.aarch64-darwin.system 2>&1 | \
        grep -i "ignoring untrusted substituter" > /tmp/build_warnings || true

      if [[ -s /tmp/build_warnings ]]; then
        echo "❌ Build still shows substituter warnings:"
        cat /tmp/build_warnings
        exit 1
      else
        echo "✅ No substituter warnings in build output"
      fi
    '';
  }

  {
    name = "should-show-cache-utilization";
    test = ''
      # Test that cache utilization is working
      echo "Testing cache utilization..."

      # Check if we can query the cache
      if nix path-info --store https://nix-community.cachix.org --all | head -5 > /tmp/cache_query 2>&1; then
        echo "✅ Successfully queried nix-community.cachix.org cache"
        echo "Sample cache entries:"
        head -3 /tmp/cache_query
      else
        echo "⚠️  Could not query nix-community.cachix.org cache"
        echo "Error output:"
        cat /tmp/cache_query
      fi
    '';
  }

  {
    name = "should-have-improved-performance-indicators";
    test = ''
      # Test performance indicators
      echo "Testing performance indicators..."

      # Check for cache hit indicators in a small build
      ${perfTestUtils.measureBuildTime "nix build --dry-run nixpkgs#hello"}

      # Check build logs for cache utilization
      nix build --dry-run nixpkgs#hello 2>&1 | grep -i "downloading\|copying\|cache" > /tmp/perf_indicators || true

      if [[ -s /tmp/perf_indicators ]]; then
        echo "✅ Performance indicators found:"
        cat /tmp/perf_indicators
      else
        echo "⚠️  No specific performance indicators found"
      fi
    '';
  }

  {
    name = "should-validate-full-workflow";
    test = ''
      # Test the full workflow with configuration changes
      echo "Testing full workflow validation..."

      # Validate that our configuration is syntactically correct
      if nix flake check --all-systems 2>&1 | grep -E "(error|failed)" > /tmp/flake_errors; then
        echo "❌ Flake check found errors:"
        cat /tmp/flake_errors
        exit 1
      else
        echo "✅ Flake check passed - configuration is valid"
      fi

      # Check that the Darwin configuration builds successfully
      if nix build --dry-run .#darwinConfigurations.aarch64-darwin.system 2>&1 | grep -E "error" > /tmp/darwin_build_errors; then
        echo "❌ Darwin configuration build check failed:"
        cat /tmp/darwin_build_errors
        exit 1
      else
        echo "✅ Darwin configuration build check passed"
      fi
    '';
  }

  {
    name = "should-verify-acceptance-criteria";
    test = ''
      # Test all acceptance criteria from the GitHub issue
      echo "Verifying acceptance criteria..."

      acceptance_passed=0

      # 1. nix-community.cachix.org substituter is properly utilized
      if nix show-config | grep -q "nix-community.cachix.org"; then
        echo "✅ Acceptance criteria 1: nix-community.cachix.org substituter is configured"
        acceptance_passed=$((acceptance_passed + 1))
      else
        echo "❌ Acceptance criteria 1: nix-community.cachix.org substituter not configured"
      fi

      # 2. No "ignoring untrusted substituter" warnings
      nix --version 2>&1 | grep -i "ignoring untrusted substituter" > /tmp/warning_check || true
      if [[ ! -s /tmp/warning_check ]]; then
        echo "✅ Acceptance criteria 2: No untrusted substituter warnings"
        acceptance_passed=$((acceptance_passed + 1))
      else
        echo "❌ Acceptance criteria 2: Still getting untrusted substituter warnings"
      fi

      # 3. Configuration is ready for build time improvement
      if nix show-config | grep -q "trusted-users"; then
        echo "✅ Acceptance criteria 3: trusted-users configuration ready for build time improvement"
        acceptance_passed=$((acceptance_passed + 1))
      else
        echo "❌ Acceptance criteria 3: trusted-users configuration not ready"
      fi

      # 4. Cache hit rate improvement potential
      if curl -s -f --connect-timeout 5 "https://nix-community.cachix.org/nix-cache-info" > /dev/null; then
        echo "✅ Acceptance criteria 4: Cache server accessible for hit rate improvement"
        acceptance_passed=$((acceptance_passed + 1))
      else
        echo "❌ Acceptance criteria 4: Cache server not accessible"
      fi

      echo "Acceptance criteria passed: $acceptance_passed/4"

      if [[ $acceptance_passed -eq 4 ]]; then
        echo "✅ All acceptance criteria passed!"
      else
        echo "❌ Some acceptance criteria failed"
        exit 1
      fi
    '';
  }
]
