# Powerlevel10k Prompt Test
#
# Instant prompt only helps when its block runs before compinit, and a broken
# p10k config only shows up when a shell loads it. Both fail silently in a
# terminal, so check them here.
{
  pkgs,
  lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  mockConfig = import ../lib/mock-config.nix { inherit pkgs lib; };

  p10kModule = import ../../users/shared/programs/powerlevel10k.nix {
    inherit pkgs lib;
    config = mockConfig.mkEmptyConfig // {
      modules.programs.powerlevel10k.enable = true;
    };
  };
  initParts = p10kModule.config.content.programs.zsh.initContent.contents;
  instantPrompt = lib.findFirst (
    part: lib.hasInfix "p10k-instant-prompt" part.content
  ) null initParts;
  themeLoad = lib.findFirst (part: lib.hasInfix "powerlevel10k.zsh-theme" part.content) null initParts;

  # Home Manager's compinit order (programs/zsh: mkOrder 570).
  compinitOrder = 570;

  # Load the theme and config in a real interactive zsh. Rendering the prompt
  # needs a TTY and gitstatusd, so check that the config overrides applied.
  runtimeSmoke =
    pkgs.runCommand "test-powerlevel10k-runtime"
      {
        nativeBuildInputs = [
          pkgs.zsh
          pkgs.git
        ];
      }
      ''
        export HOME=$TMPDIR/home TERM=xterm-256color
        mkdir -p $HOME
        cat > $HOME/.zshrc <<'EOF'
        ${themeLoad.content}
        EOF
        prompt=$(zsh -i -c '(( $+functions[p10k] )) && print -r -- "$POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_CONTENT_EXPANSION"' 2>$TMPDIR/err)
        if [[ -s $TMPDIR/err ]]; then
          cat $TMPDIR/err >&2
          exit 1
        fi
        case "$prompt" in
          *➜*) ;;
          *)
            echo "p10k did not load or its config did not apply: $prompt" >&2
            exit 1
            ;;
        esac
        touch $out
      '';
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "powerlevel10k" [
    (helpers.assertTest "instant-prompt-before-compinit" (
      instantPrompt != null && instantPrompt.priority < compinitOrder
    ) "p10k instant prompt must load before compinit, or the first prompt waits for all of .zshrc")
    (helpers.assertTest "theme-loaded" (themeLoad != null) "powerlevel10k theme should be sourced")
    runtimeSmoke
  ];
}
