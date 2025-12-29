#!/usr/bin/env node

import { chromium } from "playwright";

const b = await chromium.connectOverCDP("http://localhost:9222");
const contexts = b.contexts();
const p = contexts[0].pages().at(-1);

if (!p) {
  console.error("No active tab found");
  process.exit(1);
}

// Get CDP session to access Accessibility domain
const client = await p.context().newCDPSession(p);

// Get accessibility snapshot using CDP directly
const { nodes } = await client.send('Accessibility.getFullAXTree');

if (!nodes || nodes.length === 0) {
  console.error("Could not capture accessibility tree");
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
  console.error("Could not parse accessibility tree");
  process.exit(1);
}

// Convert to YAML-like format (Playwright ARIA Snapshot style)
function toYAML(node, indent = 0) {
  const prefix = "  ".repeat(indent);

  // Skip nodes without meaningful role
  const skipRoles = ['generic', 'none', 'StaticText', 'InlineTextBox', 'LineBreak'];
  if (!node.role || skipRoles.includes(node.role)) {
    // Process children directly
    if (node.children) {
      node.children.forEach((child) => toYAML(child, indent));
    }
    return;
  }

  // Build YAML line
  let line = `${prefix}- ${node.role}`;

  if (node.name) {
    line += ` "${node.name}"`;
  }

  // Add attributes in brackets
  const attrs = [];
  if (node.level) attrs.push(`level=${node.level}`);
  if (node.checked === true) attrs.push('checked=true');
  if (node.checked === false) attrs.push('checked=false');
  if (node.pressed === true) attrs.push('pressed=true');
  if (node.pressed === false) attrs.push('pressed=false');
  if (node.expanded === true) attrs.push('expanded=true');
  if (node.expanded === false) attrs.push('expanded=false');
  if (node.disabled) attrs.push('disabled=true');
  if (node.focused) attrs.push('focused=true');

  if (attrs.length > 0) {
    line += ` [${attrs.join(', ')}]`;
  }

  // Add children indicator
  if (node.children && node.children.length > 0) {
    line += ':';
  }

  console.log(line);

  // Process children with increased indent
  if (node.children) {
    node.children.forEach((child) => toYAML(child, indent + 1));
  }
}

toYAML(snapshot);

await b.close();
