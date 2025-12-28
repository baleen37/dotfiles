---
name: web-browser
description: "Use when you need to interact with websites - clicking buttons, filling forms, analyzing page structure, or monitoring network traffic. Provides browser automation via Playwright and Chrome DevTools Protocol (CDP)."
license: Stolen from Mario
---

# Web Browser Skill

Browser automation tools for development, testing, and debugging.

## When to Use

- Test or debug web applications
- Extract data from websites
- Analyze page structure and accessibility
- Monitor API calls and network traffic
- Real-time development (no reload needed)

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

## Browser Control

```bash
./tools/stop.js                                # Stop Chrome
./tools/click.js 'button.submit'              # Click element
./tools/click.js '#login-btn' --force         # Force click hidden element
./tools/type.js 'input[name=email]' 'test@example.com'
./tools/type.js '#search' 'query' --delay=100 # Slow typing
```

Basic browser interactions - stop Chrome, click elements, type text.

## Data Extraction

```bash
./tools/extract.js 'h1' --text                # First h1 text
./tools/extract.js 'a' --attr=href --all      # All link hrefs
./tools/extract.js '#content' --html          # Content HTML
./tools/extract.js '.price' --text --all      # All prices
```

Extract HTML, text, or attributes from elements. Use `--all` for multiple matches.

## Wait & Timing

```bash
./tools/wait.js '.loading-spinner' --state=hidden
./tools/wait.js '#content' --timeout=5000
./tools/wait.js '.success-message'            # Default: wait for visible
```

Wait for elements to reach specific states (visible, hidden, attached, detached). Essential for async pages.

## Console Monitoring

```bash
./tools/console.js                            # All console messages
./tools/console.js --level=error              # Only errors
./tools/console.js --filter='API'             # Messages containing 'API'
```

Capture browser console logs in real-time. Press Ctrl+C for summary.

## Cookie Management

```bash
./tools/cookies.js --list
./tools/cookies.js --get=session_id
./tools/cookies.js --set='session=abc123'
./tools/cookies.js --delete=tracking_id
```

Manage browser cookies - list, get, set, delete.

## Real-time Development (No Reload!)

```bash
# Apply CSS instantly
./tools/dev.js css '.title' 'color: red; font-size: 24px'

# Replace HTML
./tools/dev.js html '#content' '<h1>New Content</h1>'

# Toggle class
./tools/dev.js class '.box' 'active'

# Set attribute
./tools/dev.js attr 'img' 'src=new-image.png'

# Inject CSS/JS files
./tools/dev.js inject-css styles.css
./tools/dev.js inject-js script.js

# Watch mode - auto-reload on file changes
./tools/dev.js watch styles.css

# Interactive REPL
./tools/dev.js repl
```

Most efficient workflow: changes apply instantly without page reload. Watch mode monitors file changes and auto-injects. 10-20x faster than screenshot-based development.

## Common Workflows

### API Debugging
```bash
./tools/start.js --profile
./tools/nav.js https://app.example.com
./tools/api.js capture --filter=/api/ --output=requests.har
# (perform actions in browser)
# Ctrl+C to save
./tools/eval.js 'await fetch("/api/data").then(r => r.json())'
```

### Form Testing
```bash
./tools/start.js
./tools/nav.js https://example.com/login
./tools/type.js 'input[name=email]' 'test@example.com'
./tools/type.js 'input[name=password]' 'password123'
./tools/click.js 'button[type=submit]'
./tools/wait.js '.dashboard'
./tools/screenshot.js
```

### Live CSS Development
```bash
./tools/start.js --profile
./tools/nav.js https://localhost:3000
./tools/dev.js watch styles.css
# Edit styles.css in your editor → saves → instantly see changes!
```

### Accessibility Audit
```bash
./tools/start.js
./tools/nav.js https://example.com
./tools/a11y.js --role=button
./tools/a11y.js --role=heading
./tools/console.js --level=error
```
