# tests/lib/test-runner.nix
# Test suite runner with filtering, performance monitoring, and detailed reporting

{ pkgs, lib }:

let
  # Test runner with filtering and performance monitoring
  mkTestSuite =
    name: tests: args:
    let
      verbose = args.verbose or false;
      filter = args.filter or null;
    in
    pkgs.runCommand "test-suite-${name}" { } ''
      echo "🧪 Running test suite: ${name}"
      ${lib.optionalString (filter != null) ''
        echo "🔍 Filter: ${filter}"
      ''}
      ${lib.optionalString verbose ''
        echo "📢 Verbose mode enabled"
      ''}

      total_tests=0
      passed_tests=0
      failed_tests=0
      start_time=$(date +%s)

      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (testName: test: ''
          # Test name extraction from attribute name
          test_name="${testName}"

          # Filter application using regex matching
          ${lib.optionalString (filter != null) ''
            if [[ ! "$test_name" =~ ${toString filter} ]]; then
              echo "⏭️  Skipping: $test_name"
              continue
            fi
          ''}

          total_tests=$((total_tests + 1))
          echo ""
          echo "🔍 Running: $test_name"
          test_start_time=$(date +%s)

          # Run the test and capture output
          if ${test} > test_output_$test_name.log 2>&1; then
            test_end_time=$(date +%s)
            test_duration=$((test_end_time - test_start_time))
            echo "✅ $test_name: PASSED ⏱️  $test_duration"s
            passed_tests=$((passed_tests + 1))
          else
            test_end_time=$(date +%s)
            test_duration=$((test_end_time - test_start_time))
            echo "❌ $test_name: FAILED ⏱️  $test_duration"s
            failed_tests=$((failed_tests + 1))
            echo "📋 Test output for $test_name:"
            cat test_output_$test_name.log | sed 's/^/   /'
          fi
        '') tests
      )}

      end_time=$(date +%s)
      total_duration=$((end_time - start_time))

      echo ""
      echo "📊 Results: $passed_tests/$total_tests passed, $failed_tests failed"
      echo "⏱️  Total time: $total_duration}s"

      if [ $failed_tests -gt 0 ]; then
        echo "❌ Test suite failed"
        exit 1
      else
        echo "✅ All tests passed"
        touch $out
      fi
    '';
in
{
  inherit mkTestSuite;
}
