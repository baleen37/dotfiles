#!/usr/bin/env node

import { chromium } from "playwright";

const selector = process.argv[2];
const force = process.argv.includes("--force");

if (!selector || process.argv.includes("--help")) {
  console.log("Usage: click.js <selector> [--force]");
  console.log("\nClick element by CSS selector");
  console.log("\nExamples:");
  console.log("  click.js 'button.submit'");
  console.log("  click.js '#login-btn'");
  console.log("  click.js 'a[href=\"/logout\"]' --force  # Force click even if hidden");
  process.exit(selector ? 0 : 1);
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

  await p.click(selector, { force, timeout: 5000 });
  console.log(`✓ Clicked: ${selector}`);

  await b.close();
} catch (e) {
  console.error("✗ Failed to click element");
  console.error(`  Selector: ${selector}`);
  console.error(`  Error: ${e.message}`);
  process.exit(1);
}
