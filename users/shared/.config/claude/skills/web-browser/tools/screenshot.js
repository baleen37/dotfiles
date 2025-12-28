#!/usr/bin/env node

import { tmpdir } from "node:os";
import { join } from "node:path";
import { chromium } from "playwright";

const b = await chromium.connectOverCDP("http://localhost:9222");
const contexts = b.contexts();
const p = contexts[0].pages().at(-1);

if (!p) {
  console.error("✗ No active tab found");
  process.exit(1);
}

const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
const filename = `screenshot-${timestamp}.png`;
const filepath = join(tmpdir(), filename);

await p.screenshot({ path: filepath });

console.log(filepath);

await b.close();
