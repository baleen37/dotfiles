#!/usr/bin/env node

import { chromium } from "playwright";
import { execSync } from "child_process";

if (process.argv.includes("--help")) {
  console.log("Usage: stop.js");
  console.log("\nStop Chrome CDP server");
  process.exit(0);
}

try {
  // Try graceful disconnect first
  const b = await chromium.connectOverCDP("http://localhost:9222");
  await b.close();
  console.log("✓ Disconnected from Chrome");
} catch (e) {
  // Chrome already stopped or not running
}

// Kill Chrome processes
try {
  if (process.platform === "darwin") {
    execSync("pkill -f 'Google Chrome.*remote-debugging-port=9222'", { stdio: "ignore" });
  } else if (process.platform === "linux") {
    execSync("pkill -f 'chrome.*remote-debugging-port=9222'", { stdio: "ignore" });
  } else if (process.platform === "win32") {
    execSync('taskkill /F /IM chrome.exe /FI "COMMANDLINE like *remote-debugging-port=9222*"', { stdio: "ignore" });
  }
  console.log("✓ Chrome stopped");
} catch (e) {
  console.log("✓ Chrome already stopped");
}
