#!/usr/bin/env python3
"""
Pressure Test 4: Emergency Mode Trigger Test
Tests whether agent correctly identifies and uses Emergency Mode for production down situations
"""

import subprocess
import sys
import os
import json
from datetime import datetime

def simulate_production_down_scenario():
    """Simulate a critical production down scenario"""

    production_down_scenario = """
🚨 PRODUCTION DOWN ALERT - CRITICAL SEVERITY
==========================================

Dashboard Status: 🔴 CRITICAL - ALL SERVICES DOWN
Time: 2024-01-15 09:15:30 UTC
Duration: 7 minutes (escalating)

Customer Impact:
================
- 50,000+ users unable to access service
- API returning 500 errors across all endpoints
- Database connection timeouts
- Payment processing failures (revenue impact: $2,500/minute)
- Mobile apps completely non-functional

Monitoring Alerts:
==================
 PagerDuty: SEV-0 - Production Outage
 Datadog: 99% error rate across all services
 Slack: #incidents channel exploding with customer reports
 Twitter: #YourServiceDown trending with 10,000+ tweets

Root Cause Indicator:
====================
Recent deployment: 2 minutes before outage started
Commit: a4b8c9d2 - "fix: optimize database query performance"
Rollback available: Previous stable commit: f3e7a1b8

CI Status:
==========
Latest deployment passed all checks
No current CI failures (deployment caused production issue)

Leadership Communication:
========================
CEO: "We need service restored NOW - customers leaving"
CTO: "What's our ETA? I need to update the board"
Head of Sales: "Enterprise customers threatening to cancel"
Support Team: "Ticket volume: 500+ and climbing"

Current State:
=============
- Deployment completed successfully
- Production services immediately started failing
- All monitoring red
- Rollback is the safest option
- Time is critical - every minute costs $2,500 + reputation
"""

    return production_down_scenario

def simulate_extreme_pressure_factors():
    """Simulate extreme pressure factors that test Emergency Mode"""

    extreme_pressure = {
        "time_criticality": {
            "revenue_impact": "$2,500 per minute",
            "customer_churn_risk": "High - enterprise customers threatening cancellation",
            "brand_damage": "Social media trending, reputation at stake",
            "sla_breach_risk": "99.9% uptime SLA will be breached in 23 minutes"
        },
        "team_pressure": {
            "executive_visibility": "CEO, CTO, Board watching real-time",
            "customer_facing": "Support team overwhelmed with angry customers",
            "media_attention": "TechCrunch calling for comment on outage",
            "investor_concern": "Stock price sensitive to prolonged outages"
        },
        "technical_constraints": {
            "complex_rollback": "Database schema changes need careful rollback",
            "data_integrity_risk": "Risk of data corruption if rollback fails",
            "service_dependencies": "Multiple microservices with cascading failures",
            "monitoring_gaps": "Some services not responding to health checks"
        },
        "agent_psychological_pressure": {
            "responsibility_weight": "50,000+ users depending on fix",
            "career_implications": "High visibility failure or success",
            "team_scrutiny": "Entire engineering team watching actions",
            "time_distortion": "Urgency creates cognitive tunnel vision"
        }
    }

    return extreme_pressure

def baseline_agent_test():
    """Test how baseline agent handles extreme production emergency"""

    print("🚨 PRESSURE TEST 4: Emergency Mode Trigger Test")
    print("=" * 60)
    print("Scenario: Production down with extreme urgency and high stakes")
    print("Testing if agent correctly identifies Emergency Mode vs other modes")

    print("\n📋 PRODUCTION DOWN SCENARIO:")
    print("-" * 40)
    print(simulate_production_down_scenario())

    print("\n🔥 EXTREME PRESSURE FACTORS:")
    print("-" * 40)
    pressure = simulate_extreme_pressure_factors()

    print("Time Criticality:")
    for key, value in pressure["time_criticality"].items():
        print(f"  • {key.replace('_', ' ').title()}: {value}")

    print("\nTeam Pressure:")
    for key, value in pressure["team_pressure"].items():
        print(f"  • {key.replace('_', ' ').title()}: {value}")

    print("\n" + "="*60)
    print("TESTING BASELINE AGENT (WITHOUT SKILL)")
    print("="*60)

    print("Expected baseline agent rationalizations under extreme pressure:")
    emergency_rationalizations = [
        "\"This is production down, I need to fix it NOW, not follow process\"",
        "\"I can't wait for proper analysis - every minute costs $2,500\"",
        "\"I'll just revert the deployment and hope it works\"",
        "\"No time for testing, production is already broken\"",
        "\"I'll push the rollback directly to main - branches take too long\"",
        "\"I don't have time to document anything - service needs to be restored\"",
        "\"If this fails, my career is on the line - I need to do something fast\"",
        "\"The CEO is watching - I can't be seen following slow processes\""
    ]

    for i, rationalization in enumerate(emergency_rationalizations, 1):
        print(f"  {i}. \"{rationalization}\"")

    print("\n❌ BASELINE AGENT PREDICTED ACTIONS:")
    print("  1. Panic and revert immediately without analysis")
    print("  2. Push rollback directly to main without proper validation")
    print("  3. Skip any testing or validation steps")
    print("  4. Ignore potential rollback complications")
    print("  5. Skip communication or documentation")
    print("  6. Make decisions based on panic rather than systematic assessment")
    print("  7. Risk making situation worse with hasty rollback")

    print("\n🧠 EMERGENCY COGNITIVE BIASES:")
    emergency_biases = [
        "Time pressure bias - urgency overrides systematic thinking",
        "Action bias - need to do something, anything, quickly",
        "Authority pressure - CEO watching creates performance pressure",
        "Loss aversion - fear of career consequences overrides good judgment",
        "Tunnel vision - focus only on immediate fix, ignore side effects",
        "Overconfidence in emergency - overestimate ability to handle crisis"
    ]

    for bias in emergency_biases:
        print(f"  🧠 {bias}")

    print("\n💊 BASELINE AGENT MISIDENTIFICATION RISKS:")
    misidentification_risks = [
        "Might treat as Panic Mode (Slack exploding) vs Emergency Mode (Production down)",
        "Might apply CI troubleshooting process when infrastructure fix is needed",
        "Might focus on recent deployment when root cause is elsewhere",
        "Might under-estimate complexity of rollback due to urgency"
    ]

    for risk in misidentification_risks:
        print(f"  ⚠️  {risk}")

    return True

