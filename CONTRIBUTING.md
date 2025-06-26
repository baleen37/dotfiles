# Contributing Guidelines

## Branch Naming

```
{type}/{username}/{scope}-{description}
```

**Types:** `feat/`, `fix/`, `docs/`, `test/`, `chore/`, `refactor/`

**Examples:**
- `feat/jito/auth-integration`
- `fix/jito/api-timeout`

## Commit Messages

```
<type>: <description>
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

**Examples:**
```
feat: add user authentication
fix: resolve nil pointer panic
docs: update API documentation
```

## Before PR

```bash
make test
make lint
make fmt
```

## PR Requirements

- Clear title following commit convention
- Tests for new functionality
- All checks passing
- Clean commit history