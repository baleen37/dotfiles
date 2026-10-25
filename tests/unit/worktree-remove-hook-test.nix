# tests/unit/worktree-remove-hook-test.nix
# The Claude Code WorktreeRemove hook replaces Claude Code's own git cleanup,
# so it alone decides what gets deleted. Run it against worktrees the
# WorktreeCreate hook made and require that it removes only clean linked
# worktrees, deletes a branch only when main already holds its changes, and
# refuses anything else.
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  ...
}:

let
  create = ../../users/shared/programs/.config/claude/setup-worktree.sh;
  remove = ../../users/shared/programs/.config/claude/remove-worktree.sh;
in
{
  platforms = [ "any" ];
  value =
    pkgs.runCommand "worktree-remove-hook"
      {
        nativeBuildInputs = [
          pkgs.git
          pkgs.jq
        ];
      }
      ''
        set -euo pipefail
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        git config --global user.name test
        git config --global user.email test@example.com
        git config --global init.defaultBranch main
        printf '.worktrees/\nnode_modules/\n' > "$HOME/.gitignore_global"
        git config --global core.excludesFile "$HOME/.gitignore_global"

        fail() { echo "FAIL: $*" >&2; exit 1; }
        create() { printf '{"name":"%s","cwd":"%s"}' "$1" "$repo" | bash ${create}; }
        remove() { printf '{"worktree_path":"%s"}' "$1" | bash ${remove}; }
        has_branch() { git -C "$repo" rev-parse --verify -q "refs/heads/$1" > /dev/null; }

        repo="$TMPDIR/repo"
        git init -q "$repo"
        git -C "$repo" commit -q --allow-empty -m init

        # Clean, nothing new: worktree and branch both go.
        wt=$(create merged)
        mkdir "$wt/node_modules" && touch "$wt/node_modules/dep.js"
        remove "$wt" || fail "clean worktree with ignored files not removed"
        [ ! -e "$wt" ] || fail "merged: directory left"
        ! has_branch merged || fail "merged: branch left"

        # Unmerged commits: worktree goes, branch stays.
        wt=$(create unmerged)
        echo work > "$wt/work" && git -C "$wt" add work && git -C "$wt" commit -q -m work
        remove "$wt" || fail "unmerged worktree not removed"
        [ ! -e "$wt" ] || fail "unmerged: directory left"
        has_branch unmerged || fail "unmerged: branch deleted"

        # Squash-merged into main while the main checkout sits on another
        # branch: the branch still goes, judged against main, not HEAD.
        wt=$(create squashed)
        echo change > "$wt/file" && git -C "$wt" add file && git -C "$wt" commit -q -m work
        echo change > "$repo/file" && git -C "$repo" add file && git -C "$repo" commit -q -m squash
        git -C "$repo" checkout -q -b elsewhere
        remove "$wt" || fail "squashed worktree not removed"
        ! has_branch squashed || fail "squashed: branch left"
        git -C "$repo" checkout -q main

        # Untracked work: refused, everything stays.
        wt=$(create dirty)
        touch "$wt/notes.txt"
        if remove "$wt" 2> /dev/null; then fail "dirty worktree removed"; fi
        [ -f "$wt/notes.txt" ] || fail "dirty: work lost"
        has_branch dirty || fail "dirty: branch deleted"

        # The main checkout and plain directories are never touched.
        if remove "$repo" 2> /dev/null; then fail "main checkout accepted"; fi
        [ -d "$repo/.git" ] || fail "main checkout damaged"
        mkdir "$TMPDIR/plain"
        if remove "$TMPDIR/plain" 2> /dev/null; then fail "plain directory accepted"; fi
        [ -d "$TMPDIR/plain" ] || fail "plain directory deleted"

        # Already gone counts as removed.
        remove "$TMPDIR/does-not-exist" || fail "missing path is an error"

        touch "$out"
      '';
}
