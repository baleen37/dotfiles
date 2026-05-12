# Zsh multi-dot cd function tests
#
# Verifies that the cd function override is wired into zsh initContent
# so that `cd ...` becomes `cd ../..`, `cd ....` becomes `cd ../../..`, etc.
# The override preserves the typed form in shell history (unlike a ZLE
# widget that rewrites $LBUFFER inline).
#
# Also runs the function under a real zsh to confirm expansion output.
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  nixtest ? { },
  self ? ./.,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  mockConfig = import ../lib/mock-config.nix { inherit pkgs lib; };

  zshConfig = import ../../users/shared/zsh {
    inherit pkgs lib;
    isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
    config = mockConfig.mkEmptyConfig;
  };

  initContent = zshConfig.programs.zsh.initContent.content or "";
  aliases = zshConfig.programs.zsh.shellAliases or { };

  assertInitHas =
    name: needle:
    helpers.assertTest "zsh-multidot-${name}" (lib.hasInfix needle initContent)
      "Expected '${needle}' in zsh initContent";

  # Runtime check: source the cd override under zsh and verify that calling
  # `cd ...` etc. resolves to the right physical directory. We use $PWD as
  # the observable since `builtin cd` mutates it.
  runtimeTest =
    pkgs.runCommand "zsh-multidot-cd-runtime"
      {
        nativeBuildInputs = [ pkgs.zsh pkgs.coreutils ];
      }
      ''
        mkdir -p a/b/c/d/e
        root=$PWD

        cat > fn.zsh <<'EOF'
        cd() {
          if [[ $# -eq 1 && "$1" =~ "^\.{3,}$" ]]; then
            local dots="$1"
            local target=""
            local i
            for (( i = 1; i < ''${#dots}; i++ )); do
              target+="../"
            done
            builtin cd "$target"
          else
            builtin cd "$@"
          fi
        }
        EOF

        run() {
          # $1 = starting subdir, $2 = cd argument; prints resulting $PWD
          zsh -c "
            source $root/fn.zsh
            builtin cd $root/$1
            cd '$2'
            print -r -- \"\$PWD\"
          "
        }

        got=$(run "a/b/c/d/e" "...")
        [[ "$got" = "$root/a/b/c" ]] || { echo "FAIL cd ...: got '$got'"; exit 1; }

        got=$(run "a/b/c/d/e" "....")
        [[ "$got" = "$root/a/b" ]] || { echo "FAIL cd ....: got '$got'"; exit 1; }

        got=$(run "a/b/c/d/e" ".....")
        [[ "$got" = "$root/a" ]] || { echo "FAIL cd .....: got '$got'"; exit 1; }

        got=$(run "a/b/c" "..")
        [[ "$got" = "$root/a/b" ]] || { echo "FAIL cd ..: got '$got'"; exit 1; }

        got=$(run "a/b" "c")
        [[ "$got" = "$root/a/b/c" ]] || { echo "FAIL cd c: got '$got'"; exit 1; }

        # Regression: arbitrary paths must NOT be treated as multi-dot.
        # Previously, an unquoted `=~ ^\.\.\.+$` regex mis-matched paths
        # like "/tmp" or "abc", causing them to be rewritten as `../../../`.
        mkdir -p tmp_target abc_target
        got=$(run "a/b/c/d/e" "$root/tmp_target")
        [[ "$got" = "$root/tmp_target" ]] || { echo "FAIL cd /abs path: got '$got'"; exit 1; }

        got=$(run "a/b/c" "../d_sibling" 2>/dev/null || true)
        # Just ensure that a non-dot relative arg is passed through as-is
        # (mkdir the target first so cd succeeds).
        mkdir -p a/b/d_sibling
        got=$(run "a/b/c" "../d_sibling")
        [[ "$got" = "$root/a/b/d_sibling" ]] || { echo "FAIL cd ../sibling: got '$got'"; exit 1; }

        echo "runtime cd override behavior OK"
        touch $out
      '';

in
{
  platforms = [ "any" ];
  value = helpers.testSuite "zsh-multidot-cd" [
    (assertInitHas "fn-defined" "cd() {")
    (assertInitHas "regex-check" ''"$1" =~ "^\.{3,}$"'')
    (assertInitHas "builtin-cd" "builtin cd")

    (helpers.assertTest "zsh-multidot-no-triple-alias"
      (!(builtins.hasAttr "..." aliases))
      "shellAliases should not define '...' — the cd function handles it"
    )
    (helpers.assertTest "zsh-multidot-no-quad-alias"
      (!(builtins.hasAttr "...." aliases))
      "shellAliases should not define '....' — the cd function handles it"
    )

    (helpers.assertTest "zsh-multidot-runtime"
      (builtins.pathExists runtimeTest)
      "cd function runtime simulation failed"
    )
  ];
}
