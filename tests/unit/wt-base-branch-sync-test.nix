# tests/unit/wt-base-branch-sync-test.nix
# Verify wt updates the base branch before creating a new worktree.
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  wtScript = import ../../users/shared/programs/zsh/wt.nix;
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "wt-base-branch-sync" [
    (helpers.assertTest "wt-finds-base-worktree" (lib.hasInfix "git worktree list --porcelain" wtScript)
      "wt should find the worktree where the base branch is checked out"
    )

    (helpers.assertTest "wt-defines-base-branch-updater" (lib.hasInfix "_update_base_branch" wtScript)
      "wt should define a helper for updating the base branch"
    )

    (helpers.assertTest "wt-fetches-origin-before-creation"
      (lib.hasInfix "git -C \"$base_root\" fetch origin" wtScript)
      "wt should fetch origin before creating a new worktree"
    )

    (helpers.assertTest "wt-pulls-base-fast-forward-only"
      (lib.hasInfix "git -C \"$base_root\" pull --ff-only origin \"$base_branch\"" wtScript)
      "wt should update the base branch with a fast-forward-only pull"
    )

    (helpers.assertTest "wt-rejects-dirty-base-worktree"
      (lib.hasInfix "git -C \"$base_root\" status --porcelain" wtScript)
      "wt should check the base worktree for uncommitted changes"
    )

    (helpers.assertTest "wt-updates-only-new-branches"
      (lib.hasInfix ''if [[ "$branch_existed" -eq 0 ]]'' wtScript)
      "wt should update the base branch only when creating a new branch"
    )

    (helpers.assertTest "wt-stops-when-base-update-fails"
      (lib.hasInfix ''_update_base_branch "$base_branch" || return 1'' wtScript)
      "wt should stop before worktree creation when base update fails"
    )
  ];
}
