#!/usr/bin/env node

import { chromium } from "playwright";

const selector = process.argv[2];
const isHtml = process.argv.includes("--html");
const isText = process.argv.includes("--text");
const attr = process.argv.find(arg => arg.startsWith("--attr="))?.split("=")[1];
const all = process.argv.includes("--all");

if (!selector || process.argv.includes("--help")) {
  console.log("Usage: extract.js <selector> [--html | --text | --attr=<name>] [--all]");
  console.log("\nExtract HTML, text, or attributes from elements");
  console.log("\nExamples:");
  console.log("  extract.js 'h1' --text              # First h1 text");
  console.log("  extract.js 'a' --attr=href --all    # All link hrefs");
  console.log("  extract.js '#content' --html        # Content HTML");
  console.log("  extract.js '.price' --text --all    # All prices");
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

  if (all) {
    const elements = await p.$$(selector);

    if (elements.length === 0) {
      console.log("(no elements found)");
      await b.close();
      process.exit(0);
    }

    const results = [];
    for (const el of elements) {
      if (isHtml) {
        results.push(await el.innerHTML());
      } else if (isText) {
        results.push(await el.textContent());
      } else if (attr) {
        results.push(await el.getAttribute(attr));
      } else {
        results.push(await el.textContent());
      }
    }

    results.forEach(result => console.log(result));
  } else {
    const el = await p.$(selector);

    if (!el) {
      console.log("(element not found)");
      await b.close();
      process.exit(0);
    }

    let result;
    if (isHtml) {
      result = await el.innerHTML();
    } else if (isText) {
      result = await el.textContent();
    } else if (attr) {
      result = await el.getAttribute(attr);
    } else {
      result = await el.textContent();
    }

    console.log(result);
  }

  await b.close();
} catch (e) {
  console.error("✗ Failed to extract from element");
  console.error(`  Selector: ${selector}`);
  console.error(`  Error: ${e.message}`);
  process.exit(1);
}
