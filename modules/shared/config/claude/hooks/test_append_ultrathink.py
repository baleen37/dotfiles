#!/usr/bin/env python3

import json
import subprocess
import sys
import os
from pathlib import Path

def test_ultrathink_hook():
    """Test the append_ultrathink.py hook script"""

    # Get the script path
    script_dir = Path(__file__).parent
    script_path = script_dir / "append_ultrathink.py"

    print(f"Testing script: {script_path}")

    # Test cases
    test_cases = [
        {
            "name": "Normal message (no change expected)",
            "input": {"prompt": "Hello world"},
            "expected_output": {"prompt": "Hello world"}
        },
        {
            "name": "Message with -u flag",
            "input": {"prompt": "Hello world -u"},
            "expected_output": {
                "prompt": "Hello world\n\nUse the maximum amount of ultrathink. Take all the time you need. It's much better if you do too much research and thinking than not enough."
            }
        },
        {
            "name": "Message with -u flag and extra spaces",
            "input": {"prompt": "  Hello world -u  "},
            "expected_output": {
                "prompt": "Hello world\n\nUse the maximum amount of ultrathink. Take all the time you need. It's much better if you do too much research and thinking than not enough."
            }
        },
        {
            "name": "Multi-line message with -u flag",
            "input": {"prompt": "Line 1\nLine 2 -u"},
            "expected_output": {
                "prompt": "Line 1\nLine 2\n\nUse the maximum amount of ultrathink. Take all the time you need. It's much better if you do too much research and thinking than not enough."
            }
        },
        {
            "name": "Message containing -u but not at the end",
            "input": {"prompt": "Hello -u world"},
            "expected_output": {"prompt": "Hello -u world"}
        },
        {
            "name": "Empty prompt with -u flag",
            "input": {"prompt": " -u"},
            "expected_output": {
                "prompt": "\n\nUse the maximum amount of ultrathink. Take all the time you need. It's much better if you do too much research and thinking than not enough."
            }
        }
    ]

    # Run test cases
    passed = 0
    failed = 0

    for i, test_case in enumerate(test_cases, 1):
        print(f"\n--- Test {i}: {test_case['name']} ---")

        try:
            # Run the script with test input
            input_json = json.dumps(test_case["input"])
            result = subprocess.run(
                [sys.executable, str(script_path)],
                input=input_json,
                capture_output=True,
                text=True,
                timeout=5
            )

            if result.returncode != 0:
                print(f"❌ FAILED: Script returned non-zero exit code {result.returncode}")
                print(f"   stderr: {result.stderr}")
                failed += 1
                continue

            # Parse output
            try:
                actual_output = json.loads(result.stdout.strip())
            except json.JSONDecodeError as e:
                print(f"❌ FAILED: Invalid JSON output: {e}")
                print(f"   stdout: {result.stdout}")
                failed += 1
                continue

            # Compare with expected
            if actual_output == test_case["expected_output"]:
                print("✅ PASSED")
                passed += 1
            else:
                print("❌ FAILED: Output doesn't match expected")
                print(f"   Expected: {test_case['expected_output']}")
                print(f"   Actual:   {actual_output}")
                failed += 1

        except subprocess.TimeoutExpired:
            print("❌ FAILED: Script timeout")
            failed += 1
        except Exception as e:
            print(f"❌ FAILED: Unexpected error: {e}")
            failed += 1

    # Summary
    print(f"\n{'='*50}")
    print(f"TEST SUMMARY")
    print(f"{'='*50}")
    print(f"Total tests: {len(test_cases)}")
    print(f"Passed: {passed}")
    print(f"Failed: {failed}")
    print(f"Success rate: {passed/len(test_cases)*100:.1f}%")

    return failed == 0

def test_error_handling():
    """Test error handling scenarios"""

    script_dir = Path(__file__).parent
    script_path = script_dir / "append_ultrathink.py"

    print(f"\n{'='*50}")
    print("ERROR HANDLING TESTS")
    print(f"{'='*50}")

    error_test_cases = [
        {
            "name": "Invalid JSON input",
            "input": "{ invalid json",
            "expect_failure": True
        },
        {
            "name": "Missing prompt key",
            "input": '{"message": "hello"}',
            "expect_failure": False  # Should handle gracefully with empty prompt
        },
        {
            "name": "Empty input",
            "input": "",
            "expect_failure": True
        }
    ]

    passed = 0
    failed = 0

    for i, test_case in enumerate(error_test_cases, 1):
        print(f"\n--- Error Test {i}: {test_case['name']} ---")

        try:
            result = subprocess.run(
                [sys.executable, str(script_path)],
                input=test_case["input"],
                capture_output=True,
                text=True,
                timeout=5
            )

            if test_case["expect_failure"]:
                if result.returncode != 0:
                    print("✅ PASSED: Script failed as expected")
                    passed += 1
                else:
                    print("❌ FAILED: Script should have failed but didn't")
                    failed += 1
            else:
                if result.returncode == 0:
                    print("✅ PASSED: Script handled gracefully")
                    passed += 1
                else:
                    print("❌ FAILED: Script failed unexpectedly")
                    print(f"   stderr: {result.stderr}")
                    failed += 1

        except Exception as e:
            print(f"❌ FAILED: Test error: {e}")
            failed += 1

    print(f"\nError handling tests - Passed: {passed}, Failed: {failed}")
    return failed == 0

if __name__ == "__main__":
    print("🧪 ULTRATHINK HOOK TESTS")
    print("=" * 50)

    # Check if script exists
    script_dir = Path(__file__).parent
    script_path = script_dir / "append_ultrathink.py"

    if not script_path.exists():
        print(f"❌ ERROR: Script not found at {script_path}")
        sys.exit(1)

    # Run tests
    basic_tests_passed = test_ultrathink_hook()
    error_tests_passed = test_error_handling()

    # Overall result
    print(f"\n{'='*50}")
    print("OVERALL RESULT")
    print(f"{'='*50}")

    if basic_tests_passed and error_tests_passed:
        print("🎉 ALL TESTS PASSED!")
        sys.exit(0)
    else:
        print("💥 SOME TESTS FAILED!")
        sys.exit(1)
