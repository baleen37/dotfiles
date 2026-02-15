# D2 Coding Font Installation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Install D2 Coding font via Nix and configure Ghostty to use it as Korean fallback font.

**Architecture:** Add `d2coding` package to Home Manager configuration, then update Ghostty config with font-family fallback chain (JetBrains Mono → D2Coding).

**Tech Stack:** Nix (Home Manager), Ghostty terminal emulator

---

## Task 1: Add D2 Coding Font Package

**Files:**
- Modify: `users/shared/home-manager.nix:122-124`

**Step 1: Add d2coding to packages list**

Locate the Fonts section (line 122-124) and add `d2coding`:

```nix
# Fonts
noto-fonts-cjk-sans
cascadia-code
d2coding
```

**Step 2: Verify syntax**

Run: `nix flake check --impure`

Expected: Build succeeds without syntax errors

**Step 3: Commit**

```bash
git add users/shared/home-manager.nix
git commit -m "feat(fonts): add D2 Coding for Korean characters

Add d2coding package to home-manager fonts for Korean character
support in terminal. Will be used as Ghostty font fallback.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 2: Configure Ghostty Font Fallback

**Files:**
- Modify: `users/shared/.config/ghostty/config:5`

**Step 1: Add D2Coding fallback to font configuration**

After line 5 (font-family = JetBrains Mono), add D2Coding fallback:

```
# Font Configuration
font-family = JetBrains Mono
font-family = D2Coding
font-size = 14
```

**Step 2: Verify configuration syntax**

Run: `cat users/shared/.config/ghostty/config | grep -A 2 "Font Configuration"`

Expected output:
```
# Font Configuration
font-family = JetBrains Mono
font-family = D2Coding
font-size = 14
```

**Step 3: Commit**

```bash
git add users/shared/.config/ghostty/config
git commit -m "feat(ghostty): add D2 Coding as Korean font fallback

Configure font-family fallback chain:
- JetBrains Mono (primary for English/symbols)
- D2Coding (fallback for Korean characters)

Ghostty 1.2.0+ auto-adjusts fallback font size for consistent
line height.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 3: Build and Apply Configuration

**Files:**
- None (build/deployment task)

**Step 1: Build configuration**

Run: `make build`

Expected: Build completes successfully with d2coding package included

**Step 2: Apply configuration**

Run: `make switch`

Expected: Configuration applied, fonts installed to system

**Step 3: Verify font installation**

Run: `fc-list | grep -i d2`

Expected output (contains D2Coding entries):
```
/nix/store/.../share/fonts/truetype/D2Coding.ttc: D2Coding:style=Regular
/nix/store/.../share/fonts/truetype/D2Coding.ttc: D2Coding:style=Bold
```

**Step 4: Verify Ghostty config symlink**

Run: `cat ~/.config/ghostty/config | grep font-family`

Expected output:
```
font-family = JetBrains Mono
font-family = D2Coding
```

---

## Task 4: Runtime Verification

**Files:**
- None (manual testing task)

**Step 1: Test font rendering**

1. Open Ghostty terminal (or restart if already open)
2. Type: `Hello 안녕하세요`
3. Verify visual rendering:
   - "Hello" should render in JetBrains Mono (ligatures, wider spacing)
   - "안녕하세요" should render in D2Coding (proper Korean glyphs)
   - Line height should be consistent (no gaps)

**Step 2: Test font fallback behavior**

Type mixed content to verify fallback:
```
English text
한글 텍스트
Mixed English and 한글
```

Verify:
- English consistently uses JetBrains Mono
- Korean consistently uses D2Coding
- No rendering artifacts or spacing issues

**Step 3: Verify font metrics**

Check that line height is consistent across font changes:
```
aaaaaaaaaa
가가가가가
aaaaaaaaaa
```

Expected: All three lines should have same vertical spacing

---

## Task 5: Update Tests

**Files:**
- Modify: `tests/integration/ghostty-test.nix:74-75`

**Step 1: Update font family test assertion**

Change the test to verify both font families are set:

```nix
# Before (line 74-75):
(helpers.assertTest "ghostty-font-family-set" (hasConfigLine "font-family.*=.*Cascadia Code")
  "Ghostty should have font-family set to Cascadia Code"

# After:
(helpers.assertTest "ghostty-font-family-jetbrains-set"
  (hasConfigLine "font-family.*=.*JetBrains Mono")
  "Ghostty should have JetBrains Mono as primary font")

(helpers.assertTest "ghostty-font-family-d2coding-set"
  (hasConfigLine "font-family.*=.*D2Coding")
  "Ghostty should have D2Coding as fallback font")
```

**Step 2: Run integration tests**

Run: `make test-integration`

Expected: All tests pass including new font-family assertions

**Step 3: Commit**

```bash
git add tests/integration/ghostty-test.nix
git commit -m "test(ghostty): update font family assertions

Update integration tests to verify:
- JetBrains Mono set as primary font
- D2Coding set as fallback font

Replaces outdated Cascadia Code assertion.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 6: Final Verification

**Files:**
- None (comprehensive verification task)

**Step 1: Run full test suite**

Run: `make test-all`

Expected: All unit, integration, and container tests pass

**Step 2: Verify build reproducibility**

Run: `nix flake check --impure`

Expected: All checks pass (basic, fonts, integration)

**Step 3: Verify git status clean**

Run: `git status`

Expected: All changes committed, working tree clean

**Step 4: Document completion**

Create summary of changes:
- Added `d2coding` package to home-manager.nix
- Configured Ghostty font fallback (JetBrains Mono → D2Coding)
- Updated integration tests for font verification
- All tests passing
- Ready for merge to main

---

## Success Criteria

- [ ] D2 Coding font installed via Nix (`fc-list` shows D2Coding)
- [ ] Ghostty config has font-family fallback chain
- [ ] Configuration builds successfully (`make build`)
- [ ] Configuration applies without errors (`make switch`)
- [ ] Korean characters render in D2Coding font
- [ ] English characters render in JetBrains Mono font
- [ ] Line height consistent across font fallback
- [ ] Integration tests pass (`make test-integration`)
- [ ] All tests pass (`make test-all`)
- [ ] All changes committed to git

---

## Rollback Plan

If issues occur:

```bash
# Revert Ghostty config
git checkout HEAD~1 users/shared/.config/ghostty/config

# Revert home-manager changes
git checkout HEAD~2 users/shared/home-manager.nix

# Rebuild and switch
make switch
```

## References

- Design doc: `docs/plans/2025-02-15-d2-coding-font-design.md`
- [d2codingfont on MyNixOS](https://mynixos.com/nixpkgs/package/d2coding)
- [Ghostty Font Configuration](https://ghostty.org/docs/config/reference)
