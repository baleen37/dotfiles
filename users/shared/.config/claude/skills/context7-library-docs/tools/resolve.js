#!/usr/bin/env node

/**
 * Context7 Library Resolver
 *
 * Searches Context7 API for library documentation.
 * Usage: ./resolve.js <library-name>
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

function searchLibrary(libraryName, apiKey) {
  return new Promise((resolve, reject) => {
    const url = new URL(`${CONTEXT7_API_BASE}/search`);
    url.searchParams.append('q', libraryName);

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
          reject(new Error('API endpoint not found'));
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

function formatLibraryResults(libraries) {
  if (!Array.isArray(libraries) || libraries.length === 0) {
    return {
      count: 0,
      libraries: [],
    };
  }

  return {
    count: libraries.length,
    libraries: libraries.map((lib) => ({
      id: lib.id || 'N/A',
      name: lib.name || 'N/A',
      description: lib.description || 'No description available',
      codeSnippets: lib.codeSnippets || 0,
      score: lib.score || 0,
    })),
  };
}

async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.error('Usage: ./resolve.js <library-name>');
    console.error('Example: ./resolve.js react');
    process.exit(1);
  }

  const libraryName = args[0];
  const apiKey = getApiKey();

  try {
    console.error(`Searching for: ${libraryName}`);
    const results = await searchLibrary(libraryName, apiKey);
    const formatted = formatLibraryResults(results);
    console.log(JSON.stringify(formatted, null, 2));
  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
}

main();
