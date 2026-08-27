# Baleen toolkit CLI tests.
#
# The runtime fixture exercises `bl gc --dry-run` against a real Git repository
# with a worktree whose filesystem and HEAD activity are older than three days.
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  scriptPath = ../../users/shared/programs/baleen-toolkit.sh;
  modulePath = ../../users/shared/programs/baleen-toolkit.nix;
  scriptExists = builtins.pathExists scriptPath;
  moduleExists = builtins.pathExists modulePath;
  script = if scriptExists then builtins.readFile scriptPath else "";
  module = if moduleExists then builtins.readFile modulePath else "";

  homeConfig =
    if moduleExists then
      inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          modulePath
          {
            home = {
              username = "testuser";
              homeDirectory = "/home/testuser";
              stateVersion = "24.11";
            };
            modules.programs.baleen-toolkit.enable = true;
          }
        ];
      }
    else
      null;

  packageNames =
    if moduleExists then map (package: package.name or "") homeConfig.config.home.packages else [ ];

  runtimeTest =
    pkgs.runCommand "baleen-toolkit-gc-runtime"
      {
        nativeBuildInputs = [
          pkgs.bash
          pkgs.coreutils
          pkgs.gawk
          pkgs.git
          pkgs.gnugrep
          pkgs.gnused
        ];
      }
      ''
        set -eu
        export HOME="$PWD/home"
        export GIT_CONFIG_NOSYSTEM=1
        export PATH="${pkgs.bash}/bin:${pkgs.coreutils}/bin:${pkgs.gawk}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:${pkgs.git}/bin"

        # Avoid scanning the host Nix store while testing output formatting.
        # Git worktree discovery and age classification still use real Git.
        mkdir -p fake-bin
        cat > fake-bin/du <<'EOF'
        #!/bin/sh
        path=""
        for argument in "$@"; do
          case "$argument" in
            -*) ;;
            *) path="$argument" ;;
          esac
        done
        printf '1K %s\n' "$path"
        EOF
        chmod +x fake-bin/du
        cat > fake-bin/stat <<'EOF'
        #!/bin/sh
        case "$1" in
          -c) exec "${pkgs.coreutils}/bin/stat" "$@" ;;
          -f) printf '/\n' ;;
          *) exit 1 ;;
        esac
        EOF
        chmod +x fake-bin/stat
        export PATH="$PWD/fake-bin:$PATH"

        mkdir -p "$HOME/project"
        cd "$HOME/project"
        git init -q
        git config user.email test@example.com
        git config user.name Test
        touch tracked
        git add tracked
        GIT_AUTHOR_DATE="2000-01-01T00:00:00Z" \
          GIT_COMMITTER_DATE="2000-01-01T00:00:00Z" \
          git commit -qm initial

        mkdir -p .worktrees
        git worktree add -q -b stale "$PWD/.worktrees/stale"
        git worktree add -q -b dirty "$PWD/.worktrees/dirty"
        git worktree add -q -b fresh "$PWD/.worktrees/fresh"
        git worktree add -q -b locked "$PWD/.worktrees/locked"
        git worktree lock "$PWD/.worktrees/locked"
        touch -t 200001010000 "$PWD/.worktrees/stale"
        touch -t 200001010000 "$PWD/.worktrees/locked"
        touch "$PWD/.worktrees/dirty/untracked"

        bash "${scriptPath}" gc --dry-run > output
        grep -q "stale" output
        grep -q ">= 3 days" output
        if grep -q "locked" output; then
          exit 1
        fi
        test -d "$PWD/.worktrees/stale"

        printf 'n\ny\n' | bash "${scriptPath}" gc > cleanup-output
        grep -q "removed worktree" cleanup-output
        test ! -d "$PWD/.worktrees/stale"
        test -d "$PWD/.worktrees/dirty"
        test -d "$PWD/.worktrees/fresh"
        test -d "$PWD/.worktrees/locked"

        touch "$out"
      '';

  assertScriptHas =
    name: needle:
    helpers.assertTest "bl-gc-${name}" (lib.hasInfix needle script) "bl gc should contain '${needle}'";
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "baleen-toolkit" [
    (helpers.assertTest "script-exists" scriptExists "the Baleen toolkit script should exist")
    (helpers.assertTest "module-exists" moduleExists
      "the Baleen toolkit Home Manager module should exist"
    )
    (helpers.assertTest "module-installs-bl" (lib.hasInfix "home.packages" module)
      "the Home Manager module should install bl"
    )
    (helpers.assertTest "bl-package-enabled" (builtins.elem "bl" packageNames)
      "enabling the module should put bl in home.packages"
    )
    (assertScriptHas "gc-command" "gc")
    (assertScriptHas "stats" "stats")
    (assertScriptHas "dry-run" "--dry-run")
    (assertScriptHas "worktree-removal" "git worktree remove")
    (assertScriptHas "three-day-threshold" "259200")
    (assertScriptHas "nul-safe-worktree-list" "git worktree list --porcelain -z")
    (assertScriptHas "locked-worktree-protection" "locked")
    (assertScriptHas "portable-stat" "stat -c %Y")
    (assertScriptHas "disk-summary" "df -Pk")
    (helpers.assertTest "best-effort-shell-options" (
      lib.hasInfix "bashOptions = [" module
      && lib.hasInfix ''"nounset"'' module
      && lib.hasInfix ''"pipefail"'' module
    ) "the packaged CLI should not inherit errexit over best-effort cleanup")
    (helpers.assertTest "does-not-prune-docker-volumes" (
      !(lib.hasInfix "docker volume prune" script)
    ) "bl gc must preserve Docker named volumes")
    (helpers.assertTest "does-not-delete-library-caches-root" (
      !(lib.hasInfix ''rm -rf "$HOME/Library/Caches"'' script)
    ) "bl gc must not recursively delete the whole user cache directory")
    (helpers.assertTest "does-not-delete-nix-generations" (
      !(lib.hasInfix "nix-collect-garbage -d" script)
    ) "bl gc must not delete Nix profiles or generations")
    (helpers.assertTest "runtime-dry-run" (builtins.pathExists runtimeTest)
      "bl gc --dry-run should list a clean worktree older than three days"
    )
  ];
}
