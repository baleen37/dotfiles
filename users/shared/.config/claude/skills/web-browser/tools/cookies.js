#!/usr/bin/env node

import { chromium } from "playwright";

const isList = process.argv.includes("--list");
const getName = process.argv.find(arg => arg.startsWith("--get="))?.split("=")[1];
const setArg = process.argv.find(arg => arg.startsWith("--set="))?.split("=")[1];
const deleteName = process.argv.find(arg => arg.startsWith("--delete="))?.split("=")[1];

if (process.argv.includes("--help") || (!isList && !getName && !setArg && !deleteName)) {
  console.log("Usage: cookies.js [--list | --get=<name> | --set=<name>=<value> | --delete=<name>]");
  console.log("\nManage browser cookies");
  console.log("\nExamples:");
  console.log("  cookies.js --list");
  console.log("  cookies.js --get=session_id");
  console.log("  cookies.js --set='session=abc123'");
  console.log("  cookies.js --delete=tracking_id");
  process.exit(0);
}

try {
  const b = await chromium.connectOverCDP("http://localhost:9222");
  const contexts = b.contexts();
  const context = contexts[0];

  if (!context) {
    console.error("✗ No browser context found");
    process.exit(1);
  }

  if (isList) {
    const cookies = await context.cookies();
    if (cookies.length === 0) {
      console.log("(no cookies)");
    } else {
      console.log(`Cookies (${cookies.length}):\n`);
      cookies.forEach(cookie => {
        console.log(`${cookie.name} = ${cookie.value}`);
        console.log(`  Domain: ${cookie.domain}`);
        console.log(`  Path: ${cookie.path}`);
        console.log(`  Expires: ${cookie.expires === -1 ? "Session" : new Date(cookie.expires * 1000).toISOString()}`);
        console.log("");
      });
    }
  } else if (getName) {
    const cookies = await context.cookies();
    const cookie = cookies.find(c => c.name === getName);

    if (!cookie) {
      console.log("(cookie not found)");
    } else {
      console.log(`${cookie.name} = ${cookie.value}`);
    }
  } else if (setArg) {
    const [name, ...valueParts] = setArg.split("=");
    const value = valueParts.join("=");

    if (!name || value === undefined) {
      console.error("✗ Invalid format for --set");
      console.error("  Use: --set='name=value'");
      process.exit(1);
    }

    const pages = context.pages();
    const page = pages.at(-1);
    const url = page ? await page.url() : "http://localhost";
    const domain = new URL(url).hostname;

    await context.addCookies([{
      name,
      value,
      domain,
      path: "/"
    }]);

    console.log(`✓ Cookie set: ${name} = ${value}`);
  } else if (deleteName) {
    const cookies = await context.cookies();
    const cookie = cookies.find(c => c.name === deleteName);

    if (!cookie) {
      console.log("(cookie not found)");
    } else {
      await context.addCookies([{
        name: deleteName,
        value: "",
        domain: cookie.domain,
        path: cookie.path,
        expires: 0
      }]);
      console.log(`✓ Cookie deleted: ${deleteName}`);
    }
  }

  await b.close();
} catch (e) {
  console.error("✗ Failed to manage cookies");
  console.error(`  Error: ${e.message}`);
  process.exit(1);
}
