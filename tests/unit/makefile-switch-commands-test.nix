# tests/unit/makefile-switch-commands-test.nix
#
# The Darwin `switch` recipe is coupled to two things outside the Makefile:
#
#   - the sudoers rule in users/shared/darwin (see darwin-sudo-test.nix), which
#     allowlists one exact command line. Any drift here turns a passwordless
#     switch into a password prompt, or worse, widens the rule.
#   - the experimental-features flags on $(NIX); without them every nix
#     invocation fails with "experimental Nix feature 'nix-command' is disabled".
#
# Both are string-level contracts, so they are checked as strings.
{
  pkgs ? import <nixpkgs> { },
  ...
}:

pkgs.runCommand "makefile-switch-commands-test"
  {
    buildInputs = [
      pkgs.gnugrep
      pkgs.gnused
    ];
    makefileSource = ../../Makefile;
  }
  ''
    fail() {
      echo "❌ $1"
      exit 1
    }

    darwinSwitch=$(sed -n '/^switch:/,/^else/p' "$makefileSource")

    # $(NIX) must carry the experimental feature flags.
    grep '^NIX :=' "$makefileSource" | grep -q 'experimental-features.*nix-command' \
      || fail "NIX must be defined with --extra-experimental-features nix-command"
    grep '^NIX :=' "$makefileSource" | grep -q 'experimental-features.*flakes' \
      || fail "NIX must be defined with --extra-experimental-features flakes"

    # Darwin switches through nix-darwin, never home-manager.
    if echo "$darwinSwitch" | grep -q 'home-manager'; then
      fail "the Darwin branch of switch must use darwin-rebuild, not home-manager"
    fi

    # The invocation has to match the sudoers allowlist byte for byte. Strip the
    # recipe tab and match the whole line: a substring match would also accept an
    # extra argument, which falls outside the rule and starts prompting for a
    # password.
    grep -q '^DARWIN_REBUILD := /run/current-system/sw/bin/darwin-rebuild$' "$makefileSource" \
      || fail "DARWIN_REBUILD must be the absolute allowlisted darwin-rebuild path"
    echo "$darwinSwitch" | sed 's/^\t*//' \
      | grep -qxF 'sudo -H $(DARWIN_REBUILD) switch --flake ".#$(NIXNAME)"' \
      || fail "Darwin switch must invoke exactly the command the sudoers rule allows"

    # Expiring generations after the switch is what lets GC free old closures;
    # the line also has to match the nh sudoers rule byte for byte.
    grep -q '^NH := /run/current-system/sw/bin/nh$' "$makefileSource" \
      || fail "NH must be the absolute allowlisted nh path"
    echo "$darwinSwitch" | sed 's/^\t*//' \
      | grep -qxF 'sudo -H $(NH) clean all --keep 3' \
      || fail "Darwin switch must run exactly the nh clean the sudoers rule allows"

    # Allowlisting /usr/bin/env would let any command through sudo.
    if echo "$darwinSwitch" | grep -q 'sudo -H env'; then
      fail "Darwin switch must not sudo /usr/bin/env"
    fi

    # build-switch is only an alias; it must not grow its own recipe.
    grep -q '^build-switch: switch$' "$makefileSource" \
      || fail "build-switch should stay an alias for switch"

    grep '^\.PHONY:' "$makefileSource" | grep -q 'switch' \
      || fail "switch must be declared .PHONY"

    grep -q '^HM_USER ?= \$(shell id -un 2>/dev/null || whoami)$' "$makefileSource" \
      || fail "HM_USER must default to the current user"

    switchHome=$(sed -n '/^switch-home:/,/^test:/p' "$makefileSource")
    echo "$switchHome" | grep -q '\.#\$(HM_USER)' \
      || fail "switch-home must select Home Manager profiles with HM_USER"

    grep -q '^# This target does not install Homebrew casks; full `make switch` owns that path\.$' "$makefileSource" \
      || fail "switch-home must document that Homebrew is handled only by make switch"
    if echo "$switchHome" | grep -Eiq '(^|[[:space:]])brew([[:space:]]|$)|darwin-rebuild'; then
      fail "switch-home must not install Homebrew or run Darwin system activation"
    fi

    if echo "$darwinSwitch" | grep -q 'audit-darwin-vscode'; then
      fail "make switch must not run a separate VS Code audit target"
    fi
    if echo "$switchHome" | grep -q 'audit-darwin-vscode'; then
      fail "switch-home must not run a separate VS Code audit target"
    fi
    if grep -q '^audit-darwin-vscode:' "$makefileSource"; then
      fail "Makefile must not define a separate VS Code audit target"
    fi

    if grep -q -- '--impure' "$makefileSource"; then
      fail "Makefile must evaluate flakes purely"
    fi

    # NIXPKGS_ALLOW_* is only read under --impure, so setting it is dead weight
    # that suggests unfree packages are enabled here rather than in nixpkgs.config.
    if grep -q 'NIXPKGS_ALLOW_' "$makefileSource"; then
      fail "Makefile must not set NIXPKGS_ALLOW_* (ignored without --impure)"
    fi

    # `nix run` on a bare flake reference resolves the registry or the branch tip,
    # not flake.lock: home-manager and nixos-rebuild would silently drift from
    # the versions the configuration was built and tested against.
    if grep -q 'github:nix-community/home-manager' "$makefileSource"; then
      fail "Makefile must run home-manager from flake.lock, not github:nix-community/home-manager"
    fi
    unpinned=$(grep -E '[[:space:]]run[[:space:]].*(nixpkgs#|home-manager)' "$makefileSource" \
      | grep -v -- '--inputs-from' || true)
    if [ -n "$unpinned" ]; then
      echo "$unpinned"
      fail "every nix run of nixpkgs#/home-manager must pass --inputs-from to use flake.lock"
    fi

    echo "✅ Makefile switch contracts hold"
    touch $out
  ''
