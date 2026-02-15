# tests/unit/statusline-test.nix
# Statusline context extraction logic tests
# Tests JSON input context_window.current_usage based calculation
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

  # Read statusline script content as text (not a derivation)
  statuslineScriptContent = builtins.readFile ../../users/shared/.config/claude/statusline.sh;

  # Test data for JSON input context calculation
  testData = {
    # No context_window - no context display
    no-context-window = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
      };
      expectNoContext = true;
      description = "No context_window - no context displayed";
    };

    # No current_usage - no context display
    no-current-usage = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        context_window = {
          context_window_size = 200000;
        };
      };
      expectNoContext = true;
      description = "No current_usage - no context displayed";
    };

    # Full usage - all token types
    full-usage = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        context_window = {
          context_window_size = 200000;
          current_usage = {
            input_tokens = 15000;
            cache_read_input_tokens = 3000;
            cache_creation_input_tokens = 2000;
          };
        };
      };
      expectedCtx = "20k";
      description = "Full usage (15000+3000+2000=20k)";
    };

    # Large context
    large-context = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        context_window = {
          context_window_size = 200000;
          current_usage = {
            input_tokens = 180000;
            cache_read_input_tokens = 5000;
            cache_creation_input_tokens = 0;
          };
        };
      };
      expectedCtx = "185k";
      description = "Large context (180000+5000=185k)";
    };

    # Small context - no k suffix
    small-context = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        context_window = {
          context_window_size = 200000;
          current_usage = {
            input_tokens = 500;
            cache_read_input_tokens = 0;
            cache_creation_input_tokens = 0;
          };
        };
      };
      expectedCtx = "500";
      description = "Small context (500) - no k suffix";
    };

    # Partial usage - only input_tokens
    partial-usage = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        context_window = {
          context_window_size = 200000;
          current_usage = {
            input_tokens = 30000;
          };
        };
      };
      expectedCtx = "30k";
      description = "Partial usage (only input_tokens) - 30k";
    };

    # Zero tokens - no context
    zero-tokens = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        context_window = {
          context_window_size = 200000;
          current_usage = {
            input_tokens = 0;
            cache_read_input_tokens = 0;
            cache_creation_input_tokens = 0;
          };
        };
      };
      expectNoContext = true;
      description = "Zero tokens - no context";
    };
  };

  # Create individual test
  createTest =
    testName: data:
    pkgs.runCommand "statusline-test-${testName}" {
      nativeBuildInputs = [ pkgs.bash pkgs.jq ];
    } ''
      script=$TMPDIR/statusline.sh
      cat > $script <<'SCRIPT_END'
      ${statuslineScriptContent}
      SCRIPT_END
      chmod +x $script

      input_json='${data.input}'

      output=$(echo "$input_json" | bash $script 2>&1 || true)

      ${if data.expectNoContext or false then ''
        # Should NOT contain context (no number followed by k or space)
        if echo "$output" | grep -qE '[0-9]+k'; then
          echo "❌ ${testName}: FAIL"
          echo "  ${data.description}"
          echo "  Expected: no context"
          echo "  Got output:"
          echo "$output" | head -20
          exit 1
        else
          echo "✅ ${testName}: PASS"
          echo "  ${data.description}"
          touch $out
        fi
      '' else ''
        if echo "$output" | grep -qF '${data.expectedCtx}'; then
          echo "✅ ${testName}: PASS"
          echo "  ${data.description}"
          echo "  Expected Ctx: ${data.expectedCtx}"
          touch $out
        else
          echo "❌ ${testName}: FAIL"
          echo "  ${data.description}"
          echo "  Expected Ctx: ${data.expectedCtx}"
          echo "  Got output:"
          echo "$output" | head -20
          exit 1
        fi
      ''}
    '';

in
{
  platforms = [ "any" ];
  value = helpers.testSuite "statusline-context-extraction-tests" (
    builtins.attrValues (builtins.mapAttrs createTest testData)
  );
}
