#!/usr/bin/env node

import { chromium } from "playwright";

const level = process.argv.find(arg => arg.startsWith("--level="))?.split("=")[1];
const filter = process.argv.find(arg => arg.startsWith("--filter="))?.split("=")[1];

if (process.argv.includes("--help")) {
  console.log("Usage: console.js [--level=<log|warn|error>] [--filter=<pattern>]");
  console.log("\nCapture console logs from browser");
  console.log("\nExamples:");
  console.log("  console.js                    # All console messages");
  console.log("  console.js --level=error      # Only errors");
  console.log("  console.js --filter='API'     # Messages containing 'API'");
  console.log("\nPress Ctrl+C to stop");
  process.exit(0);
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

  console.log("📝 Capturing console messages... (Press Ctrl+C to stop)\n");
  if (level) {
    console.log(`   Level filter: ${level}`);
  }
  if (filter) {
    console.log(`   Text filter: ${filter}`);
  }
  if (level || filter) {
    console.log("");
  }

  const messages = [];

  p.on("console", msg => {
    const msgType = msg.type();
    const msgText = msg.text();

    // Apply level filter
    if (level && msgType !== level) {
      return;
    }

    // Apply text filter
    if (filter && !msgText.includes(filter)) {
      return;
    }

    const icon = {
      log: "ℹ️ ",
      warn: "⚠️ ",
      error: "❌",
      info: "ℹ️ ",
      debug: "🐛"
    }[msgType] || "  ";

    console.log(`${icon} [${msgType}] ${msgText}`);
    messages.push({ type: msgType, text: msgText, timestamp: new Date().toISOString() });
  });

  // Handle graceful shutdown
  process.on("SIGINT", async () => {
    console.log(`\n\n📊 Summary: ${messages.length} messages captured`);

    const counts = messages.reduce((acc, msg) => {
      acc[msg.type] = (acc[msg.type] || 0) + 1;
      return acc;
    }, {});

    if (Object.keys(counts).length > 0) {
      console.log("   By type:");
      Object.entries(counts).forEach(([type, count]) => {
        console.log(`     ${type}: ${count}`);
      });
    }

    await b.close();
    process.exit(0);
  });

  // Keep alive
  await new Promise(() => {});
} catch (e) {
  console.error("✗ Failed to capture console messages");
  console.error(`  Error: ${e.message}`);
  process.exit(1);
}
