# tests/unit/wt-hook-consistency-test.nix
# The Claude Code WorktreeCreate hook keeps its own bash copy of wt's path rule
# (wt switch -c also fetches and pulls the base branch, which the hook must not
# do). Run both against the same throwaway repository and require the same
# placement, so a change on either side fails here.
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  ...
}:

let
  hook = ../../users/shared/programs/.config/claude/setup-worktree.sh;
  worktreePackage = inputs.worktree.packages.${system}.default;
in
{
  platforms = [ "any" ];
  value =
    pkgs.runCommand "wt-hook-consistency"
      {
        nativeBuildInputs = [
          pkgs.bash
          pkgs.git
          pkgs.jq
          pkgs.coreutils
        ];
      }
      ''
        set -euo pipefail
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        git config --global user.name test
        git config --global user.email test@example.com
        git config --global init.defaultBranch main
        unset HERDR_ENV HERDR_WORKSPACE_ID

        fail() { echo "FAIL: $*" >&2; exit 1; }
        hook() { printf '{"name":"%s","cwd":"%s"}' "$1" "$2" | bash ${hook}; }

        git init -q --bare "$TMPDIR/origin.git"
        git clone -q "$TMPDIR/origin.git" "$TMPDIR/repo"
        repo="$TMPDIR/repo"
        git -C "$repo" commit -q --allow-empty -m init
        git -C "$repo" push -q origin main
        # As in real repos: otherwise wt sees the untracked dir as a dirty base.
        echo .worktrees/ >> "$repo/.git/info/exclude"

        # Placement: <main root>/.worktrees/<branch with / -> ->
        got=$(hook feat/hook "$repo")
        [ "$got" = "$repo/.worktrees/feat-hook" ] || fail "hook path: $got"
        [ "$(git -C "$got" branch --show-current)" = feat/hook ] || fail "hook branch"

        # Run from inside a linked worktree: must not nest under it.
        got=$(hook nested "$repo/.worktrees/feat-hook")
        [ "$got" = "$repo/.worktrees/nested" ] || fail "nested path: $got"

        # wt puts its worktrees in the same directory as the hook.
        wt_path=$(cd "$repo" && ${worktreePackage}/bin/wt switch -c feat/wt)
        [ "$wt_path" = "$repo/.worktrees/feat-wt" ] || fail "wt path: $wt_path"

        # master-only repositories still work.
        git init -q "$TMPDIR/legacy"
        git -C "$TMPDIR/legacy" checkout -q -b master
        git -C "$TMPDIR/legacy" commit -q --allow-empty -m init
        got=$(hook x "$TMPDIR/legacy")
        [ "$(git -C "$got" rev-parse HEAD)" = "$(git -C "$TMPDIR/legacy" rev-parse master)" ] \
          || fail "master base"

        # Missing name is an error, not a worktree named "null".
        if printf '{"cwd":"%s"}' "$repo" | bash ${hook} 2>/dev/null; then
          fail "missing name accepted"
        fi

        touch "$out"
      '';
}
