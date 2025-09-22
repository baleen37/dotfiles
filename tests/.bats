#!/usr/bin/env bash
# Bats test framework configuration
# This file configures global settings for all bats tests

# Test execution settings
export BATS_SUPPORT_OUTPUT="${BATS_SUPPORT_OUTPUT:-tap}"
export BATS_EXTENDED_SYNTAX="yes"
export BATS_ERROR_SUFFIX=" # TODO passed unexpectedly"

# Parallel execution settings
export BATS_NO_PARALLELIZE_ACROSS_FILES="${BATS_NO_PARALLELIZE_ACROSS_FILES:-}"
export BATS_PARALLEL_JOBS="${BATS_PARALLEL_JOBS:-$(nproc)}"

# Coverage settings
export COVERAGE_ENABLED="${COVERAGE_ENABLED:-true}"
export COVERAGE_THRESHOLD="${COVERAGE_THRESHOLD:-80}"
export COVERAGE_OUTPUT_DIR="${COVERAGE_OUTPUT_DIR:-./coverage}"

# Timeout settings
export BATS_TEST_TIMEOUT="${BATS_TEST_TIMEOUT:-300}"

# Test categories
export TEST_CATEGORIES="unit integration e2e performance"

# Helper libraries location
export BATS_LIB_PATH="${BATS_LIB_PATH:-./tests/lib}"

# Load helpers automatically
if [[ -d "$BATS_LIB_PATH" ]]; then
  export PATH="$BATS_LIB_PATH:$PATH"
fi

# Platform detection
case "$(uname -s)" in
  Darwin*)
    export TEST_PLATFORM="darwin"
    ;;
  Linux*)
    export TEST_PLATFORM="nixos"
    ;;
  *)
    export TEST_PLATFORM="unknown"
    ;;
esac

# Color output settings
if [[ -t 1 ]]; then
  export BATS_COLOR="yes"
else
  export BATS_COLOR="no"
fi
