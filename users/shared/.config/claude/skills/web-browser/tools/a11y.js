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

// Get CDP session to access Accessibility domain
const client = await p.context().newCDPSession(p);

// Get accessibility snapshot using CDP directly
const { nodes } = await client.send('Accessibility.getFullAXTree');

if (!nodes || nodes.length === 0) {
  console.error("✗ Could not capture accessibility tree");
  process.exit(1);
}

// Convert CDP accessibility nodes to standardized format
function convertNode(node, allNodes) {
  const result = {
    role: node.role?.value || 'unknown',
    name: node.name?.value || '',
  };

  if (node.value?.value) {
    result.value = node.value.value;
  }

  // Add important properties
  if (node.focused?.value) result.focused = true;
  if (node.disabled?.value) result.disabled = true;
  if (node.checked?.value) result.checked = node.checked.value === 'true';
  if (node.pressed?.value) result.pressed = node.pressed.value === 'true';
  if (node.expanded?.value) result.expanded = node.expanded.value === 'true';
  if (node.level?.value) result.level = parseInt(node.level.value);

  // Process children
  if (node.childIds && node.childIds.length > 0) {
    result.children = node.childIds
      .map(childId => allNodes.find(n => n.nodeId === childId))
      .filter(Boolean)
      .map(childNode => convertNode(childNode, allNodes));
  }

  return result;
}

// Find root node (usually the first one)
const rootNode = nodes[0];
const snapshot = convertNode(rootNode, nodes);

if (!snapshot) {
  console.error("✗ Could not parse accessibility tree");
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