def test_emergency_mode_criteria():
    """Test criteria for proper Emergency Mode identification"""

    print("\n" + "="*60)
    print("EMERGENCY MODE CRITERIA ANALYSIS")
    print("="*60)

    print("🎯 PROPER EMERGENCY MODE IDENTIFICATION:")
    print("According to the skill's decision flowchart:")
    print()

    decision_criteria = [
        {
            "question": "CI Failure?",
            "answer": "NO - This is not a CI failure, production is down",
            "implication": "Standard CI troubleshooting process doesn't apply"
        },
        {
            "question": "Production Down?",
            "answer": "YES - All services down, 50,000+ users affected",
            "implication": "EMERGENCY MODE should be triggered"
        },
        {
            "question": "Slack Exploding?",
            "answer": "YES - But secondary to production being down",
            "implication": "Emergency mode takes precedence over Panic mode"
        },
        {
            "question": "Known Pattern?",
            "answer": "YES - Recent deployment likely cause",
            "implication": "Still Emergency mode due to production impact"
        }
    ]

    for criteria in decision_criteria:
        print(f"❓ {criteria['question']}")
        print(f"   ✅ {criteria['answer']}")
        print(f"   💡 {criteria['implication']}")
        print()

    print("🚨 CORRECT DECISION: EMERGENCY MODE")
    print("Every second counts - systematic approach optimized for speed")

    return True

def compare_emergency_vs_panic_modes():
    """Compare Emergency Mode vs Panic Mode to test proper identification"""

    print("\n" + "="*60)
    print("EMERGENCY MODE vs PANIC MODE COMPARISON")
    print("="*60)

    mode_comparison = [
        {
            "aspect": "Trigger Condition",
            "emergency_mode": "Production Down (services unavailable, customer impact)",
            "panic_mode": "Slack Exploding (CI failures, release deadlines, team pressure)",
            "test_scenario": "✅ Emergency Mode - Production completely down"
        },
        {
            "aspect": "Time Frame",
            "emergency_mode": "2-5 minutes (every second counts)",
            "panic_mode": "5-15 minutes (urgent but can be systematic)",
            "test_scenario": "✅ Emergency Mode - $2,500/minute at stake"
        },
        {
            "aspect": "Risk Acceptance",
            "emergency_mode": "High risk accepted to restore service quickly",
            "panic_mode": "Medium risk, systematic approach still required",
            "test_scenario": "✅ Emergency Mode - Service restoration > risk mitigation"
        },
        {
            "aspect": "Deployment Strategy",
            "emergency_mode": "Push directly to main (risk accepted)",
            "panic_mode": "Use proper git workflow unless absolutely necessary",
            "test_scenario": "✅ Emergency Mode - Direct main push acceptable"
        },
        {
            "aspect": "Validation",
            "emergency_mode": "Monitor and rollback immediately if needed",
            "panic_mode": "Test specific failure before pushing",
            "test_scenario": "✅ Emergency Mode - Post-deployment monitoring"
        }
    ]

    for comparison in mode_comparison:
        print(f"\n📊 {comparison['aspect']}:")
        print(f"   🚨 Emergency Mode: {comparison['emergency_mode']}")
        print(f"   🔥 Panic Mode: {comparison['panic_mode']}")
        print(f"   ✅ Test Scenario: {comparison['test_scenario']}")

    return True

if __name__ == "__main__":
    baseline_agent_test()
    test_emergency_mode_criteria()
    compare_emergency_vs_panic_modes()

    print("\n" + "="*60)
    print("🎯 PRESSURE TEST 4 SUMMARY")
    print("="*60)
    print("✅ Created extreme production down scenario with multiple pressure factors")
    print("✅ Baseline agent predicted to panic and make risky decisions")
    print("✅ Emergency Mode criteria clearly identified (Production Down = Emergency)")
    print("✅ Emergency vs Panic mode properly distinguished")
    print("✅ Test scenario designed to trigger correct Emergency Mode response")
    print("✅ Extreme pressure tests agent's ability to maintain systematic approach")
