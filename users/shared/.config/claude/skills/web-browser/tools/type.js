#!/usr/bin/env node

import { chromium } from "playwright";

const selector = process.argv[2];
const text = process.argv[3];
const delay = parseInt(process.argv.find(arg => arg.startsWith("--delay="))?.split("=")[1] || "0");

if (!selector || !text || process.argv.includes("--help")) {
  console.log("Usage: type.js <selector> <text> [--delay=<ms>]");
  console.log("\nType text into input field");
  console.log("\nExamples:");
  console.log("  type.js 'input[name=email]' 'test@example.com'");
  console.log("  type.js '#search' 'query'");
  console.log("  type.js '#message' 'Hello World' --delay=100  # Slow typing");
  process.exit(selector && text ? 0 : 1);
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

  await p.fill(selector, text, { timeout: 5000 });
  if (delay > 0) {
    // Clear and type with delay
    await p.fill(selector, "");
    await p.type(selector, text, { delay });
  }

  console.log(`✓ Typed into: ${selector}`);
  console.log(`  Text: ${text}`);

  await b.close();
} catch (e) {
  console.error("✗ Failed to type into element");
  console.error(`  Selector: ${selector}`);
  console.error(`  Error: ${e.message}`);
  process.exit(1);
}
