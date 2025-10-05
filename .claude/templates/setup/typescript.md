# TypeScript/Node.js Project Setup Template

## Directory Structure

```text
src/
  ├── domain/          # Business logic (no external dependencies)
  ├── application/     # Use cases
  ├── infrastructure/  # External services, databases
  ├── interfaces/      # Controllers, API routes
  └── shared/          # Common types, utils
tests/
  ├── unit/
  ├── integration/
  ├── e2e/
  └── architecture/    # Architecture validation tests
config/
scripts/
docs/
```

## Dependencies

```json
{
  "devDependencies": {
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0",
    "eslint": "^8.50.0",
    "prettier": "^3.0.0",
    "husky": "^8.0.0",
    "lint-staged": "^15.0.0",
    "jest": "^29.7.0",
    "ts-jest": "^29.1.0",
    "typescript": "^5.2.0"
  }
}
```

## Pre-commit Setup

**Install:**

```bash
npm install -D husky lint-staged
npx husky init
```

**`.husky/pre-commit`:**

```bash
#!/usr/bin/env sh
npx lint-staged
npm run test:architecture
npm run test:unit
```

**`package.json`:**

```json
{
  "lint-staged": {
    "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
    "*.{json,md}": ["prettier --write"]
  }
}
```

## Architecture Validation Tests

**`tests/architecture/dependency-rules.test.ts`:**

```typescript
import { describe, it, expect } from '@jest/globals';
import * as fs from 'fs';
import * as path from 'path';
import { glob } from 'glob';

describe('Architecture: Dependency Rules', () => {
  it('domain should not import from infrastructure or interfaces', () => {
    const files = glob.sync('src/domain/**/*.ts');

    files.forEach(file => {
      const content = fs.readFileSync(file, 'utf-8');
      expect(content).not.toMatch(/from ['"].*\/infrastructure/);
      expect(content).not.toMatch(/from ['"].*\/interfaces/);
    });
  });

  it('domain should not import external frameworks', () => {
    const files = glob.sync('src/domain/**/*.ts');
    const forbidden = ['express', 'fastify', 'nest', 'typeorm', 'prisma'];

    files.forEach(file => {
      const content = fs.readFileSync(file, 'utf-8');
      forbidden.forEach(lib => {
        expect(content).not.toMatch(new RegExp(`from ['"]${lib}`));
      });
    });
  });

  it('each layer should have index.ts', () => {
    const layers = ['domain', 'application', 'infrastructure', 'interfaces'];
    layers.forEach(layer => {
      expect(fs.existsSync(`src/${layer}/index.ts`)).toBe(true);
    });
  });

  it('circular dependencies should not exist', () => {
    // Use madge or dependency-cruiser for this
    const madge = require('madge');

    madge('src/').then((res: any) => {
      const circular = res.circular();
      expect(circular).toHaveLength(0);
    });
  });
});

describe('Architecture: Naming Conventions', () => {
  it('entities should end with .entity.ts', () => {
    const files = glob.sync('src/domain/entities/**/*.ts');
    files.forEach(file => {
      if (file.endsWith('index.ts')) return;
      expect(file).toMatch(/\.entity\.ts$/);
    });
  });

  it('use cases should end with .use-case.ts', () => {
    const files = glob.sync('src/application/use-cases/**/*.ts');
    files.forEach(file => {
      if (file.endsWith('index.ts')) return;
      expect(file).toMatch(/\.use-case\.ts$/);
    });
  });
});
```

## Test Configuration

**`jest.config.js`:**

```javascript
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src', '<rootDir>/tests'],
  testMatch: ['**/*.test.ts'],
  collectCoverageFrom: ['src/**/*.ts', '!src/**/*.d.ts'],
  coverageThreshold: {
    global: { branches: 80, functions: 80, lines: 80, statements: 80 }
  },
  projects: [
    {
      displayName: 'unit',
      testMatch: ['<rootDir>/tests/unit/**/*.test.ts']
    },
    {
      displayName: 'integration',
      testMatch: ['<rootDir>/tests/integration/**/*.test.ts']
    },
    {
      displayName: 'architecture',
      testMatch: ['<rootDir>/tests/architecture/**/*.test.ts']
    }
  ]
};
```

## CI Configuration

**`.github/workflows/ci.yml`:**

```yaml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint
      - run: npm run type-check
      - run: npm run test:architecture
      - run: npm run test:unit
      - run: npm run test:integration
      - run: npm run build
```

## Scripts

```json
{
  "scripts": {
    "lint": "eslint . --ext .ts",
    "type-check": "tsc --noEmit",
    "test:unit": "jest tests/unit",
    "test:integration": "jest tests/integration",
    "test:architecture": "jest tests/architecture",
    "test": "jest --coverage",
    "build": "tsc"
  }
}
```
