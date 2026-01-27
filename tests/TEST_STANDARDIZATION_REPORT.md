# Test Structure Standardization Report

**Date:** 2026-01-08
**Status:** In Progress
**Objective:** Standardize test structure patterns across all test files

## Summary

This report documents the progress of standardizing test structure patterns across the codebase. The goal is to ensure all tests follow consistent patterns for maintainability and ease of understanding.

## Standard Pattern Definition

All test files should follow this standard structure:

```nix
# Feature Test
#
# Description of what is being tested
# Additional context if needed
{ inputs, system, pkgs, lib, self, nixtest ? {}, ... }:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
in
{
  platforms = ["any"];  # or ["darwin"] or ["linux"]
  value = helpers.testSuite "feature-name" [
    (helpers.assertTest "test-1" condition "message")
    (helpers.assertTest "test-2" condition "message")
  ];
}
```

## Completed Standardizations

### 1. Created conventions documentation
- **File:** `/Users/baleen/dotfiles/tests/lib/conventions.nix`
- **Status:** ✅ Complete
- **Description:** Comprehensive documentation of standard test patterns, naming conventions, and anti-patterns to avoid

### 2. Standardized unit test files

#### platform-helpers-test.nix
- **Status:** ✅ Complete
- **Changes:**
  - Converted from `pkgs.runCommand` to `helpers.testSuite`
  - Added standard `platforms = ["any"]` wrapper
  - Simplified test logic using `helpers.assertTest`

#### lib-user-info-test.nix
- **Status:** ✅ Complete
- **Changes:**
  - Converted from nested attribute set to `helpers.testSuite`
  - Renamed `testHelpers` to `helpers`
  - Added standard header format

## Remaining Work

### Unit Tests Needing Standardization

#### High Priority (Easy fixes)
1. **lib-mksystem-detailed-test.nix**
   - Issue: Uses nested attribute set instead of `helpers.testSuite`
   - Effort: Medium (17 tests to convert)
   - Impact: High (core system factory test)

2. **trend-analysis-test.nix**
   - Issue: Uses `testHelpers` instead of `helpers`
   - Effort: Low (simple rename)

3. **lib-monitoring-test.nix**
   - Issue: Uses `testHelpers` instead of `helpers`
   - Effort: Low (simple rename)

#### Medium Priority (Complex tests)
4. **edge-case-git-config-test.nix**
   - Issue: Uses `testHelpers` and `pkgs.runCommand`
   - Effort: High (complex test logic)
   - Impact: Medium (edge case validation)

5. **property-based-user-management-test.nix**
   - Issue: Uses `pkgs.runCommand`
   - Effort: High (property-based testing pattern)
   - Impact: Medium (advanced testing pattern)

6. **makefile-nix-features-test.nix**
   - Issue: Uses `testHelpers` and `pkgs.runCommand`
   - Effort: Medium (Makefile integration tests)

7. **makefile-switch-commands-test.nix**
   - Issue: Uses `pkgs.runCommand`
   - Effort: Medium (Makefile integration tests)

#### Low Priority (Specialized tests)
8. **build-performance-test.nix**
   - Issue: Uses `testHelpers`, `pkgs.runCommand`, and nested attribute set
   - Effort: Very High (complex performance testing framework)
   - Impact: Low (specialized performance tests)
   - **Note:** This file may need special consideration due to its unique performance testing requirements

9. **mksimpletest-helper-test.nix**
   - Issue: Uses `testHelpers` and `pkgs.runCommand`
   - Effort: Medium (testing the test helper itself)
   - Impact: Low (meta-test)

10. **lib-performance-\*.nix** (3 files)
    - Issue: Uses `testHelpers`
    - Effort: Low (simple rename)
    - Impact: Low (performance testing utilities)

### Integration Tests Needing Standardization

1. **claude-plugin-test.nix**
   - Issue: Uses `testHelpers` and `pkgs.runCommand`
   - Effort: Medium (plugin validation tests)

2. **claude-symlink-test.nix**
   - Issue: Uses `pkgs.runCommand`
   - Effort: Low (symlink validation)

3. **claude-home-symlink-test.nix**
   - Issue: Uses `pkgs.runCommand`
   - Effort: Low (symlink validation)

## Patterns That Couldn't Be Converted

### 1. Performance Testing Framework
**Files:** `build-performance-test.nix`, `lib-performance-*.nix`

**Reason:** These files use a specialized performance testing framework with:
- Custom performance measurement utilities
- Benchmark suite creation
- Memory monitoring
- Performance baseline comparison

**Recommendation:** These tests should maintain their current structure as they serve a different purpose than standard validation tests. Consider creating a separate `helpers.perfTest` pattern in the conventions.

### 2. Test Runner Tests
**File:** `test-runner-test.nix`

**Reason:** This file tests the test runner itself and uses mock tests in a different format.

**Recommendation:** Keep as-is since it's meta-testing.

### 3. Property-Based Testing
**Files:** `property-based-*.nix`

**Reason:** These use property-based testing patterns that don't fit neatly into the standard `helpers.assertTest` model.

**Recommendation:** Consider creating a dedicated `helpers.propertyTest` pattern.

## Migration Guidelines

### For Simple Renames (testHelpers → helpers)
```bash
# Find files
grep -r "testHelpers = import" tests/

# Replace in each file
sed -i '' 's/testHelpers/helpers/g' <file>
```

### For Nested Attribute Sets → testSuite
Before:
```nix
{
  platforms = ["any"];
  value = {
    test1 = helpers.assertTest "test1" condition "message";
    test2 = helpers.assertTest "test2" condition "message";
  };
}
```

After:
```nix
{
  platforms = ["any"];
  value = helpers.testSuite "feature" [
    (helpers.assertTest "test1" condition "message")
    (helpers.assertTest "test2" condition "message")
  ];
}
```

### For pkgs.runCommand → testSuite
This requires careful analysis of the test logic. Many `pkgs.runCommand` tests have complex shell scripts that should be broken down into individual assertions.

## Statistics

### Unit Tests
- **Total files:** 22
- **Already compliant:** 10 (45%)
- **Standardized in this effort:** 2 (9%)
- **Remaining:** 10 (45%)

### Integration Tests
- **Total files:** 15
- **Already compliant:** 12 (80%)
- **Standardized in this effort:** 0 (0%)
- **Remaining:** 3 (20%)

### Overall
- **Total files:** 37
- **Already compliant:** 22 (59%)
- **Standardized in this effort:** 2 (5%)
- **Remaining:** 13 (35%)

## Recommendations

1. **Prioritize high-impact files:** Focus on core functionality tests like `lib-mksystem-detailed-test.nix` first.

2. **Create specialized patterns:** For performance testing and property-based testing, consider creating dedicated helper patterns rather than forcing them into the standard mold.

3. **Incremental migration:** Standardize files incrementally, starting with the easiest fixes (simple renames) before tackling complex conversions.

4. **Update CI/CD:** Ensure the test discovery system properly handles both old and new formats during the transition period.

5. **Documentation:** Keep the `conventions.nix` file updated as new patterns emerge or edge cases are discovered.

## Next Steps

1. Complete standardization of high-priority files
2. Create specialized patterns for performance and property-based testing
3. Update CI/CD to enforce new conventions for new tests
4. Schedule migration of remaining files
5. Remove deprecated patterns once all files are migrated

---

**Generated by:** Claude Code
**Last updated:** 2026-01-08
