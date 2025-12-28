#!/usr/bin/env node

import { chromium } from "playwright";

const roleFilter = process.argv.find((arg) => arg.startsWith("--role="))?.split("=")[1];
const showHelp = process.argv.includes("--help");

if (showHelp) {
  console.log("Usage: a11y.js [--role=<role>]");
  console.log("\nExamples:");
  console.log("  a11y.js                # Show full accessibility tree");
  console.log("  a11y.js --role=button  # Filter by role (button, link, heading, etc.)");
  console.log("  a11y.js --role=heading # Show only headings");
  process.exit(0);
}

const b = await chromium.connectOverCDP("http://localhost:9222");
const contexts = b.contexts();
const p = contexts[0].pages().at(-1);

if (!p) {
  console.error("✗ No active tab found");
  process.exit(1);
}

// Get accessibility snapshot
const snapshot = await p.accessibility.snapshot();

if (!snapshot) {
  console.error("✗ Could not capture accessibility tree");
  process.exit(1);
}

// Function to format and display the tree
function displayNode(node, indent = 0) {
  const prefix = "  ".repeat(indent);

  // Skip if role filter is set and doesn't match
  if (roleFilter && node.role !== roleFilter) {
    // Still process children
    if (node.children) {
      node.children.forEach((child) => displayNode(child, indent));
    }
    return;
  }

  // Build node description
  let description = `${prefix}[${node.role}]`;

  if (node.name) {
    description += ` "${node.name}"`;
  }

  if (node.value) {
    description += ` = ${node.value}`;
  }

  // Add important properties
  const props = [];
  if (node.focused) props.push("focused");
  if (node.disabled) props.push("disabled");
  if (node.checked === true) props.push("checked");
  if (node.checked === false) props.push("unchecked");
  if (node.pressed === true) props.push("pressed");
  if (node.expanded === true) props.push("expanded");
  if (node.expanded === false) props.push("collapsed");
  if (node.level) props.push(`level=${node.level}`);

  if (props.length > 0) {
    description += ` (${props.join(", ")})`;
  }

  console.log(description);

  // Process children
  if (node.children) {
    node.children.forEach((child) => displayNode(child, indent + 1));
  }
}

console.log("🌲 Accessibility Tree:\n");
displayNode(snapshot);

console.log("\n📊 Summary:");

// Count nodes by role
function countByRole(node, counts = {}) {
  if (node.role) {
    counts[node.role] = (counts[node.role] || 0) + 1;
  }
  if (node.children) {
    node.children.forEach((child) => countByRole(child, counts));
  }
  return counts;
}

const roleCounts = countByRole(snapshot);
const sortedRoles = Object.entries(roleCounts).sort((a, b) => b[1] - a[1]);

sortedRoles.forEach(([role, count]) => {
  console.log(`  ${role}: ${count}`);
});

await b.close();
