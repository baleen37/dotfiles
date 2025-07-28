{ lib, pkgs }:

let
  # Import state management for integration
  stateLib = import ./auto-update-state.nix { inherit lib pkgs; };

  # ANSI color codes for terminal formatting
  colors = {
    reset = "\033[0m";
    bold = "\033[1m";
    green = "\033[32m";
    yellow = "\033[33m";
    blue = "\033[34m";
    cyan = "\033[36m";
    red = "\033[31m";
  };

  # Terminal UI symbols
  symbols = {
    update = "📦";
    arrow = "→";
    check = "✓";
    cross = "✗";
    clock = "⏰";
    eye = "👁";
  };

in {
  # Format the main prompt message with update information
  formatPromptMessage = { commit_hash, summary, changes_count, ... }:
    let
      header = "${colors.bold}${colors.cyan}${symbols.update} dotfiles 업데이트 사용 가능${colors.reset}";
      commitInfo = "커밋: ${colors.yellow}${commit_hash}${colors.reset}";
      summaryInfo = "요약: ${summary}";
      changesInfo = "변경사항: ${toString changes_count}개 파일";

      options = lib.concatStringsSep " " [
        "${colors.green}(y)es${colors.reset} - 지금 적용"
        "${colors.yellow}(l)ater${colors.reset} - 내일 다시 묻기"
        "${colors.red}(n)o${colors.reset} - 이 업데이트 건너뛰기"
        "${colors.blue}(s)how${colors.reset} - 변경사항 표시"
      ];

      prompt = "${colors.bold}선택하세요:${colors.reset}";

    in lib.concatStringsSep "\n" [
      ""
      header
      "  ${commitInfo}"
      "  ${summaryInfo}"
      "  ${changesInfo}"
      ""
      "  ${options}"
      ""
      "${prompt} "
    ];

  # Validate user input
  validateInput = input:
    let
      normalizedInput = lib.toLower (lib.trim input);
    in builtins.elem normalizedInput [ "y" "l" "n" "s" ];

  # Process user choice and update state accordingly
  processUserChoice = { choice, commit_hash, notification_file }:
    let
      normalizedChoice = lib.toLower (lib.trim choice);

      # Map user choices to state decisions
      decisionMap = {
        "y" = "apply";
        "l" = "later";
        "n" = "skip";
        "s" = "show"; # Special case - will show diff and re-prompt
      };

      decision = decisionMap.${normalizedChoice} or "later";

      # Calculate next prompt time for 'later' decision (24 hours from now)
      nextPromptTime = if decision == "later"
        then "$(date -d '+24 hours' -Iseconds)"
        else null;

    in pkgs.writeShellScript "process-user-choice" ''
      # Update state with user decision
      ${stateLib.updateState} \
        "${commit_hash}" \
        "${decision}" \
        ${if nextPromptTime != null then "\"${nextPromptTime}\"" else "null"}

      # Clean up notification file if decision is final (not 'show')
      if [ "${decision}" != "show" ]; then
        rm -f "${notification_file}"
        echo "알림 처리 완료: ${decision}"
      fi

      # Return the decision for caller
      echo "${decision}"
    '';

  # Main prompt function with timeout and signal handling
  promptUserWithTimeout = { commit_hash, summary, changes_count, notification_file, timeout ? 30 }:
    pkgs.writeShellScript "prompt-user-with-timeout" ''
      set -euo pipefail

      # Display the formatted prompt
      prompt_message=$(${pkgs.nix}/bin/nix eval --impure --expr '
        let prompt = import ${./auto-update-prompt.nix} { inherit (import <nixpkgs> {}) lib pkgs; };
        in prompt.formatPromptMessage {
          commit_hash = "${commit_hash}";
          summary = "${summary}";
          changes_count = ${toString changes_count};
        }
      ')

      echo -e "$prompt_message"

      # Set up signal handlers for graceful interruption
      trap 'echo "later"; exit 0' INT TERM

      # Function to read user input with timeout
      read_with_timeout() {
        local timeout_seconds="$1"
        local user_input=""

        # Use read with timeout
        if read -t "$timeout_seconds" -r user_input; then
          echo "$user_input"
          return 0
        else
          # Timeout occurred
          echo "later"
          return 1
        fi
      }

      # Main input loop with validation
      while true; do
        echo -n "> "
        user_input=$(read_with_timeout ${toString timeout})
        read_result=$?

        # If timeout or interrupt, return 'later'
        if [ $read_result -ne 0 ]; then
          echo
          echo "${colors.yellow}${symbols.clock} 시간 초과 - 나중에 다시 묻겠습니다${colors.reset}"
          echo "later"
          exit 0
        fi

        # Validate input
        if ${pkgs.nix}/bin/nix eval --impure --expr '
          let prompt = import ${./auto-update-prompt.nix} { inherit (import <nixpkgs> {}) lib pkgs; };
          in prompt.validateInput "'"$user_input"'"
        '; then
          # Process valid choice - call the function directly
          ${stateLib.updateState} "$commit_hash" "$(echo "$user_input" | tr 'A-Z' 'a-z')" "null"

          # Clean up notification file
          rm -f "${notification_file}"
          echo "알림 처리 완료: $user_input"

          echo "$user_input"
          exit 0
        else
          echo "${colors.red}${symbols.cross} 잘못된 입력입니다. y/l/n/s 중 하나를 선택하세요.${colors.reset}"
        fi
      done
    '';

  # Helper function to check if terminal supports colors
  supportsColor = pkgs.writeShellScript "supports-color" ''
    # Check if terminal supports colors
    if [ -t 1 ] && [ -n "''${TERM:-}" ] && [ "$TERM" != "dumb" ]; then
      # Check if tput is available and can determine colors
      if command -v tput >/dev/null 2>&1; then
        colors=$(tput colors 2>/dev/null || echo 0)
        [ "$colors" -ge 8 ]
      else
        # Fallback: assume color support for common terminals
        case "$TERM" in
          *color*|xterm*|screen*|tmux*|rxvt*)
            true
            ;;
          *)
            false
            ;;
        esac
      fi
    else
      false
    fi
  '';

  # Create a non-blocking shell integration function
  shellIntegration = pkgs.writeShellScript "auto-update-shell-integration" ''
    # Check for pending notifications without blocking shell startup
    check_dotfiles_updates() {
      local cache_dir="$HOME/.cache/dotfiles-updates"
      local notification_files

      # Quick check - if no cache directory, nothing to do
      [ -d "$cache_dir" ] || return 0

      # Find pending notifications (limit to prevent slowdown)
      notification_files=$(find "$cache_dir" -name "pending-*.json" -type f 2>/dev/null | head -5)

      # If no notifications, return
      [ -n "$notification_files" ] || return 0

      # For each notification, show prompt
      echo "$notification_files" | while IFS= read -r notification_file; do
        [ -f "$notification_file" ] || continue

        # Extract commit hash from filename
        commit_hash=$(basename "$notification_file" .json | sed 's/pending-//')

        # Read notification data
        if command -v jq >/dev/null 2>&1; then
          summary=$(jq -r '.summary // "업데이트 사용 가능"' "$notification_file" 2>/dev/null)
          changes_count=$(jq -r '.changes_count // 1' "$notification_file" 2>/dev/null)
        else
          # Fallback parsing without jq
          summary="업데이트 사용 가능"
          changes_count=1
        fi

        # Show prompt - create prompt on demand
        prompt_script=$(${pkgs.nix}/bin/nix eval --impure --expr '
          let prompt = import ${./auto-update-prompt.nix} { inherit (import <nixpkgs> {}) lib pkgs; };
          in prompt.promptUserWithTimeout {
            commit_hash = "'"$commit_hash"'";
            summary = "'"$summary"'";
            changes_count = '"$changes_count"';
            notification_file = "'"$notification_file"'";
          }
        ')

        result=$($prompt_script)

        # Handle special 'show' result
        if [ "$result" = "show" ]; then
          echo "${colors.blue}${symbols.eye} 변경사항 표시 기능은 다음 단계에서 구현됩니다${colors.reset}"
          # Re-prompt after showing changes
          result=$($prompt_script)
        fi
      done
    }

    # Only run in interactive shells
    if [ -n "''${PS1:-}" ]; then
      check_dotfiles_updates
    fi
  '';
}
