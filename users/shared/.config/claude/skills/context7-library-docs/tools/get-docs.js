#!/usr/bin/env node

/**
 * Context7 Documentation Fetcher
 *
 * Fetches documentation from Context7 API for a specific library.
 * Usage: ./get-docs.js <library-id> [--mode=code|info] [--topic=<topic>] [--page=<N>]
 *
 * Examples:
 *   ./get-docs.js /facebook/react --topic=hooks
 *   ./get-docs.js /vercel/next.js --mode=info --topic=routing
 *   ./get-docs.js /mongodb/docs/v7.0.0 --page=2
 */

import https from 'https';

const CONTEXT7_API_BASE = 'https://context7.com/api/v2';

function getApiKey() {
  const apiKey = process.env.CONTEXT7_API_KEY;
  if (!apiKey) {
    console.error('Error: CONTEXT7_API_KEY environment variable is not set');
    process.exit(1);
  }
  return apiKey;
}

function parseLibraryId(libraryId) {
  // Format: /owner/repo or /owner/repo/version
  const match = libraryId.match(/^\/([^/]+)\/([^/]+)(?:\/(.+))?$/);
  if (!match) {
    throw new Error(
      'Invalid library ID format. Expected: /owner/repo or /owner/repo/version'
    );
  }

  return {
    owner: match[1],
    repo: match[2],
    version: match[3] || null,
  };
}

function parseArgs(args) {
  const parsed = {
    libraryId: null,
    mode: 'code',
    topic: null,
    page: 1,
  };

  for (const arg of args) {
    if (arg.startsWith('--mode=')) {
      const mode = arg.substring(7);
      if (mode !== 'code' && mode !== 'info') {
        throw new Error('Invalid mode. Use --mode=code or --mode=info');
      }
      parsed.mode = mode;
    } else if (arg.startsWith('--topic=')) {
      parsed.topic = arg.substring(8);
    } else if (arg.startsWith('--page=')) {
      const page = parseInt(arg.substring(7), 10);
      if (isNaN(page) || page < 1) {
        throw new Error('Invalid page number. Must be a positive integer');
      }
      parsed.page = page;
    } else if (arg.startsWith('/')) {
      if (parsed.libraryId) {
        throw new Error('Multiple library IDs provided');
      }
      parsed.libraryId = arg;
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  if (!parsed.libraryId) {
    throw new Error('Library ID is required');
  }

  return parsed;
}

function getDocs(libraryId, mode, topic, page, apiKey) {
  return new Promise((resolve, reject) => {
    const { owner, repo, version } = parseLibraryId(libraryId);

    // Build URL path
    let path = `/docs/${mode}/${owner}/${repo}`;
    if (version) {
      path += `/${version}`;
    }

    const url = new URL(`${CONTEXT7_API_BASE}${path}`);
    if (topic) {
      url.searchParams.append('topic', topic);
    }
    url.searchParams.append('page', page.toString());

    const options = {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Accept': 'application/json',
      },
    };

    const req = https.request(url, options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        if (res.statusCode === 200) {
          try {
            const jsonData = JSON.parse(data);
            resolve(jsonData);
          } catch (error) {
            reject(new Error(`Failed to parse JSON response: ${error.message}`));
          }
        } else if (res.statusCode === 401) {
          reject(new Error('Authentication failed: Invalid API key'));
        } else if (res.statusCode === 404) {
          reject(new Error('Library or documentation not found'));
        } else {
          reject(new Error(`API request failed with status ${res.statusCode}: ${data}`));
        }
      });
    });

    req.on('error', (error) => {
      reject(new Error(`Network error: ${error.message}`));
    });

    req.setTimeout(10000, () => {
      req.destroy();
      reject(new Error('Request timeout after 10 seconds'));
    });

    req.end();
  });
}

async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.error('Usage: ./get-docs.js <library-id> [--mode=code|info] [--topic=<topic>] [--page=<N>]');
    console.error('');
    console.error('Library ID format: /owner/repo or /owner/repo/version');
    console.error('');
    console.error('Examples:');
    console.error('  ./get-docs.js /facebook/react --topic=hooks');
    console.error('  ./get-docs.js /vercel/next.js --mode=info --topic=routing');
    console.error('  ./get-docs.js /mongodb/docs/v7.0.0 --page=2');
    process.exit(1);
  }

  const apiKey = getApiKey();

  try {
    const parsed = parseArgs(args);
    const { libraryId, mode, topic, page } = parsed;

    console.error(`Fetching ${mode} documentation for: ${libraryId}`);
    if (topic) {
      console.error(`Topic: ${topic}`);
    }
    console.error(`Page: ${page}`);

    const results = await getDocs(libraryId, mode, topic, page, apiKey);
    console.log(JSON.stringify(results, null, 2));
  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
}

main();
