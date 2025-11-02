# Mock Reduction Strategy

## Overview
Gradual replacement of mocks with real dependencies while maintaining test stability and improving test reliability.

## Current Mock Usage Analysis

### High-Impact Mocks (36 total occurrences across 7 files)

1. **claude-test.nix**:
   - `mockClaude` (writeShellScriptBin)
   - `mockFileSystem` (functions)
   - External: `pkgs.jq`, `pkgs.cmark`

2. **Multiple files**:
   - `pathExists` structural tests (17 occurrences)
   - File system operation mocks
   - External executable mocks

## Reduction Priority Matrix

| Priority | Mock Type | Impact | Risk | Action |
|----------|-----------|---------|------|---------|
| **P1** | `pathExists` structural tests | High | Low | Convert to behavioral |
| **P2** | `pkgs.jq`/`pkgs.cmark` | High | Low | Use pure Nix JSON parsing |
| **P3** | `mockFileSystem` | Medium | Low | Use real file operations |
| **P4** | `mockClaude` | Medium | Medium | Keep with reduced scope |
| **P5** | External executable mocks | Low | High | Keep until later phase |

## Phase 1: High-Impact, Low-Risk Replacements

### 1.1 Replace `pathExists` Structural Tests

**Current Pattern**:
```nix
# ❌ Anti-pattern
test-file-exists = assertTest "file-exists" (builtins.pathExists "./config.json");
```

**Target Pattern**:
```nix
# ✅ Behavioral test
test-config-validation =
  let config = import ./config.nix;
  in assertTest "config-valid" (lib.isDerivation config.result);
```

**Files to Update**:
- All 17 `pathExists` occurrences across unit tests

### 1.2 Replace External Tool Dependencies

**Current** (claude-test.nix):
```nix
# ❌ Using external tools
buildInputs = [ pkgs.jq pkgs.cmark mockClaude ];
${pkgs.jq}/bin/jq . "${claudeDir}/settings.json"
${pkgs.cmark}/bin/cmark -t html "${claudeDir}/CLAUDE.md"
```

**Target**:
```nix
# ✅ Pure Nix approach
settings = builtins.fromJSON (builtins.readFile settingsPath);
isMarkdown = builtins.match ".*#.*" content != null;
```

## Phase 2: Medium-Impact Replacements

### 2.1 File System Mock Reduction

**Current**:
```nix
mockFileSystem = {
  exists = path: builtins.pathExists path;
  readDir = path: if builtins.pathExists path then builtins.readDir path else {};
};
```

**Target**:
```nix
# Use real file operations where appropriate
# Keep mocks only for truly external dependencies
```

### 2.2 Mock Scope Reduction

**Current** (claude-test.nix):
```nix
mockClaude = pkgs.writeShellScriptBin "claude" ''
  echo "Mock Claude: $@"
  # Complex mock behavior
'';
```

**Target**:
```nix
# Simplified mock for only essential behavior
mockClaude = {
  version = "1.0.0";
  exists = true;
};
```

## Phase 3: Low-Impact, High-Risk Replacements

### 3.1 External Executable Mocks

Keep these mocks for now but document their purpose:
- Git command mocks
- Network call mocks
- System integration mocks

## Implementation Strategy

### Step-by-Step Process

1. **Week 1**: Replace all `pathExists` structural tests
2. **Week 2**: Remove external tool dependencies (`jq`, `cmark`)
3. **Week 3**: Simplify file system mocks
4. **Week 4**: Reduce mock scope and complexity

### Validation Process

For each replacement:
1. **Create new behavioral test alongside existing mock test**
2. **Run both tests in parallel** for 1 week
3. **Remove mock test** once behavioral test is stable
4. **Update test documentation**

### Success Metrics

- **Reduce mock count**: 36 → 15 (58% reduction)
- **Maintain test coverage**: 100% functionality preserved
- **Improve test reliability**: Target 95% pass rate consistently
- **Reduce test execution time**: Target 20% faster execution

## Specific File Transformation Plans

### claude-test.nix Transformation

**Before**:
- Uses `pkgs.jq` for JSON validation
- Uses `pkgs.cmark` for markdown validation
- Creates complex mock executable
- External tool dependencies in buildInputs

**After**:
- Pure Nix JSON parsing with `builtins.fromJSON`
- Simple markdown structure validation with regex
- Simplified mock data structure
- No external build dependencies

### git-test.nix, vim-test.nix, hammerspoon-test.nix

**Action**: Move to integration tests (already completed in boundary violations)
**Result**: These are now integration tests in `tests/integration/`, reducing unit test mock needs

## Risk Mitigation

### Potential Issues & Solutions

1. **Test Flakiness from Real Dependencies**
   - Solution: Use deterministic test data
   - Fallback: Keep critical mocks as safety net

2. **Performance Degradation**
   - Solution: Cache expensive operations
   - Monitor test execution times

3. **Breakages During Transition**
   - Solution: Run old and new tests in parallel
   - Rollback plan: Keep mock tests until new tests are stable

### Rollback Criteria

If any of these occur, pause and evaluate:
- Test pass rate drops below 90%
- Test execution time increases by >50%
- CI failures increase by >25%

## Next Steps

1. **Start with Phase 1.1**: Replace `pathExists` structural tests
2. **Update test documentation** with new behavioral patterns
3. **Create migration tracking** in the improvement plan
4. **Set up monitoring** for test reliability metrics

## Timeline

- **Phase 1** (2 weeks): High-impact, low-risk replacements
- **Phase 2** (2 weeks): Medium-impact replacements
- **Phase 3** (2 weeks): Low-impact, high-risk replacements
- **Total**: 6 weeks for complete mock reduction

This gradual approach ensures test stability while systematically reducing mock dependencies and improving test quality.
