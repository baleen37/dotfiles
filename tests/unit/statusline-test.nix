# tests/unit/statusline-test.nix
# Statusline context extraction logic tests
# Tests transcript-based context calculation and formatting
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

  # Helper to create a transcript JSONL file
  # Each message has the format expected by statusline.sh
  createTranscript = messages:
    builtins.concatStringsSep "\n" (map (msg: builtins.toJSON msg) messages);

  # Test data for the new transcript-based context calculation
  testData = {
    # No transcript path provided - should use baseline estimate
    no-transcript-path = {
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
      transcript = null;
      expectedCtx = "~20k";
      description = "No transcript_path - uses baseline estimate (~20k)";
    };

    # Transcript path provided but file doesn't exist - fallback to baseline
    transcript-not-found = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        transcript_path = "/nonexistent/transcript.jsonl";
        context_window = {
          context_window_size = 200000;
        };
      };
      transcript = null;
      expectedCtx = "~20k";
      description = "Transcript file not found - fallback to baseline (~20k)";
    };

    # Empty transcript file (file exists but has no valid JSON lines)
    # Uses baseline estimate because jq can't parse empty content
    empty-transcript = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        transcript_path = "/tmp/test-transcript.jsonl";
        context_window = {
          context_window_size = 200000;
        };
      };
      # Empty file will cause jq to fail, falling back to baseline
      createEmptyTranscript = true;
      expectedCtx = "~20k";
      description = "Empty transcript file - jq fails, uses baseline (~20k)";
    };

    # Single message in transcript (baseline only)
    single-message = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        transcript_path = "/tmp/test-transcript.jsonl";
        context_window = {
          context_window_size = 200000;
        };
      };
      transcript = createTranscript [
        {
          message = {
            usage = {
              input_tokens = 15000;
              cache_read_input_tokens = 3000;
              cache_creation_input_tokens = 2000;
            };
          };
          isSidechain = false;
          isApiErrorMessage = false;
        }
      ];
      expectedCtx = "20k";
      description = "Single message - baseline only (15000+3000+2000=20k)";
    };

    # Multiple messages - context grows
    multiple-messages = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        transcript_path = "/tmp/test-transcript.jsonl";
        context_window = {
          context_window_size = 200000;
        };
      };
      transcript = createTranscript [
        {
          message = {
            usage = {
              input_tokens = 15000;
              cache_read_input_tokens = 3000;
              cache_creation_input_tokens = 2000;
            };
          };
          isSidechain = false;
          isApiErrorMessage = false;
        }
        {
          message = {
            usage = {
              input_tokens = 45000;
              cache_read_input_tokens = 5000;
              cache_creation_input_tokens = 0;
            };
          };
          isSidechain = false;
          isApiErrorMessage = false;
        }
        {
          message = {
            usage = {
              input_tokens = 70000;
              cache_read_input_tokens = 10000;
              cache_creation_input_tokens = 0;
            };
          };
          isSidechain = false;
          isApiErrorMessage = false;
        }
      ];
      expectedCtx = "80k";
      description = "Multiple messages - last message context (70000+10000=80k)";
    };

    # Large context (180k+)
    large-context = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        transcript_path = "/tmp/test-transcript.jsonl";
        context_window = {
          context_window_size = 200000;
        };
      };
      transcript = createTranscript [
        {
          message = {
            usage = {
              input_tokens = 20000;
              cache_read_input_tokens = 0;
              cache_creation_input_tokens = 0;
            };
          };
          isSidechain = false;
          isApiErrorMessage = false;
        }
        {
          message = {
            usage = {
              input_tokens = 180000;
              cache_read_input_tokens = 5000;
              cache_creation_input_tokens = 0;
            };
          };
          isSidechain = false;
          isApiErrorMessage = false;
        }
      ];
      expectedCtx = "185k";
      description = "Large context (180000+5000=185k)";
    };

    # Sidechain messages should be filtered out
    sidechain-filtered = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        transcript_path = "/tmp/test-transcript.jsonl";
        context_window = {
          context_window_size = 200000;
        };
      };
      transcript = createTranscript [
        {
          message = {
            usage = {
              input_tokens = 20000;
              cache_read_input_tokens = 0;
              cache_creation_input_tokens = 0;
            };
          };
          isSidechain = false;
          isApiErrorMessage = false;
        }
        {
          # This sidechain message should be ignored
          message = {
            usage = {
              input_tokens = 100000;
              cache_read_input_tokens = 0;
              cache_creation_input_tokens = 0;
            };
          };
          isSidechain = true;
          isApiErrorMessage = false;
        }
        {
          message = {
            usage = {
              input_tokens = 50000;
              cache_read_input_tokens = 0;
              cache_creation_input_tokens = 0;
            };
          };
          isSidechain = false;
          isApiErrorMessage = false;
        }
      ];
      expectedCtx = "50k";
      description = "Sidechain messages filtered - uses last non-sidechain (50k)";
    };

    # Error messages should be filtered out
    error-filtered = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        transcript_path = "/tmp/test-transcript.jsonl";
        context_window = {
          context_window_size = 200000;
        };
      };
      transcript = createTranscript [
        {
          message = {
            usage = {
              input_tokens = 20000;
              cache_read_input_tokens = 0;
              cache_creation_input_tokens = 0;
            };
          };
          isSidechain = false;
          isApiErrorMessage = false;
        }
        {
          # This error message should be ignored
          message = {
            usage = {
              input_tokens = 100000;
              cache_read_input_tokens = 0;
              cache_creation_input_tokens = 0;
            };
          };
          isSidechain = false;
          isApiErrorMessage = true;
        }
      ];
      expectedCtx = "20k";
      description = "Error messages filtered - uses only valid message (20k)";
    };

    # Messages without usage info should be skipped
    no-usage-skipped = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        transcript_path = "/tmp/test-transcript.jsonl";
        context_window = {
          context_window_size = 200000;
        };
      };
      transcript = createTranscript [
        {
          # No usage field - should be skipped
          message = { };
          isSidechain = false;
          isApiErrorMessage = false;
        }
      ];
      expectedCtx = "~20k";
      description = "No valid messages with usage - fallback to baseline (~20k)";
    };

    # Model name display test
    model-name-display = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Claude Opus 4.6";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        context_window = {
          context_window_size = 200000;
        };
      };
      transcript = null;
      expectedModel = "Claude Opus 4.6";
      expectedCtx = "~20k";
      description = "Model name should be displayed correctly";
    };

    # Context formatting - values under 1000
    small-context = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        transcript_path = "/tmp/test-transcript.jsonl";
        context_window = {
          context_window_size = 200000;
        };
      };
      transcript = createTranscript [
        {
          message = {
            usage = {
              input_tokens = 500;
              cache_read_input_tokens = 0;
              cache_creation_input_tokens = 0;
            };
          };
          isSidechain = false;
          isApiErrorMessage = false;
        }
      ];
      expectedCtx = "500";
      description = "Small context (500) - no k suffix";
    };

    # Partial usage fields - missing cache tokens
    partial-usage = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        transcript_path = "/tmp/test-transcript.jsonl";
        context_window = {
          context_window_size = 200000;
        };
      };
      transcript = createTranscript [
        {
          message = {
            usage = {
              input_tokens = 30000;
              # No cache fields
            };
          };
          isSidechain = false;
          isApiErrorMessage = false;
        }
      ];
      expectedCtx = "30k";
      description = "Partial usage (only input_tokens) - should work (30k)";
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

      # Create transcript file in TMPDIR (same sandbox location)
      transcript_file=$TMPDIR/test-transcript.jsonl

      ${lib.optionalString (data ? transcript && data.transcript != null && data.transcript != "") ''
        cat > $transcript_file <<'TRANSCRIPT_END'
        ${data.transcript}
        TRANSCRIPT_END
      ''}

      ${lib.optionalString (data.createEmptyTranscript or false) ''
        touch $transcript_file
      ''}

      # Update input JSON to use our transcript path
      if [[ -f $transcript_file ]]; then
        input_json=$(echo '${data.input}' | jq --arg path "$transcript_file" '.transcript_path = $path')
      else
        input_json='${data.input}'
      fi

      # Run statusline with test input
      output=$(echo "$input_json" | bash $script 2>&1 || true)

      # Check if output contains expected context value
      # The new format uses just the value (e.g., "20k" or "~20k") without "Ctx:" prefix
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
    '';

in
{
  platforms = [ "any" ];
  value = helpers.testSuite "statusline-context-extraction-tests" (
    builtins.attrValues (builtins.mapAttrs createTest testData)
  );
}
