# Claude Code wrapper functions for Zsh
#
# Returns a pure string of shell code defining:
#   cc/cc-h/cc-l:    Anthropic API (sonnet/opus/haiku)
#   cco/cco-h/cco-l: OpenAI-compatible proxy
#   ccz/ccz-h/ccz-l: Z.ai GLM API
#   cck:             Kimi API via OpenAI-compatible proxy
# Configure cco/ccz/cck models in ~/.zshrc.local
#
# Note: ENABLE_TOOL_SEARCH must be set explicitly per wrapper because
# settings.json env values override shell environment variables, making
# wrapper-level overrides ineffective. cco disables it (causes defer_loading
# errors with OpenAI-compatible proxies); cc and ccz explicitly enable it.

''
  # Internal helper - do not call directly
  _cc_run() {
    local model="$1"; shift
    if [[ -n "$model" ]]; then
      command claude --dangerously-skip-permissions --model "$model" "$@"
    else
      command claude --dangerously-skip-permissions "$@"
    fi
  }

  # Parse -h/--high and -l/--low model flags
  # Usage: eval "$(_cc_parse_model_flags <default> <high> <low> name args...)"
  # Sets 'name' variable to selected model and removes consumed flags from args
  _cc_parse_model_flags() {
    local default_model="$1"
    local high_model="$2"
    local low_model="$3"
    local var_name="$4"
    shift 4
    local model="$default_model"
    local args=()

    while [[ $# -gt 0 ]]; do
      case "$1" in
        -h|--high)
          model="$high_model"
          shift
          ;;
        -l|--low)
          model="$low_model"
          shift
          ;;
        --)
          shift
          args+=("$@")
          break
          ;;
        *)
          args+=("$1")
          shift
          ;;
      esac
    done

    echo "''${var_name}=\"''${model}\"; set -- \"''${args[@]}\""
  }

  cc() {
    eval "$(_cc_parse_model_flags "" "opus" "haiku" model "$@")"
    ENABLE_TOOL_SEARCH=true _cc_run "$model" "$@"
  }

  # cco: Configure in ~/.zshrc.local:
  #   CCO_BASE_URL, CCO_AUTH_TOKEN
  #   CCO_OPUS_MODEL, CCO_SONNET_MODEL, CCO_HAIKU_MODEL
  _cco_run() {
    local model="$1"; shift
    ENABLE_TOOL_SEARCH=false \
    ANTHROPIC_BASE_URL="''${CCO_BASE_URL:-http://127.0.0.1:8317}" \
    ANTHROPIC_AUTH_TOKEN="''${CCO_AUTH_TOKEN:-sk-dummy}" \
    ANTHROPIC_DEFAULT_OPUS_MODEL="''${CCO_OPUS_MODEL:-}" \
    ANTHROPIC_DEFAULT_SONNET_MODEL="''${CCO_SONNET_MODEL:-}" \
    ANTHROPIC_DEFAULT_HAIKU_MODEL="''${CCO_HAIKU_MODEL:-}" \
    _cc_run "$model" "$@"
  }

  cco() {
    eval "$(_cc_parse_model_flags "''${CCO_SONNET_MODEL:?Set CCO_SONNET_MODEL in ~/.zshrc.local}" "''${CCO_OPUS_MODEL:?Set CCO_OPUS_MODEL in ~/.zshrc.local}" "''${CCO_HAIKU_MODEL:?Set CCO_HAIKU_MODEL in ~/.zshrc.local}" model "$@")"
    _cco_run "$model" "$@"
  }

  # ccz: Configure in ~/.zshrc.local:
  #   CCZ_TOKEN, CCZ_HAIKU_MODEL, CCZ_SONNET_MODEL, CCZ_OPUS_MODEL
  _ccz_run() {
    local model="$1"; shift
    ENABLE_TOOL_SEARCH=true \
    ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic" \
    ANTHROPIC_AUTH_TOKEN="''${CCZ_TOKEN:-}" \
    ANTHROPIC_DEFAULT_HAIKU_MODEL="''${CCZ_HAIKU_MODEL:-}" \
    ANTHROPIC_DEFAULT_SONNET_MODEL="''${CCZ_SONNET_MODEL:-}" \
    ANTHROPIC_DEFAULT_OPUS_MODEL="''${CCZ_OPUS_MODEL:-}" \
    _cc_run "$model" "$@"
  }

  ccz() {
    eval "$(_cc_parse_model_flags "''${CCZ_SONNET_MODEL:?Set CCZ_SONNET_MODEL in ~/.zshrc.local}" "''${CCZ_OPUS_MODEL:?Set CCZ_OPUS_MODEL in ~/.zshrc.local}" "''${CCZ_HAIKU_MODEL:?Set CCZ_HAIKU_MODEL in ~/.zshrc.local}" model "$@")"
    _ccz_run "$model" "$@"
  }

  # cck: Kimi API via OpenAI-compatible proxy
  # Configure in ~/.zshrc.local:
  #   CCK_BASE_URL, CCK_AUTH_TOKEN
  #   CCK_HIGH_MODEL, CCK_LOW_MODEL
  _cck_run() {
    local model="$1"; shift
    ANTHROPIC_BASE_URL="''${CCK_BASE_URL:-http://127.0.0.1:8317}" \
    ANTHROPIC_AUTH_TOKEN="''${CCK_AUTH_TOKEN:-sk-dummy}" \
    _cc_run "$model" "$@"
  }

  cck() {
    eval "$(_cc_parse_model_flags "''${CCK_MED_MODEL:-kimi-k2.5}" "''${CCK_HIGH_MODEL:-kimi-k2-thinking}" "''${CCK_LOW_MODEL:-kimi-k2}" model "$@")"
    _cck_run "$model" "$@"
  }
''
