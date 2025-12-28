#!/usr/bin/env node

import { chromium } from "playwright";

const command = process.argv[2];
const arg1 = process.argv[3];
const arg2 = process.argv[4];

if (!command || process.argv.includes("--help")) {
  console.log("Usage: dev.js <command> [args]");
  console.log("\nReal-time development commands (no reload needed):");
  console.log("\nDOM Manipulation (page.evaluate):");
  console.log("  dev.js css <selector> <styles>    # Apply CSS instantly");
  console.log("  dev.js html <selector> <html>     # Replace HTML");
  console.log("  dev.js attr <selector> <attr=val> # Set attribute");
  console.log("  dev.js class <selector> <class>   # Toggle class");
  console.log("\nAdvanced (CDP):");
  console.log("  dev.js inject-css <file>          # Inject CSS file");
  console.log("  dev.js inject-js <file>           # Inject JS file");
  console.log("  dev.js watch <file>               # Watch file and auto-inject");
  console.log("\nInteractive:");
  console.log("  dev.js repl                       # Interactive REPL mode");
  console.log("\nExamples:");
  console.log("  dev.js css '.title' 'color: red; font-size: 24px'");
  console.log("  dev.js html '#content' '<h1>New Content</h1>'");
  console.log("  dev.js class '.box' 'active'");
  console.log("  dev.js inject-css styles.css");
  console.log("  dev.js watch styles.css");
  process.exit(0);
}

