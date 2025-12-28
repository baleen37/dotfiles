#!/usr/bin/env node

import { chromium } from "playwright";

const selector = process.argv[2];
const timeout = parseInt(process.argv.find(arg => arg.startsWith("--timeout="))?.split("=")[1] || "30000");
const state = process.argv.find(arg => arg.startsWith("--state="))?.split("=")[1] || "visible";

if (!selector || process.argv.includes("--help")) {
  console.log("Usage: wait.js <selector> [--timeout=<ms>] [--state=<state>]");
  console.log("\nWait for element to reach specified state");
  console.log("\nStates:");
  console.log("  visible  - Element is visible (default)");
  console.log("  hidden   - Element is hidden");
  console.log("  attached - Element exists in DOM");
  console.log("  detached - Element removed from DOM");
  console.log("\nExamples:");
  console.log("  wait.js '.loading-spinner' --state=hidden");
  console.log("  wait.js '#content' --timeout=5000");
  console.log("  wait.js '.success-message' --state=visible");
  process.exit(selector ? 0 : 1);
}

const validStates = ["visible", "hidden", "attached", "detached"];
if (!validStates.includes(state)) {
  console.error(`✗ Invalid state: ${state}`);
  console.error(`  Valid states: ${validStates.join(", ")}`);
  process.exit(1);
}

try {
  const b = await chromium.connectOverCDP("http://localhost:9222");
  const contexts = b.contexts();
  const pages = contexts[0]?.pages() || [];
  const p = pages.at(-1);

  if (!p) {
    console.error("✗ No active tab found");
    console.error("  Open a page first: ./nav.js <url>");
    process.exit(1);
  }

  await p.waitForSelector(selector, { state, timeout });
  console.log(`✓ Element ${state}: ${selector}`);

  await b.close();
} catch (e) {
  if (e.message.includes("Timeout")) {
    console.error("✗ Timeout waiting for element");
    console.error(`  Selector: ${selector}`);
    console.error(`  State: ${state}`);
    console.error(`  Timeout: ${timeout}ms`);
  } else {
    console.error("✗ Failed to wait for element");
    console.error(`  Selector: ${selector}`);
    console.error(`  Error: ${e.message}`);
  }
  process.exit(1);
}
