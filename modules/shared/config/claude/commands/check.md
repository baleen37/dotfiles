---
name: check
description: "Test, verify, and commit implemented features with comprehensive validation"
agents: []
---

# /check - Test, Verify & Commit

**Purpose**: Test, verify, and commit implemented features. Quality validation and automatic git commit only.

## Usage

```bash
/check "user authentication implementation"
/check "rate limiting middleware"
/check "database query optimization"
```

## Process

1. **Test**: Run all relevant test suites
2. **Verify**: Check functionality and quality  
3. **Commit**: Auto-commit with descriptive message

## Commit Strategy

- **Pass**: Auto-commit with co-author attribution
- **Fail**: Report issues, suggest fixes, no commit

## Example

```
/check "JWT authentication"

→ Tests: ✅ 15/15 passing
→ Quality: ✅ Style consistent  
→ Security: ✅ No vulnerabilities
→ Commit: "feat: implement JWT authentication"
→ Ready for next cycle
```
