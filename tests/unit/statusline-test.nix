# tests/unit/statusline-test.nix
# Statusline context extraction logic tests
# Tests cross-model compatibility for glm-4.7 and Claude models
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

  # Test data for different model formats
  testData = {
    # glm-4.7 format: no current_usage, uses total_input_tokens
    glm-4-7-basic = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "glm-4.7";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        context_window = {
          total_input_tokens = 1000;
          total_output_tokens = 100;
        };
      };
      expectedCtx = "1.0k";
      description = "glm-4.7 basic format with total_input_tokens";
    };

    # glm-4.7 format: no context_window at all (edge case)
    glm-4-7-no-context = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "glm-4.7";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
      };
      expectedCtx = "0";
      description = "glm-4.7 with no context_window field";
    };

    # Claude model (Sonnet 4.5): uses current_usage
    sonnet-4-5-current-usage = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        context_window = {
          current_usage = {
            input_tokens = 1000;
            output_tokens = 200;
            cache_read_input_tokens = 400;
            cache_creation_input_tokens = 200;
          };
        };
      };
      expectedCtx = "1.6k";
      description = "Sonnet 4.5 with current_usage (1000+400+200=1600)";
    };

    # Claude model: current_usage with only input_tokens
    sonnet-4-5-no-cache = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        context_window = {
          current_usage = {
            input_tokens = 500;
            output_tokens = 100;
          };
        };
      };
      expectedCtx = "500";
      description = "Sonnet 4.5 with current_usage but no cache tokens";
    };

    # Fallback: current_usage is null, should use total_input_tokens
    fallback-to-total = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Unknown Model";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        context_window = {
          current_usage = null;
          total_input_tokens = 2500;
          total_output_tokens = 250;
        };
      };
      expectedCtx = "2.5k";
      description = "Fallback when current_usage is null";
    };

    # Large numbers: should format with k
    large-tokens = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        context_window = {
          total_input_tokens = 18600;
        };
      };
      expectedCtx = "18.6k";
      description = "Large token count formatting (18.6k)";
    };

    # Very large numbers
    very-large-tokens = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        context_window = {
          total_input_tokens = 128000;
        };
      };
      expectedCtx = "128.0k";
      description = "Very large token count (128k)";
    };

    # Edge case: empty current_usage object
    empty-current-usage = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Some Model";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        context_window = {
          current_usage = { };
          total_input_tokens = 100;
        };
      };
      expectedCtx = "100";
      description = "Empty current_usage object falls back to total_input_tokens";
    };

    # glm-4.7: zero-filled current_usage (all fields are 0, but object exists)
    glm-4-7-zero-current-usage = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "glm-4.7";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        context_window = {
          current_usage = {
            input_tokens = 0;
            cache_read_input_tokens = 0;
            cache_creation_input_tokens = 0;
          };
          total_input_tokens = 5000;
        };
      };
      expectedCtx = "5.0k";
      description = "glm-4.7 with zero-filled current_usage falls back to total_input_tokens";
    };

    # Bug: Very large context values (1M+ tokens) should display with M suffix
    # This test reproduces the reported bug and verifies M suffix formatting
    large-context-1m-tokens = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        context_window = {
          total_input_tokens = 1560000;
        };
      };
      expectedCtx = "1.6M";
      description = "Large context (1.56M tokens) should display with M suffix";
    };

    # Additional large value test
    large-context-2m-tokens = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        context_window = {
          total_input_tokens = 2500000;
        };
      };
      expectedCtx = "2.5M";
      description = "Large context (2.5M tokens) should display with M suffix";
    };

    # Edge case: exactly 1M tokens
    exact-1m-tokens = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        context_window = {
          total_input_tokens = 1000000;
        };
      };
      expectedCtx = "1.0M";
      description = "Exactly 1M tokens should display as 1.0M";
    };

    # NEW: used_percentage fallback - basic case
    used-percentage-fallback = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        context_window = {
          used_percentage = 25.5;
          context_window_size = 200000;
        };
      };
      expectedCtx = "51.0k";
      description = "used_percentage fallback: 25.5% of 200k = 51k tokens";
    };

    # NEW: used_percentage fallback - large value with M suffix
    used-percentage-large = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        context_window = {
          used_percentage = 80;
          context_window_size = 2000000;
        };
      };
      expectedCtx = "1.6M";
      description = "used_percentage fallback: 80% of 2M = 1.6M tokens";
    };

    # NEW: used_percentage fallback - edge case null values
    used-percentage-null = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        context_window = {
          used_percentage = null;
          context_window_size = null;
        };
      };
      expectedCtx = "0";
      description = "used_percentage fallback: null values should default to 0";
    };

    # NEW: used_percentage fallback - edge case 0 values
    used-percentage-zero = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        context_window = {
          used_percentage = 0;
          context_window_size = 0;
        };
      };
      expectedCtx = "0";
      description = "used_percentage fallback: 0 values should result in 0";
    };

    # NEW: used_percentage fallback - full chain test
    # When both current_usage and total_input_tokens are unavailable,
    # used_percentage should be used as final fallback
    used-percentage-full-chain = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Unknown Model";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        context_window = {
          current_usage = null;
          total_input_tokens = null;
          used_percentage = 50;
          context_window_size = 100000;
        };
      };
      expectedCtx = "50.0k";
      description = "Full fallback chain: null current_usage → null total_input_tokens → used_percentage";
    };
  };

  # Create individual test for each data point
  createTest =
    testName: data:
    pkgs.runCommand "statusline-test-${testName}" {
      nativeBuildInputs = [ pkgs.bash pkgs.jq ];
    } ''
      # Write statusline script to a temporary file
      script=$TMPDIR/statusline.sh
      cat > $script <<'SCRIPT_END'
      ${statuslineScriptContent}
      SCRIPT_END
      chmod +x $script

      # Run statusline with test input
      output=$(echo '${data.input}' | bash $script 2>&1 || true)

      # Check if output contains expected context value
      if echo "$output" | grep -q "Ctx:[[:space:]]*${lib.escapeRegex data.expectedCtx}"; then
        echo "✅ ${testName}: PASS"
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
    '';

in
{
  platforms = [ "any" ];
  value = helpers.testSuite "statusline-context-extraction-tests" (
    builtins.attrValues (builtins.mapAttrs createTest testData)
  );
}