try {
  const b = await chromium.connectOverCDP("http://localhost:9222");
  const contexts = b.contexts();
  const pages = contexts[0]?.pages() || [];
  const p = pages.at(-1);

  if (!p) {
    console.error("✗ No active tab found");
    console.error("  Open a page first: ./nav.js <url>");
    process.exit(1);
  }

  // Setup bidirectional communication
  await p.exposeFunction('devLog', (msg) => {
    console.log('[Browser]:', msg);
  });

  switch (command) {
    case "css": {
      const selector = arg1;
      const styles = arg2;

      if (!selector || !styles) {
        console.error("✗ Usage: dev.js css <selector> <styles>");
        process.exit(1);
      }

      await p.evaluate(({ sel, css }) => {
        const el = document.querySelector(sel);
        if (!el) {
          window.devLog(`Element not found: ${sel}`);
          return;
        }

        // Parse and apply styles
        css.split(';').forEach(rule => {
          const [prop, val] = rule.split(':').map(s => s.trim());
          if (prop && val) {
            el.style[prop.replace(/-([a-z])/g, (_, c) => c.toUpperCase())] = val;
          }
        });

        window.devLog(`CSS applied to: ${sel}`);
      }, { sel: selector, css: styles });

      console.log(`✓ CSS applied: ${selector}`);
      break;
    }

    case "html": {
      const selector = arg1;
      const html = arg2;

      if (!selector || !html) {
        console.error("✗ Usage: dev.js html <selector> <html>");
        process.exit(1);
      }

      await p.evaluate(({ sel, content }) => {
        const el = document.querySelector(sel);
        if (!el) {
          window.devLog(`Element not found: ${sel}`);
          return;
        }
        el.innerHTML = content;
        window.devLog(`HTML updated: ${sel}`);
      }, { sel: selector, content: html });

      console.log(`✓ HTML updated: ${selector}`);
      break;
    }

    case "attr": {
      const selector = arg1;
      const attrVal = arg2;

      if (!selector || !attrVal) {
        console.error("✗ Usage: dev.js attr <selector> <attr=val>");
        process.exit(1);
      }

      const [attr, val] = attrVal.split('=');

      await p.evaluate(({ sel, attribute, value }) => {
        const el = document.querySelector(sel);
        if (!el) {
          window.devLog(`Element not found: ${sel}`);
          return;
        }
        el.setAttribute(attribute, value);
        window.devLog(`Attribute set: ${sel} ${attribute}="${value}"`);
      }, { sel: selector, attribute: attr, value: val });

      console.log(`✓ Attribute set: ${selector} ${attr}="${val}"`);
      break;
    }

    case "class": {
      const selector = arg1;
      const className = arg2;

      if (!selector || !className) {
        console.error("✗ Usage: dev.js class <selector> <class>");
        process.exit(1);
      }

      await p.evaluate(({ sel, cls }) => {
        const el = document.querySelector(sel);
        if (!el) {
          window.devLog(`Element not found: ${sel}`);
          return;
        }
        el.classList.toggle(cls);
        const hasClass = el.classList.contains(cls);
        window.devLog(`Class ${hasClass ? 'added' : 'removed'}: ${sel} .${cls}`);
      }, { sel: selector, cls: className });

      console.log(`✓ Class toggled: ${selector} .${className}`);
      break;
    }

    case "inject-css": {
      const { readFileSync } = await import('fs');
      const cssFile = arg1;

      if (!cssFile) {
        console.error("✗ Usage: dev.js inject-css <file>");
        process.exit(1);
      }

      const cssContent = readFileSync(cssFile, 'utf-8');

      await p.addStyleTag({ content: cssContent });
      console.log(`✓ CSS injected: ${cssFile}`);
      break;
    }

    case "inject-js": {
      const { readFileSync } = await import('fs');
      const jsFile = arg1;

      if (!jsFile) {
        console.error("✗ Usage: dev.js inject-js <file>");
        process.exit(1);
      }

      const jsContent = readFileSync(jsFile, 'utf-8');

      await p.addScriptTag({ content: jsContent });
      console.log(`✓ JavaScript injected: ${jsFile}`);
      break;
    }

    case "watch": {
      const { watch, readFileSync } = await import('fs');
      const file = arg1;

      if (!file) {
        console.error("✗ Usage: dev.js watch <file>");
        process.exit(1);
      }

      console.log(`👀 Watching: ${file}`);
      console.log("   Press Ctrl+C to stop\n");

      // Initial inject
      const isCss = file.endsWith('.css');
      const content = readFileSync(file, 'utf-8');

      if (isCss) {
        await p.addStyleTag({ content });
      } else {
        await p.addScriptTag({ content });
      }
      console.log(`✓ Initial ${isCss ? 'CSS' : 'JS'} injected`);

      // Watch for changes
      let reloadTimeout;
      watch(file, async (eventType) => {
        if (eventType === 'change') {
          clearTimeout(reloadTimeout);
          reloadTimeout = setTimeout(async () => {
            try {
              const newContent = readFileSync(file, 'utf-8');

              if (isCss) {
                // Remove old style tags and add new
                await p.evaluate(() => {
                  document.querySelectorAll('style[data-dev-injected]').forEach(s => s.remove());
                });
                await p.addStyleTag({ content: newContent });
                await p.evaluate(() => {
                  const styles = document.querySelectorAll('style');
                  styles[styles.length - 1].setAttribute('data-dev-injected', 'true');
                });
              } else {
                await p.addScriptTag({ content: newContent });
              }

              const timestamp = new Date().toLocaleTimeString();
              console.log(`✓ [${timestamp}] Reloaded: ${file}`);
            } catch (e) {
              console.error(`✗ Error reloading: ${e.message}`);
            }
          }, 100);
        }
      });

      // Keep alive
      await new Promise(() => {});
      break;
    }

    case "repl": {
      const readline = await import('readline');
      const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout,
        prompt: 'dev> '
      });

      console.log("🔧 Interactive REPL mode");
      console.log("   Type JavaScript to execute in browser");
      console.log("   Type 'exit' to quit\n");

      rl.prompt();

      rl.on('line', async (line) => {
        const input = line.trim();

        if (input === 'exit') {
          await b.close();
          process.exit(0);
        }

        if (!input) {
          rl.prompt();
          return;
        }

        try {
          const result = await p.evaluate((code) => {
            return eval(code);
          }, input);

          if (result !== undefined) {
            console.log('=>', result);
          }
        } catch (e) {
          console.error('✗', e.message);
        }

        rl.prompt();
      });

      // Keep alive
      await new Promise(() => {});
      break;
    }

    default:
      console.error(`✗ Unknown command: ${command}`);
      console.error("  Run 'dev.js --help' for usage");
      process.exit(1);
  }

  await b.close();
} catch (e) {
  console.error("✗ Failed to execute dev command");
  console.error(`  Error: ${e.message}`);
  process.exit(1);
}
