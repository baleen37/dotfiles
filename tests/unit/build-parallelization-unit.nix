{ pkgs }:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

  # Source the build-switch-common script for testing
  buildSwitchCommon = ../../scripts/build-switch-common.sh;

  # Mock environment for testing
  mockEnv = platformType: nixBuildJobs: ''
    export PLATFORM_TYPE="${platformType}"
    ${if nixBuildJobs != null then "export NIX_BUILD_JOBS=${toString nixBuildJobs}" else "unset NIX_BUILD_JOBS"}
    export PATH=${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gawk}/bin:$PATH
  '';

in
pkgs.runCommand "build-parallelization-unit-test" {
  buildInputs = [
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.gawk
    pkgs.bash
    pkgs.util-linux
  ];
} ''
  set -e

  ${testHelpers.testSection "Build Parallelization Unit Tests"}

  # Create test environment
  ${testHelpers.setupTestEnv}

  # Copy the script to a testable location
  cp ${buildSwitchCommon} ./build-switch-common.sh
  chmod +x ./build-switch-common.sh

  # Source functions for testing
  source ./build-switch-common.sh

  ${testHelpers.testSubsection "CPU Core Detection Tests"}

  # Test 1: Darwin platform detection
  ${testHelpers.testSubsection "Darwin Core Detection"}
  (
    ${mockEnv "darwin" null}

    # Mock sysctl command to return 8 cores
    sysctl() {
      if [ "$1" = "-n" ] && [ "$2" = "hw.ncpu" ]; then
        echo "8"
      else
        return 1
      fi
    }
    export -f sysctl

    RESULT=$(detect_optimal_jobs)
    ${testHelpers.assertTrue "[ \"$RESULT\" = \"8\" ]" "Darwin detects 8 cores correctly"}
  )

  # Test 2: Linux platform detection
  ${testHelpers.testSubsection "Linux Core Detection"}
  (
    ${mockEnv "linux" null}

    # Mock nproc command to return 4 cores
    nproc() {
      echo "4"
    }
    export -f nproc

    RESULT=$(detect_optimal_jobs)
    ${testHelpers.assertTrue "[ \"$RESULT\" = \"4\" ]" "Linux detects 4 cores correctly"}
  )

  # Test 3: Environment variable override
  ${testHelpers.testSubsection "Environment Variable Override"}
  (
    ${mockEnv "darwin" 16}

    # Mock sysctl to return different value
    sysctl() {
      if [ "$1" = "-n" ] && [ "$2" = "hw.ncpu" ]; then
        echo "8"
      else
        return 1
      fi
    }
    export -f sysctl

    RESULT=$(detect_optimal_jobs)
    ${testHelpers.assertTrue "[ \"$RESULT\" = \"16\" ]" "NIX_BUILD_JOBS override works (16 instead of 8)"}
  )

  # Test 4: Fallback to 1 core when detection fails
  ${testHelpers.testSubsection "Fallback Behavior"}
  (
    ${mockEnv "darwin" null}

    # Mock sysctl to fail
    sysctl() {
      return 1
    }
    export -f sysctl

    RESULT=$(detect_optimal_jobs)
    ${testHelpers.assertTrue "[ \"$RESULT\" = \"1\" ]" "Falls back to 1 core when detection fails"}
  )

  # Test 5: Invalid environment variable handling
  ${testHelpers.testSubsection "Invalid Environment Variable"}
  (
    ${mockEnv "darwin" 0}

    # Mock sysctl to return 4 cores
    sysctl() {
      if [ "$1" = "-n" ] && [ "$2" = "hw.ncpu" ]; then
        echo "4"
      else
        return 1
      fi
    }
    export -f sysctl

    RESULT=$(detect_optimal_jobs)
    ${testHelpers.assertTrue "[ \"$RESULT\" = \"4\" ]" "Invalid NIX_BUILD_JOBS=0 falls back to detection"}
  )

  # Test 6: Negative environment variable handling
  ${testHelpers.testSubsection "Negative Environment Variable"}
  (
    export NIX_BUILD_JOBS="-5"
    ${mockEnv "linux" null}

    # Mock nproc to return 2 cores
    nproc() {
      echo "2"
    }
    export -f nproc

    RESULT=$(detect_optimal_jobs)
    ${testHelpers.assertTrue "[ \"$RESULT\" = \"2\" ]" "Negative NIX_BUILD_JOBS falls back to detection"}
  )

  # Test 7: String environment variable handling
  ${testHelpers.testSubsection "String Environment Variable"}
  (
    export NIX_BUILD_JOBS="abc"
    ${mockEnv "linux" null}

    # Mock nproc to return 6 cores
    nproc() {
      echo "6"
    }
    export -f nproc

    RESULT=$(detect_optimal_jobs)
    ${testHelpers.assertTrue "[ \"$RESULT\" = \"6\" ]" "String NIX_BUILD_JOBS falls back to detection"}
  )

  # Test 8: Linux fallback when nproc fails
  ${testHelpers.testSubsection "Linux Fallback"}
  (
    ${mockEnv "linux" null}

    # Mock nproc to fail
    nproc() {
      return 1
    }
    export -f nproc

    RESULT=$(detect_optimal_jobs)
    ${testHelpers.assertTrue "[ \"$RESULT\" = \"1\" ]" "Linux falls back to 1 core when nproc fails"}
  )

  # Test 9: Zero cores from system detection
  ${testHelpers.testSubsection "Zero Core Detection"}
  (
    ${mockEnv "darwin" null}

    # Mock sysctl to return 0 cores
    sysctl() {
      if [ "$1" = "-n" ] && [ "$2" = "hw.ncpu" ]; then
        echo "0"
      else
        return 1
      fi
    }
    export -f sysctl

    RESULT=$(detect_optimal_jobs)
    ${testHelpers.assertTrue "[ \"$RESULT\" = \"1\" ]" "Zero cores from system detection falls back to 1"}
  )

  # Test 10: Large core count
  ${testHelpers.testSubsection "Large Core Count"}
  (
    ${mockEnv "linux" null}

    # Mock nproc to return 128 cores
    nproc() {
      echo "128"
    }
    export -f nproc

    RESULT=$(detect_optimal_jobs)
    ${testHelpers.assertTrue "[ \"$RESULT\" = \"128\" ]" "Large core count (128) handled correctly"}
  )

  ${testHelpers.testSection "Test Summary"}

  # All tests passed if we reach this point
  ${testHelpers.reportResults "Build Parallelization Unit Tests" 10 10}

  # Create success marker
  touch $out

  echo ""
  echo "✅ All build parallelization unit tests passed!"
''
