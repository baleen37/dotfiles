# Overlay Security Guidelines

## Overview

This document outlines security best practices for Nix overlays in this repository to prevent supply chain attacks and ensure reproducible builds.

## Best Practices

### 1. Use Commit Hashes Instead of Tags

When fetching source code from GitHub or other repositories, always use commit hashes instead of version tags.

**Why?**
- Version tags can be moved to point to different commits
- Commit hashes are immutable
- Provides better auditability and reproducibility

**Example:**
```nix
# ❌ Insecure: Uses tag reference
src = fetchFromGitHub {
  owner = "example";
  repo = "project";
  rev = "v1.0.0";  # Tags can be moved!
  sha256 = "...";
};

# ✅ Secure: Uses commit hash
src = fetchFromGitHub {
  owner = "example";
  repo = "project";
  rev = "abc123def456...";  # Immutable commit hash
  sha256 = "...";
};
```

### 2. Document Commit Hash Origins

Always add a comment indicating which version/tag the commit hash corresponds to:

```nix
rev = "abc123def456...";  # v1.0.0
```

### 3. Versioned Release Artifacts

For pre-built release artifacts (like `.zip` or `.tar.gz` files), using versioned URLs is acceptable as they typically don't change:

```nix
# Acceptable for release artifacts
src = fetchzip {
  url = "https://github.com/owner/repo/releases/download/v1.0.0/package-1.0.0.zip";
  sha256 = "...";
};
```

### 4. Regular Security Audits

- Periodically review all overlays for tag usage
- Update commit hashes when new versions are released
- Use automated tools to detect insecure patterns

## Finding Commit Hashes

To find the commit hash for a specific tag:

```bash
# Using GitHub API
curl -s https://api.github.com/repos/OWNER/REPO/git/refs/tags/TAG_NAME | jq -r '.object.sha'

# Using git
git ls-remote https://github.com/OWNER/REPO refs/tags/TAG_NAME
```

## Updating Dependencies

When updating overlay dependencies:

1. Find the new version's commit hash
2. Update the `rev` field
3. Clear or update the `sha256` field
4. Build to get the new hash
5. Test thoroughly before committing

## Exceptions

Some packages may require using tags due to specific build requirements. In such cases:
1. Document the reason clearly
2. Consider mirroring the source
3. Implement additional verification steps
