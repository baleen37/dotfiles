# Baleen toolkit CLI tests.
#
# The runtime fixture exercises `bl gc --dry-run` against two real Git
# repositories under HOME, including worktrees whose filesystem and HEAD
# activity are older than three days.
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
          pkgs.findutils
          pkgs.gnugrep
          pkgs.gnused
        ];
      }
      ''
        set -eu
        export HOME="$PWD/home"
        export GIT_CONFIG_NOSYSTEM=1
        export PATH="${pkgs.bash}/bin:${pkgs.coreutils}/bin:${pkgs.gawk}/bin:${pkgs.findutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:${pkgs.git}/bin"

        # Avoid scanning the host Nix store while testing output formatting.
        # Git worktree discovery and age classification still use real Git.
        mkdir -p fake-bin
        fake_bin="$PWD/fake-bin"
        cat > "$fake_bin/du" <<'EOF'
        #!/bin/sh
        path=""
        for argument in "$@"; do
          case "$argument" in
            -*) ;;
            *) path="$argument" ;;
          esac
        done
        if [ "$path" = "/nix/store" ]; then
          printf 'du-start\n' >> "$GC_PHASE_LOG"
          sleep 1
          printf 'du-end\n' >> "$GC_PHASE_LOG"
        fi
        printf '1K %s\n' "$path"
        EOF
        chmod +x "$fake_bin/du"
        cat > "$fake_bin/stat" <<'EOF'
        #!/bin/sh
        case "$1" in
          -c) exec "${pkgs.coreutils}/bin/stat" "$@" ;;
          -f) printf '/\n' ;;
          *) exit 1 ;;
        esac
        EOF
        chmod +x "$fake_bin/stat"
        export PATH="$fake_bin:$PATH"

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

        mkdir -p "$HOME/other-project"
        cd "$HOME/other-project"
        git init -q
        git config user.email test@example.com
        git config user.name Test
        touch tracked
        git add tracked
        GIT_AUTHOR_DATE="2000-01-01T00:00:00Z" \
          GIT_COMMITTER_DATE="2000-01-01T00:00:00Z" \
          git commit -qm initial
        mkdir -p "$HOME/other-worktrees"
        git worktree add -q -b external-stale "$HOME/other-worktrees/external-stale"
        touch -t 200001010000 "$HOME/other-worktrees/external-stale"

        export GIT_METADATA_LOG="$PWD/git-metadata.log"
        export GC_PHASE_LOG="$PWD/gc-phase.log"
        export REAL_GIT="${pkgs.git}/bin/git"
        export REAL_FIND="${pkgs.findutils}/bin/find"
        : > "$GIT_METADATA_LOG"
        : > "$GC_PHASE_LOG"
        cat > "$fake_bin/find" <<'EOF'
        #!/bin/sh
        printf 'find-start\n' >> "$GC_PHASE_LOG"
        sleep 1
        printf 'find-end\n' >> "$GC_PHASE_LOG"
        exec "$REAL_FIND" "$@"
        EOF
        chmod +x "$fake_bin/find"
        cat > "$fake_bin/git" <<'EOF'
        #!/bin/sh
        if [ "$1" = "-C" ] && [ "$3" = "rev-parse" ]; then
          case "$4" in
            --git-dir)
              if [ "$5" = "--git-common-dir" ]; then
                printf 'combined\n' >> "$GIT_METADATA_LOG"
              else
                printf 'git-dir\n' >> "$GIT_METADATA_LOG"
              fi
              ;;
            --git-common-dir) printf 'common-dir\n' >> "$GIT_METADATA_LOG" ;;
          esac
        fi
        if [ "$1" = "-C" ] && [ "$3" = "symbolic-ref" ]; then
          printf 'symbolic-ref\n' >> "$GIT_METADATA_LOG"
        fi
        exec "$REAL_GIT" "$@"
        EOF
        chmod +x "$fake_bin/git"

        cd "$HOME"

        bash "${scriptPath}" gc --dry-run > output
        grep -q "stale" output
        grep -q "external-stale" output
        grep -q ">= 3 days" output
        combined_count=$(grep -c '^combined$' "$GIT_METADATA_LOG" || true)
        legacy_count=$(grep -c -E '^(git-dir|common-dir)$' "$GIT_METADATA_LOG" || true)
        branch_count=$(grep -c '^symbolic-ref$' "$GIT_METADATA_LOG" || true)
        du_start=$(grep -n '^du-start$' "$GC_PHASE_LOG" | cut -d: -f1)
        du_end=$(grep -n '^du-end$' "$GC_PHASE_LOG" | cut -d: -f1)
        find_start=$(grep -n '^find-start$' "$GC_PHASE_LOG" | cut -d: -f1)
        find_end=$(grep -n '^find-end$' "$GC_PHASE_LOG" | cut -d: -f1)
        test "$combined_count" -eq 5
        test "$legacy_count" -eq 0
        test "$branch_count" -eq 0
        test "$du_start" -lt "$find_end"
        test "$find_start" -lt "$du_end"
        if grep -q "locked" output; then
          exit 1
        fi
        test -d "$HOME/project/.worktrees/stale"

        printf 'n\ny\n' | bash "${scriptPath}" gc > cleanup-output
        grep -q "removed worktree" cleanup-output
        test ! -d "$HOME/project/.worktrees/stale"
        test ! -d "$HOME/other-worktrees/external-stale"
        test -d "$HOME/project/.worktrees/dirty"
        test -d "$HOME/project/.worktrees/fresh"
        test -d "$HOME/project/.worktrees/locked"
        test -d "$HOME/project/.git"
        test -d "$HOME/other-project/.git"

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
    (assertScriptHas "worktree-removal" "worktree remove")
    (assertScriptHas "three-day-threshold" "259200")
    (assertScriptHas "locked-worktree-protection" "locked")
    (assertScriptHas "portable-stat" "stat -c %Y")
    (assertScriptHas "home-worktree-discovery" "find")
    (assertScriptHas "nul-safe-home-scan" "-print0")
    (assertScriptHas "disk-summary" "df -Pk")
    (helpers.assertTest "best-effort-shell-options" (
      lib.hasInfix "bashOptions = [" module
      && lib.hasInfix ''"nounset"'' module
      && lib.hasInfix ''"pipefail"'' module
    ) "the packaged CLI should not inherit errexit over best-effort cleanup")
    (helpers.assertTest "findutils-runtime-input" (lib.hasInfix "findutils" module)
      "the packaged CLI should include findutils for home worktree discovery"
    )
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
