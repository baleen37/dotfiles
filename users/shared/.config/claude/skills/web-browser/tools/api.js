#!/usr/bin/env node

import { chromium } from 'playwright';
import { writeFileSync } from 'fs';

const command = process.argv[2];

if (command === "--help" || !command) {
  console.log("Usage: api.js <command> [options]");
  console.log("\nCommands:");
  console.log("  capture  Capture API requests and save to HAR file");
  console.log("\nOptions:");
  console.log("  --filter=<pattern>  Only capture URLs matching pattern");
  console.log("  --output=<file>     Output filename (default: api-requests.har)");
  console.log("  --help              Show this help message");
  process.exit(0);
}

if (command === "capture") {
  const filterPattern = process.argv.find(arg => arg.startsWith("--filter="))?.split("=")[1];
  const outputFile = process.argv.find(arg => arg.startsWith("--output="))?.split("=")[1] || "api-requests.har";

  try {
    const browser = await chromium.connectOverCDP('http://localhost:9222');
    const contexts = browser.contexts();

    if (contexts.length === 0) {
      console.error("✗ No browser contexts found");
      process.exit(1);
    }

    const context = contexts[0];
    const pages = context.pages();

    if (pages.length === 0) {
      console.error("✗ No active tabs found");
      process.exit(1);
    }

    const page = pages[pages.length - 1];
    console.log("✓ Connected to Chrome on :9222");

    const requests = [];

    // Capture requests
    page.on('request', request => {
      const url = request.url();
      const resourceType = request.resourceType();

      // Only capture XHR/Fetch (API calls)
      if (!['xhr', 'fetch'].includes(resourceType)) {
        return;
      }

      // Apply filter if specified
      if (filterPattern && !url.includes(filterPattern)) {
        return;
      }

      const requestData = {
        url: url,
        method: request.method(),
        headers: request.headers(),
        postData: request.postData(),
        resourceType: resourceType,
        timestamp: new Date().toISOString(),
      };

      requests.push(requestData);
      console.log(`📥 [${requestData.method}] ${url}`);
    });

    // Capture responses
    page.on('response', async response => {
      const url = response.url();
      const request = requests.find(r => r.url === url);

      if (!request) return;

      try {
        request.status = response.status();
        request.statusText = response.statusText();
        request.responseHeaders = response.headers();

        // Try to get response body
        const body = await response.body();
        request.responseBody = body.toString('base64');
        request.responseSize = body.length;

        console.log(`📤 [${request.status}] ${url}`);
      } catch (err) {
        console.log(`⚠️  Failed to capture response: ${url}`);
      }
    });

    console.log("\n🔍 Capturing API requests... (Press Ctrl+C to stop and save)\n");
    if (filterPattern) {
      console.log(`   Filter: ${filterPattern}`);
    }

    // Handle graceful shutdown
    process.on('SIGINT', async () => {
      console.log("\n\n💾 Saving captured requests...");

      const har = toHAR(requests);
      writeFileSync(outputFile, JSON.stringify(har, null, 2));

      console.log(`✓ Saved ${requests.length} requests to ${outputFile}`);
      console.log(`  Format: HAR 1.2`);
      console.log(`\nSummary:`);
      console.log(`  Total requests: ${requests.length}`);

      const methods = requests.reduce((acc, req) => {
        acc[req.method] = (acc[req.method] || 0) + 1;
        return acc;
      }, {});

      console.log(`  By method:`);
      Object.entries(methods).forEach(([method, count]) => {
        console.log(`    ${method}: ${count}`);
      });

      await browser.close();
      process.exit(0);
    });

  } catch (error) {
    console.error("✗ Failed to connect to Chrome on :9222");
    console.error("  Make sure Chrome is running with:");
    console.error("  ./start.js");
    process.exit(1);
  }
}

// Convert captured requests to HAR 1.2 format
function toHAR(requests) {
  return {
    log: {
      version: "1.2",
      creator: {
        name: "web-browser-api-tool",
        version: "1.0.0"
      },
      browser: {
        name: "Chrome",
        version: "Unknown"
      },
      pages: [],
      entries: requests.map(req => ({
        startedDateTime: req.timestamp,
        time: 0,
        request: {
          method: req.method,
          url: req.url,
          httpVersion: "HTTP/1.1",
          headers: Object.entries(req.headers || {}).map(([name, value]) => ({
            name,
            value: String(value)
          })),
          queryString: [],
          cookies: [],
          headersSize: -1,
          bodySize: req.postData ? req.postData.length : -1,
          postData: req.postData ? {
            mimeType: req.headers?.['content-type'] || 'application/octet-stream',
            text: req.postData
          } : undefined
        },
        response: {
          status: req.status || 0,
          statusText: req.statusText || '',
          httpVersion: "HTTP/1.1",
          headers: Object.entries(req.responseHeaders || {}).map(([name, value]) => ({
            name,
            value: String(value)
          })),
          cookies: [],
          content: {
            size: req.responseSize || 0,
            compression: 0,
            mimeType: req.responseHeaders?.['content-type'] || 'application/octet-stream',
            text: req.responseBody || '',
            encoding: 'base64'
          },
          redirectURL: '',
          headersSize: -1,
          bodySize: req.responseSize || -1
        },
        cache: {},
        timings: {
          blocked: -1,
          dns: -1,
          connect: -1,
          send: -1,
          wait: -1,
          receive: -1,
          ssl: -1
        }
      }))
    }
  };
}

if (!["capture"].includes(command)) {
  console.error("Unknown command:", command);
  process.exit(1);
}
