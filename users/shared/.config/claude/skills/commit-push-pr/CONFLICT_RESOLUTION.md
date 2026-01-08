# Merge Conflict Resolution Guide

Detailed guide for resolving merge conflicts before pushing PRs.

---

## Detection

Before pushing, ALWAYS check for conflicts:

```bash
# Fetch latest base branch
git fetch origin $BASE

# Check for conflicts WITHOUT merging
git merge-tree $(git merge-base HEAD origin/$BASE) HEAD origin/$BASE
```

**Output means:**
- No output = No conflicts, safe to proceed
- Conflict markers = Conflicts detected, must resolve

---

## Conflict Output Example

```
<<<<<<< HEAD
const authenticate = (user: User) => {
  return tokenService.generate(user.id);
}
=======
const authenticate = (user: User) => {
  return jwt.sign(user);
}
>>>>>>> origin/main
```

**This means:**
- `HEAD` = Your branch's version
- `origin/$BASE` = Base branch's version
- `=======` = Separator between versions

---

## Resolution Steps

### 1. Identify Conflicted Files

From the `git merge-tree` output, note all files with conflicts.

Example:
```
Auto-merging src/auth.ts
CONFLICT (content): Merge conflict in src/auth.ts
Auto-merging tests/auth.test.ts
CONFLICT (content): Merge conflict in tests/auth.test.ts
```

**Conflicts in:** `src/auth.ts`, `tests/auth.test.ts`

---

### 2. Merge Base Branch (to get conflict markers in files)

```bash
git merge origin/$BASE
```

Now files will have conflict markers you can edit.

---

### 3. Resolve Each File

For each conflicted file:

1. **Open the file**
2. **Find conflict markers:** `<<<<<<<`, `=======`, `>>>>>>>`
3. **Choose correct content:**
   - Keep HEAD version (your changes)
   - Keep base version (their changes)
   - Or combine both (manual merge)
4. **Remove ALL markers**
5. **Test the file** (if applicable: syntax check, tests, etc.)

**Example resolution:**

Before:
```typescript
<<<<<<< HEAD
const authenticate = (user: User) => {
  return tokenService.generate(user.id);
}
=======
const authenticate = (user: User) => {
  return jwt.sign(user);
}
>>>>>>> origin/main
```

After (keeping your version):
```typescript
const authenticate = (user: User) => {
  return tokenService.generate(user.id);
}
```

---

### 4. Stage Resolved Files

```bash
git add src/auth.ts tests/auth.test.ts
```

Use `git add` for each resolved file.

---

### 5. Commit the Merge Resolution

```bash
git commit -m "fix: resolve merge conflicts from $BASE"
```

**Commit message pattern:** `fix: resolve merge conflicts from <base-branch>`

---

### 6. Verify Resolution

```bash
# Check no conflicts remain
git status

# Should show:
# On branch feature/your-branch
# All conflicts fixed but you are still merging.
```

---

### 7. Proceed to Push

Only after ALL conflicts are resolved:

```bash
git push -u origin HEAD
```

Then continue with PR creation (Step 5 in main workflow).

---

## Common Conflict Patterns

### Pattern 1: Same Line Changed

Both branches modified the same line.

**Resolution:** Choose the correct version or combine intelligently.

### Pattern 2: Adjacent Lines Changed

Lines next to each other were modified.

**Resolution:** Usually safe to include both changes.

### Pattern 3: Import Reordering

Imports were reordered or organized differently.

**Resolution:** Use whichever style matches your project conventions.

### Pattern 4: Whitespace Only

Only spaces/tabs differ, no actual code change.

**Resolution:** Accept either version, or run formatter.

---

## Tips

1. **Use diff tools:** `git difftool` can show conflicts visually
2. **Ask for help:** If unsure, ask user which version to keep
3. **Test after:** Run tests to ensure resolution is correct
4. **Abort if needed:** `git merge --abort` to start over (but you'll need to resolve eventually)

---

## Verification Checklist

After resolving conflicts:

- [ ] All conflict markers removed from files
- [ ] All conflicted files staged with `git add`
- [ ] Merge commit created
- [ ] `git status` shows clean state
- [ ] Tests pass (if applicable)
- [ ] Only then proceed to push
