#!/usr/bin/env node

import { chromium } from "playwright";

const url = process.argv[2];
const newTab = process.argv[3] === "--new";

if (!url) {
  console.log("Usage: nav.js <url> [--new]");
  console.log("\nExamples:");
  console.log("  nav.js https://example.com       # Navigate current tab");
  console.log("  nav.js https://example.com --new # Open in new tab");
  process.exit(1);
}

const b = await chromium.connectOverCDP("http://localhost:9222");
const contexts = b.contexts();
const context = contexts[0];

if (newTab) {
  const p = await context.newPage();
  await p.goto(url, { waitUntil: "domcontentloaded" });
  console.log("✓ Opened:", url);
} else {
  const pages = context.pages();
  const p = pages.at(-1);
  await p.goto(url, { waitUntil: "domcontentloaded" });
  console.log("✓ Navigated to:", url);
}

await b.close();
