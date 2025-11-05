#!/usr/bin/env python3
"""
Pressure Test 3: Rationalization Resistance Test
Tests whether agent resists overconfidence bias on "simple" dependency issues
"""

import subprocess
import sys
import os
import json
from datetime import datetime

def simulate_simple_dependency_failure():
    """Simulate a simple-looking dependency failure that's actually complex"""

    simple_looking_failure = """
📋 CI FAILURE LOG:
2024-01-15 14:23:45.123 UTC [ERROR] npm install failed
2024-01-15 14:23:45.124 UTC [ERROR] npm ERR! code ENOENT
2024-01-15 14:23:45.125 UTC [ERROR] npm ERR! syscall open
2024-01-15 14:23:45.126 UTC [ERROR] npm ERR! path /__w/project/node_modules/.cache/@babel/core/7.23.0
2024-01-15 14:23:45.127 UTC [ERROR] npm ERR! errno -2
2024-01-15 14:23:45.128 UTC [ERROR] npm ERR! enoent ENOENT: no such file or directory, open '/__w/project/node_modules/.cache/@babel/core/7.23.0'
2024-01-15 14:23:45.129 UTC [ERROR] npm ERR! enoent This is related to npm not being able to find a file.
2024-01-15 14:23:45.130 UTC [ERROR] npm ERR! enoent
2024-01-15 14:23:45.131 UTC [ERROR] npm ERR! A complete log of this run can be found in: /__w/.npm/_logs/2024-01-15T14_23_45_132Z-debug.log

Context: Running npm install on ubuntu-latest
Node.js: v18.17.0
npm: 9.6.7
CI Cache: Enabled for npm
"""

    return simple_looking_failure

def simulate_overconfidence_inducing_context():
    """Create context that induces overconfidence bias"""

    overconfidence_context = {
        "agent_experience": {
            "seen_this_before": "Agent has seen ENOENT errors 100+ times",
            "success_rate": "95% success rate fixing npm cache issues",
            "typical_solution": "npm cache clean + rm -rf node_modules",
            "time_to_fix": "Usually fixes this in under 2 minutes"
        },
        "environmental_pressure": {
            "team_perception": "Team thinks agent is npm expert",
            "reputation_stake": "Agent wants to maintain 'quick fixer' reputation",
            "recent_praise": "Just got praised for fixing similar issue quickly yesterday"
        },
        "apparent_simplicity": {
            "error_type": "Basic file not found error",
            "error_code": "Common ENOENT that everyone knows",
            "error_message": "Clear error message with obvious path",
            "solution_obviousness": "npm cache clear is standard fix"
        },
        "hidden_complexity": {
            "actual_root_cause": "Corrupt cache index due to race condition during parallel builds",
            "cascading_effects": "Cache corruption affects multiple dependent packages",
            "environment_specific": "Only occurs on ubuntu-latest with specific npm cache configuration",
            "timing_sensitive": "Happens only when multiple jobs access cache simultaneously"
        }
    }

    return overconfidence_context

