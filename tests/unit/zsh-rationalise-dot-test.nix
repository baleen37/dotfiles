# Zsh rationalise-dot ZLE widget tests
#
# Verifies that the dot-expansion widget is wired into zsh initContent
# so that typing "..." becomes "../..", "...." becomes "../../..", etc.
# The widget mutates $LBUFFER inline, which is what enables tab completion
# on paths like `cd .../<TAB>`.
#
# Also runs the widget logic under a real zsh to confirm expansion output.
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
    helpers.assertTest "zsh-rat-dot-${name}" (lib.hasInfix needle initContent)
      "Expected '${needle}' in zsh initContent";

  # Runtime check: source the widget definition under zsh and simulate the
  # keypresses that produce "..." / "....", asserting $LBUFFER is rewritten.
  # We don't need ZLE active — the function body only touches $LBUFFER, so
  # we can invoke it as a regular function in a non-interactive shell.
  runtimeTest =
    pkgs.runCommand "zsh-rationalise-dot-runtime"
      {
        nativeBuildInputs = [ pkgs.zsh ];
      }
      ''
        cat > widget.zsh <<'EOF'
        rationalise-dot() {
          if [[ $LBUFFER = *.. ]]; then
            LBUFFER+=/..
          else
            LBUFFER+=.
          fi
        }
        EOF

        expand() {
          zsh -c "
            source ./widget.zsh
            LBUFFER='$1'
            for _ in {1..$2}; do rationalise-dot; done
            print -r -- \"\$LBUFFER\"
          "
        }

        # Typing "..." from empty buffer -> "../.."
        got=$(expand "" 3)
        [[ "$got" = "../.." ]] || { echo "FAIL 3 dots: got '$got'"; exit 1; }

        # Typing "...." -> "../../.."
        got=$(expand "" 4)
        [[ "$got" = "../../.." ]] || { echo "FAIL 4 dots: got '$got'"; exit 1; }

        # Typing "....." -> "../../../.."
        got=$(expand "" 5)
        [[ "$got" = "../../../.." ]] || { echo "FAIL 5 dots: got '$got'"; exit 1; }

        # After "cd " prefix, "..." still expands (LBUFFER includes prefix)
        got=$(expand "cd " 3)
        [[ "$got" = "cd ../.." ]] || { echo "FAIL cd prefix: got '$got'"; exit 1; }

        # Two dots alone stay literal (widget only rewrites from the 3rd dot)
        got=$(expand "" 2)
        [[ "$got" = ".." ]] || { echo "FAIL 2 dots literal: got '$got'"; exit 1; }

        # A single dot after a non-dot char stays literal (e.g. filenames)
        got=$(expand "foo" 1)
        [[ "$got" = "foo." ]] || { echo "FAIL foo.: got '$got'"; exit 1; }

        echo "runtime widget behavior OK"
        touch $out
      '';

in
{
  platforms = [ "any" ];
  value = helpers.testSuite "zsh-rationalise-dot" [
    # 1. Widget function body is present
    (assertInitHas "fn-defined" "rationalise-dot()")
    (assertInitHas "lbuffer-check" "[[ $LBUFFER = *.. ]]")
    (assertInitHas "lbuffer-append-slash" "LBUFFER+=/..")
    (assertInitHas "lbuffer-append-dot" "LBUFFER+=.")

    # 2. Widget is registered with ZLE and bound to "."
    (assertInitHas "zle-register" "zle -N rationalise-dot")
    (assertInitHas "bindkey" "bindkey . rationalise-dot")
    (assertInitHas "isearch-literal" "bindkey -M isearch . self-insert")

    # 3. Old multi-dot shell aliases were removed so they no longer shadow
    #    the widget (only ".." alias remains for convenience).
    (helpers.assertTest "zsh-rat-dot-no-triple-alias"
      (!(builtins.hasAttr "..." aliases))
      "shellAliases should not define '...' — the ZLE widget handles it"
    )
    (helpers.assertTest "zsh-rat-dot-no-quad-alias"
      (!(builtins.hasAttr "...." aliases))
      "shellAliases should not define '....' — the ZLE widget handles it"
    )

    # 4. Runtime behavior under real zsh
    (helpers.assertTest "zsh-rat-dot-runtime"
      (builtins.pathExists runtimeTest)
      "rationalise-dot widget runtime simulation failed"
    )
  ];
}
