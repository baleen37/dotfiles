# tests/unit/statusline-test.nix
# Statusline context extraction logic tests
# Tests transcript-based context calculation without fallback
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
  createTranscript = messages:
    builtins.concatStringsSep "\n" (map (msg: builtins.toJSON msg) messages);

  # Test data for transcript-based context calculation (no fallback)
  testData = {
    # No transcript path - no context display
    no-transcript-path = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
      };
      transcript = null;
      expectNoContext = true;
      description = "No transcript_path - no context displayed";
    };

    # Transcript file not found - no context display
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
      };
      transcript = null;
      expectNoContext = true;
      description = "Transcript file not found - no context displayed";
    };

    # Empty transcript file - no context display
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
      };
      createEmptyTranscript = true;
      expectNoContext = true;
      description = "Empty transcript file - no context displayed";
    };

    # Single message - context from last message
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
      description = "Single message - context from last (15000+3000+2000=20k)";
    };

    # Multiple messages - context from last
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
      };
      transcript = createTranscript [
        {
          message = {
            usage = {
              input_tokens = 15000;
              cache_read_input_tokens = 3000;
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
            };
          };
          isSidechain = false;
          isApiErrorMessage = false;
        }
      ];
      expectedCtx = "80k";
      description = "Multiple messages - context from last (70000+10000=80k)";
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
        transcript_path = "/tmp/test-transcript.jsonl";
      };
      transcript = createTranscript [
        {
          message = {
            usage = {
              input_tokens = 180000;
              cache_read_input_tokens = 5000;
            };
          };
          isSidechain = false;
          isApiErrorMessage = false;
        }
      ];
      expectedCtx = "185k";
      description = "Large context (180000+5000=185k)";
    };

    # Sidechain messages filtered
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
      };
      transcript = createTranscript [
        {
          message = {
            usage = {
              input_tokens = 50000;
            };
          };
          isSidechain = false;
          isApiErrorMessage = false;
        }
        {
          # Sidechain - should be ignored
          message = {
            usage = {
              input_tokens = 100000;
            };
          };
          isSidechain = true;
          isApiErrorMessage = false;
        }
      ];
      expectedCtx = "50k";
      description = "Sidechain filtered - uses non-sidechain (50k)";
    };

    # Error messages filtered
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
      };
      transcript = createTranscript [
        {
          message = {
            usage = {
              input_tokens = 30000;
            };
          };
          isSidechain = false;
          isApiErrorMessage = false;
        }
        {
          # Error - should be ignored
          message = {
            usage = {
              input_tokens = 100000;
            };
          };
          isSidechain = false;
          isApiErrorMessage = true;
        }
      ];
      expectedCtx = "30k";
      description = "Error filtered - uses non-error (30k)";
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
        transcript_path = "/tmp/test-transcript.jsonl";
      };
      transcript = createTranscript [
        {
          message = {
            usage = {
              input_tokens = 500;
            };
          };
          isSidechain = false;
          isApiErrorMessage = false;
        }
      ];
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
        transcript_path = "/tmp/test-transcript.jsonl";
      };
      transcript = createTranscript [
        {
          message = {
            usage = {
              input_tokens = 30000;
            };
          };
          isSidechain = false;
          isApiErrorMessage = false;
        }
      ];
      expectedCtx = "30k";
      description = "Partial usage (only input_tokens) - 30k";
    };

    # No valid messages - no context
    no-valid-messages = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        transcript_path = "/tmp/test-transcript.jsonl";
      };
      transcript = createTranscript [
        {
          # No usage field
          message = { };
          isSidechain = false;
          isApiErrorMessage = false;
        }
      ];
      expectNoContext = true;
      description = "No valid messages with usage - no context";
    };

    # All sidechain - no context
    all-sidechain = {
      input = builtins.toJSON {
        hook_event_name = "Status";
        model = {
          display_name = "Sonnet 4.5";
        };
        workspace = {
          current_dir = "/Users/test/dotfiles";
        };
        transcript_path = "/tmp/test-transcript.jsonl";
      };
      transcript = createTranscript [
        {
          message = {
            usage = {
              input_tokens = 50000;
            };
          };
          isSidechain = true;
          isApiErrorMessage = false;
        }
      ];
      expectNoContext = true;
      description = "All sidechain messages - no context";
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

      transcript_file=$TMPDIR/test-transcript.jsonl

      ${lib.optionalString (data ? transcript && data.transcript != null && data.transcript != "") ''
        cat > $transcript_file <<'TRANSCRIPT_END'
        ${data.transcript}
        TRANSCRIPT_END
      ''}

      ${lib.optionalString (data.createEmptyTranscript or false) ''
        touch $transcript_file
      ''}

      if [[ -f $transcript_file ]]; then
        input_json=$(echo '${data.input}' | jq --arg path "$transcript_file" '.transcript_path = $path')
      else
        input_json='${data.input}'
      fi

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
