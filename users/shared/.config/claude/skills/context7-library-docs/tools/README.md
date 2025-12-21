# Context7 API Tools

CLI tools for interacting with the Context7 API.

## resolve.js

Searches the Context7 API for library documentation.

### Requirements

- Node.js v18+ (uses native fetch/https)
- `CONTEXT7_API_KEY` environment variable

### Usage

```bash
# Set your API key
export CONTEXT7_API_KEY="your-api-key-here"

# Search for a library
./resolve.js react

# Or use it inline
CONTEXT7_API_KEY="your-key" ./resolve.js react
```

### Output Format

Returns JSON with library search results:

```json
{
  "count": 2,
  "libraries": [
    {
      "id": "/facebook/react",
      "name": "React",
      "description": "A JavaScript library for building user interfaces",
      "codeSnippets": 1250,
      "score": 98
    }
  ]
}
```

### Error Handling

- Missing API key: Exit code 1 with error message
- Network errors: Exit code 1 with error description
- API errors: Exit code 1 with status code and message
- Authentication failures: Exit code 1 with "Invalid API key" message
