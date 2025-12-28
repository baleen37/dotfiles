#!/usr/bin/env node

import { chromium } from "playwright";

const filterPattern = process.argv.find((arg) => arg.startsWith("--filter="))?.split("=")[1];
const showHelp = process.argv.includes("--help");

if (showHelp) {
  console.log("Usage: network.js [--filter=<pattern>]");
  console.log("\nExamples:");
  console.log("  network.js                    # Show all network requests");
  console.log("  network.js --filter=api.      # Filter requests containing 'api.'");
  console.log("  network.js --filter=.json     # Filter JSON requests");
  process.exit(0);
}

const b = await chromium.connectOverCDP("http://localhost:9222");
const contexts = b.contexts();
const p = contexts[0].pages().at(-1);

if (!p) {
  console.error("✗ No active tab found");
  process.exit(1);
}

console.log("🔍 Monitoring network requests... (Press Ctrl+C to stop)\n");

const requests = [];

p.on("request", (request) => {
  const url = request.url();
  if (!filterPattern || url.includes(filterPattern)) {
    const data = {
      method: request.method(),
      url: url,
      resourceType: request.resourceType(),
      timestamp: new Date().toISOString(),
    };
    requests.push(data);
  }
});

p.on("response", async (response) => {
  const url = response.url();
  if (!filterPattern || url.includes(filterPattern)) {
    const request = requests.find((r) => r.url === url);
    if (request) {
      request.status = response.status();
      request.statusText = response.statusText();
      request.contentType = response.headers()["content-type"];

      console.log(`[${request.method}] ${request.status} ${request.url}`);
      console.log(`  Type: ${request.resourceType}, Content-Type: ${request.contentType || 'N/A'}`);
      console.log(`  Time: ${request.timestamp}\n`);
    }
  }
});

// Keep process running
process.on("SIGINT", async () => {
  console.log("\n\n📊 Network Summary:");
  console.log(`Total requests captured: ${requests.length}`);

  const byType = requests.reduce((acc, req) => {
    acc[req.resourceType] = (acc[req.resourceType] || 0) + 1;
    return acc;
  }, {});

  console.log("\nBy resource type:");
  Object.entries(byType).forEach(([type, count]) => {
    console.log(`  ${type}: ${count}`);
  });

  await b.close();
  process.exit(0);
});