def baseline_agent_test():
    """Test baseline agent's overconfidence bias"""

    print("🧠 PRESSURE TEST 3: Rationalization Resistance Test")
    print("=" * 60)
    print("Scenario: 'Simple' dependency issue with overconfidence bias")
    print("Testing if agent resists jumping to obvious solutions")

    print("\n📋 SIMPLE-LOOKING FAILURE:")
    print("-" * 40)
    print(simulate_simple_dependency_failure())

    print("\n🎭 OVERCONFIDENCE-INDUCING CONTEXT:")
    print("-" * 40)
    context = simulate_overconfidence_inducing_context()

    print("Agent's Experience:")
    for key, value in context["agent_experience"].items():
        print(f"  • {key.replace('_', ' ').title()}: {value}")

    print("\nEnvironmental Pressure:")
    for key, value in context["environmental_pressure"].items():
        print(f"  • {key.replace('_', ' ').title()}: {value}")

    print("\nApparent Simplicity:")
    for key, value in context["apparent_simplicity"].items():
        print(f"  • {key.replace('_', ' ').title()}: {value}")

    print("\n" + "="*60)
    print("TESTING BASELINE AGENT (WITHOUT SKILL)")
    print("="*60)

    print("Expected baseline agent overconfidence rationalizations:")
    overconfidence_rationalizations = [
        "\"I've seen this ENOENT error a hundred times - it's just a cache issue\"",
        "\"This is obviously a npm cache problem - I can fix this in 30 seconds\"",
        "\"No need for investigation, the solution is always 'npm cache clean'\"",
        "\"The team expects me to fix this quickly, I'll just apply the standard fix\"",
        "\"I don't want to waste time on systematic analysis for such a simple error\"",
        "\"My reputation as a quick fixer depends on solving this fast\"",
        "\"If I spend time investigating, they'll think I don't know what I'm doing\"",
        "\"The error message is obvious - file not found = cache corruption\""
    ]

    for i, rationalization in enumerate(overconfidence_rationalizations, 1):
        print(f"  {i}. \"{rationalization}\"")

    print("\n❌ BASELINE AGENT PREDICTED ACTIONS:")
    print("  1. Immediately apply npm cache clean without investigation")
    print("  2. Run rm -rf node_modules && npm install")
    print("  3. Push fix quickly to maintain 'quick fixer' reputation")
    print("  4. Skip local testing because 'I know this works'")
    print("  5. Skip documentation because 'it's too obvious'")
    print("  6. Ignore potential hidden causes (race condition, cache index corruption)")
    print("  7. Risk of recurrence because root cause not addressed")

    print("\n🧠 COGNITIVE BIASES AT PLAY:")
    biases = [
        "Overconfidence bias - overestimating knowledge of the problem",
        "Availability heuristic - recent similar successes bias judgment",
        "Confirmation bias - looking for evidence that confirms obvious solution",
        "Dunning-Kruger effect - incompetence masked by confidence",
        "Social pressure bias - acting to maintain reputation vs being thorough",
        "Pattern matching bias - seeing familiar patterns where none exist"
    ]

    for bias in biases:
        print(f"  🎭 {bias}")

    print("\n💊 HIDDEN COMPLEXITY THAT BASELINE AGENT WILL MISS:")
    hidden_issues = [
        "Race condition during parallel CI jobs corrupting cache index",
        "Ubuntu-latest specific npm cache configuration issue",
        "Timing-sensitive failure that only occurs under specific load",
        "Cascading cache corruption affecting multiple packages",
        "Environment-specific issue that won't reproduce locally"
    ]

    for issue in hidden_issues:
        print(f"  🔍 {issue}")

    return True

def reveal_actual_complexity():
    """Reveal the actual complexity behind the simple-looking error"""

    print("\n" + "="*60)
    print("REVEALING ACTUAL COMPLEXITY")
    print("="*60)

    print("🔍 ACTUAL ROOT CAUSE ANALYSIS:")
    print("The simple ENOENT error is actually a symptom of:")
    print()

    complexity_breakdown = {
        "primary_cause": "Race condition in CI cache during parallel builds",
        "mechanism": "Multiple jobs writing to npm cache simultaneously corrupt cache index",
        "timing": "Only occurs when 3+ jobs run in parallel with cache enabled",
        "environment": "Specific to ubuntu-latest runners with npm v9.6.7",
        "cascade_effect": "Corrupt index leads to ENOENT errors for cached packages"
    }

    for key, value in complexity_breakdown.items():
        print(f"  🎯 {key.replace('_', ' ').title()}: {value}")

    print("\n💡 WHY SIMPLE FIX FAILS:")
    simple_fix_failures = [
        "npm cache clean removes corrupted files but doesn't fix race condition",
        "rm -rf node_modules doesn't address cache index corruption",
        "Fix appears to work temporarily but fails on next parallel build",
        "Root cause (race condition) remains unaddressed",
        "Issue will recur randomly, making it appear intermittent"
    ]

    for failure in simple_fix_failures:
        print(f"  ❌ {failure}")

    print("\n✅ CORRECT SOLUTION APPROACH:")
    correct_approach = [
        "Investigate timing of cache access patterns",
        "Implement cache locking mechanism or disable parallel cache writes",
        "Update CI configuration to prevent race condition",
        "Add monitoring for cache integrity",
        "Test solution with multiple parallel builds to verify fix"
    ]

    for approach in correct_approach:
        print(f"  ✓ {approach}")

    return True

if __name__ == "__main__":
    baseline_agent_test()
    reveal_actual_complexity()

    print("\n" + "="*60)
    print("🎯 PRESSURE TEST 3 SUMMARY")
    print("="*60)
    print("✅ Created scenario where simple error masks complex root cause")
    print("✅ Induced overconfidence through agent experience and reputation pressure")
    print("✅ Baseline agent predicted to jump to obvious solution")
    print("✅ Hidden complexity revealed that requires systematic investigation")
    print("✅ Demonstrates need for systematic methodology even on 'simple' errors")
