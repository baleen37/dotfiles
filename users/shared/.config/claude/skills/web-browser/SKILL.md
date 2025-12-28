---
name: web-browser
description: "Allows to interact with web pages by performing actions such as clicking buttons, filling out forms, and navigating links. It works by remote controlling Google Chrome or Chromium browsers using the Chrome DevTools Protocol (CDP). When Claude needs to browse the web, it can use this skill to do so."
license: Stolen from Mario
---

# Web Browser Skill

Minimal CDP tools for collaborative site exploration.

## Start Chrome

```bash
./tools/start.js              # Fresh profile
./tools/start.js --profile    # Copy your profile (cookies, logins)
```

Start Chrome on `:9222` with remote debugging.

## Navigate

```bash
./tools/nav.js https://example.com
./tools/nav.js https://example.com --new
```

Navigate current tab or open new tab.

## Evaluate JavaScript

```bash
./tools/eval.js 'document.title'
./tools/eval.js 'document.querySelectorAll("a").length'
./tools/eval.js 'JSON.stringify(Array.from(document.querySelectorAll("a")).map(a => ({ text: a.textContent.trim(), href: a.href })).filter(link => !link.href.startsWith("https://")))'
```

Execute JavaScript in active tab (async context).  Be careful with string escaping, best to use single quotes.

## Screenshot

```bash
./tools/screenshot.js
```

Screenshot current viewport, returns temp file path

## Pick Elements

```bash
./tools/pick.js "Click the submit button"
```

Interactive element picker. Click to select, Cmd/Ctrl+Click for multi-select, Enter to finish.

## Network Monitoring

```bash
./tools/network.js
./tools/network.js --filter=api.example.com
./tools/network.js --filter=.json
```

Monitor HTTP requests and responses in real-time. Shows method, status, URL, resource type, and content-type. Press Ctrl+C to stop and see summary.

## Accessibility Tree

```bash
./tools/a11y.js
./tools/a11y.js --role=button
./tools/a11y.js --role=heading
```

Capture and display the accessibility tree of the current page. Filter by role (button, link, heading, textbox, etc.) to focus on specific elements. Shows element hierarchy and ARIA properties.

## API Testing

```bash
./tools/api.js capture
./tools/api.js capture --filter=api.example.com
./tools/api.js capture --output=custom.har
```

Capture API requests (XHR/Fetch) and save to HAR 1.2 format. Filter by URL pattern. Press Ctrl+C to stop and save. HAR files can be analyzed with browser DevTools or replayed with Playwright.
