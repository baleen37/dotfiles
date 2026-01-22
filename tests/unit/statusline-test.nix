# tests/unit/statusline-test.nix
# Statusline context extraction logic tests
# Tests cross-model compatibility for glm-4.7 and Claude models
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  self ? ./.,
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Path to statusline script
  statuslineScript = ../../users/shared/.config/claude/statusline.sh;

  # Helper to run statusline script with JSON input
  runStatusline = inputData: pkgs.runCommand "statusline-test" { buildInputs = [ pkgs.jq ]; } ''
    echo '${inputData}' | bash ${statuslineScript} > $out 2>&1 || true
    cat $out
  '';

  # Helper to extract context value from statusline output
  extractCtxValue = output:
    let
      match = builtins.match ".*Ctx: ([0-9.]+[kK]?).*" output;
    in
    if match == null then null else builtins.head match;

  # Helper to check if output contains expected context
  hasCtxValue = output: expected: (extractCtxValue output) == expected;

  # Test data for different model formats
  testData = {
    # glm-4.7 format: no current_usage, uses total_input_tokens
    glm-4-7-basic = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = { display_name = "glm-4.7"; };
        workspace = { current_dir = "/Users/test/dotfiles"; };
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
        model = { display_name = "glm-4.7"; };
        workspace = { current_dir = "/Users/test/dotfiles"; };
      };
      expectedCtx = "0";
      description = "glm-4.7 with no context_window field";
    };

    # Claude model (Sonnet 4.5): uses current_usage
    sonnet-4-5-current-usage = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = { display_name = "Sonnet 4.5"; };
        workspace = { current_dir = "/Users/test/dotfiles"; };
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
        model = { display_name = "Sonnet 4.5"; };
        workspace = { current_dir = "/Users/test/dotfiles"; };
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
        model = { display_name = "Unknown Model"; };
        workspace = { current_dir = "/Users/test/dotfiles"; };
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
        model = { display_name = "Sonnet 4.5"; };
        workspace = { current_dir = "/Users/test/dotfiles"; };
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
        model = { display_name = "Sonnet 4.5"; };
        workspace = { current_dir = "/Users/test/dotfiles"; };
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
        model = { display_name = "Some Model"; };
        workspace = { current_dir = "/Users/test/dotfiles"; };
        context_window = {
          current_usage = { };
          total_input_tokens = 100;
        };
      };
      expectedCtx = "100";
      description = "Empty current_usage object falls back to total_input_tokens";
    };
  };

  # Create individual test for each data point
  createTest = testName: data:
    helpers.assertTest testName
      (
        let
          # Run statusline with test input
          result = builtins.tryEval (
            builtins.substring 0 500 (
              builtins.readFile (
                runStatusline data.input
              )
            )
          );
        in
        # Check if output contains expected context value
        result.success &&
        builtins.isString result.value &&
        builtins.match ".*Ctx:[[:space:]]*${lib.escapeRegex data.expectedCtx}.*" result.value != null
      )
      "${data.description}: expected 'Ctx: ${data.expectedCtx}'";

in
{
  platforms = [ "any" ];
  value = helpers.testSuite "statusline-context-extraction-tests" (
    builtins.attrValues (builtins.mapAttrs createTest testData)
  );
}
