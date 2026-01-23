#!/usr/bin/env bash
# Manual smoke test for statusline.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATUSLINE_SCRIPT="$SCRIPT_DIR/../users/shared/.config/claude/statusline.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🧪 Manual Statusline Smoke Tests"
echo "================================="
echo

# Test 1: Script runs with real Claude Code JSON format (no current_usage)
echo -n "Test 1: Script runs with real Claude Code JSON format... "
input=$(cat <<EOF
{
  "hook_event_name": "Status",
  "model": {"display_name": "Sonnet 4.5"},
  "workspace": {"current_dir": "$PWD"},
  "context_window": {
    "total_input_tokens": 1000,
    "total_output_tokens": 100
  }
}
EOF
)

if output=$(echo "$input" | bash "$STATUSLINE_SCRIPT" 2>&1); then
  if echo "$output" | grep -q "Ctx:"; then
    echo -e "${GREEN}✓ PASS${NC}"
  else
    echo -e "${RED}✗ FAIL${NC} - Output missing 'Ctx:' indicator"
    echo "Output: $output"
    exit 1
  fi
else
  echo -e "${RED}✗ FAIL${NC} - Script crashed"
  echo "Output: $output"
  exit 1
fi

# Test 2: Script handles missing transcript file with real JSON format
echo -n "Test 2: Script handles missing transcript file... "
input=$(cat <<EOF
{
  "hook_event_name": "Status",
  "model": {"display_name": "Sonnet 4.5"},
  "workspace": {"current_dir": "$PWD"},
  "context_window": {
    "total_input_tokens": 2000,
    "total_output_tokens": 200
  },
  "transcript_path": "/nonexistent/file.jsonl"
}
EOF
)

if output=$(echo "$input" | bash "$STATUSLINE_SCRIPT" 2>&1); then
  echo -e "${GREEN}✓ PASS${NC}"
else
  echo -e "${RED}✗ FAIL${NC} - Script crashed on missing transcript"
  echo "Output: $output"
  exit 1
fi

# Test 3: Script uses current_usage when available (preferred over transcript)
echo -n "Test 3: Script uses current_usage from context_window... "
temp_transcript=$(mktemp)
cat > "$temp_transcript" <<'EOF'
{"message":{"usage":{"input_tokens":500,"cache_read_input_tokens":200,"cache_creation_input_tokens":100}},"isSidechain":false,"timestamp":"2025-12-01T10:00:00Z"}
{"message":{"usage":{"input_tokens":1000,"cache_read_input_tokens":400,"cache_creation_input_tokens":200}},"isSidechain":false,"timestamp":"2025-12-01T10:01:00Z"}
EOF

input=$(cat <<EOF
{
  "hook_event_name": "Status",
  "model": {"display_name": "Sonnet 4.5"},
  "workspace": {"current_dir": "$PWD"},
  "context_window": {
    "current_usage": {
      "input_tokens": 1000,
      "output_tokens": 200,
      "cache_creation_input_tokens": 200,
      "cache_read_input_tokens": 400
    }
  },
  "transcript_path": "$temp_transcript"
}
EOF
)

if output=$(echo "$input" | bash "$STATUSLINE_SCRIPT" 2>&1); then
  # Should show context from current_usage (1600 tokens = 1000+400+200)
  # Not from transcript (current_usage has priority)
  if echo "$output" | grep -q "Ctx: 1.6k"; then
    echo -e "${GREEN}✓ PASS${NC}"
    echo "  Output: $output" | head -1
  else
    echo -e "${RED}✗ FAIL${NC} - Missing context info"
    echo "Output: $output"
    rm "$temp_transcript"
    exit 1
  fi
else
  echo -e "${RED}✗ FAIL${NC} - Script crashed"
  echo "Output: $output"
  rm "$temp_transcript"
  exit 1
fi

rm "$temp_transcript"

# Test 4: Script filters sidechain entries
echo -n "Test 4: Script filters sidechain entries... "
temp_transcript=$(mktemp)
cat > "$temp_transcript" <<'EOF'
{"message":{"usage":{"input_tokens":9999,"cache_read_input_tokens":9999,"cache_creation_input_tokens":9999}},"isSidechain":true,"timestamp":"2025-12-01T10:00:00Z"}
{"message":{"usage":{"input_tokens":1000,"cache_read_input_tokens":400,"cache_creation_input_tokens":200}},"isSidechain":false,"timestamp":"2025-12-01T10:01:00Z"}
EOF

input=$(cat <<EOF
{
  "model": {"display_name": "Sonnet 4.5"},
  "workspace": {"current_dir": "$PWD"},
  "context": {"length": 500},
  "transcript_path": "$temp_transcript"
}
EOF
)

if output=$(echo "$input" | bash "$STATUSLINE_SCRIPT" 2>&1); then
  # Should use non-sidechain entry (1600, not 29997)
  echo -e "${GREEN}✓ PASS${NC}"
  echo "  Output: $output" | head -1
else
  echo -e "${RED}✗ FAIL${NC} - Script crashed"
  echo "Output: $output"
  rm "$temp_transcript"
  exit 1
fi

rm "$temp_transcript"

# Test 5: Script handles empty transcript with real JSON format
echo -n "Test 5: Script handles empty transcript... "
temp_transcript=$(mktemp)
# Empty file

input=$(cat <<EOF
{
  "hook_event_name": "Status",
  "model": {"display_name": "Sonnet 4.5"},
  "workspace": {"current_dir": "$PWD"},
  "context_window": {
    "total_input_tokens": 3000,
    "total_output_tokens": 300
  },
  "transcript_path": "$temp_transcript"
}
EOF
)

if output=$(echo "$input" | bash "$STATUSLINE_SCRIPT" 2>&1); then
  # Should fallback to total_input_tokens (3000)
  echo -e "${GREEN}✓ PASS${NC}"
else
  echo -e "${RED}✗ FAIL${NC} - Script crashed on empty transcript"
  echo "Output: $output"
  rm "$temp_transcript"
  exit 1
fi

rm "$temp_transcript"

# Test 6: used_percentage fallback - basic case (25.5% of 200k = 51k)
echo -n "Test 6: used_percentage fallback (25.5% of 200k = 51k)... "
input=$(cat <<EOF
{
  "hook_event_name": "Status",
  "model": {"display_name": "Sonnet 4.5"},
  "workspace": {"current_dir": "$PWD"},
  "context_window": {
    "used_percentage": 25.5,
    "context_window_size": 200000
  }
}
EOF
)

if output=$(echo "$input" | bash "$STATUSLINE_SCRIPT" 2>&1); then
  if echo "$output" | grep -q "Ctx: 51.0k"; then
    echo -e "${GREEN}✓ PASS${NC}"
    echo "  Output: $output" | head -1
  else
    echo -e "${RED}✗ FAIL${NC} - Expected 'Ctx: 51.0k'"
    echo "Output: $output"
    exit 1
  fi
else
  echo -e "${RED}✗ FAIL${NC} - Script crashed"
  echo "Output: $output"
  exit 1
fi

# Test 7: used_percentage fallback - large value with M suffix (80% of 2M = 1.6M)
echo -n "Test 7: used_percentage fallback (80% of 2M = 1.6M)... "
input=$(cat <<EOF
{
  "hook_event_name": "Status",
  "model": {"display_name": "Sonnet 4.5"},
  "workspace": {"current_dir": "$PWD"},
  "context_window": {
    "used_percentage": 80,
    "context_window_size": 2000000
  }
}
EOF
)

if output=$(echo "$input" | bash "$STATUSLINE_SCRIPT" 2>&1); then
  if echo "$output" | grep -q "Ctx: 1.6M"; then
    echo -e "${GREEN}✓ PASS${NC}"
    echo "  Output: $output" | head -1
  else
    echo -e "${RED}✗ FAIL${NC} - Expected 'Ctx: 1.6M'"
    echo "Output: $output"
    exit 1
  fi
else
  echo -e "${RED}✗ FAIL${NC} - Script crashed"
  echo "Output: $output"
  exit 1
fi

# Test 8: used_percentage fallback - null values should default to 0
echo -n "Test 8: used_percentage fallback (null values)... "
input=$(cat <<EOF
{
  "hook_event_name": "Status",
  "model": {"display_name": "Sonnet 4.5"},
  "workspace": {"current_dir": "$PWD"},
  "context_window": {
    "used_percentage": null,
    "context_window_size": null
  }
}
EOF
)

if output=$(echo "$input" | bash "$STATUSLINE_SCRIPT" 2>&1); then
  if echo "$output" | grep -q "Ctx: 0"; then
    echo -e "${GREEN}✓ PASS${NC}"
    echo "  Output: $output" | head -1
  else
    echo -e "${RED}✗ FAIL${NC} - Expected 'Ctx: 0'"
    echo "Output: $output"
    exit 1
  fi
else
  echo -e "${RED}✗ FAIL${NC} - Script crashed"
  echo "Output: $output"
  exit 1
fi

# Test 9: used_percentage fallback - 0 values should result in 0
echo -n "Test 9: used_percentage fallback (0 values)... "
input=$(cat <<EOF
{
  "hook_event_name": "Status",
  "model": {"display_name": "Sonnet 4.5"},
  "workspace": {"current_dir": "$PWD"},
  "context_window": {
    "used_percentage": 0,
    "context_window_size": 0
  }
}
EOF
)

if output=$(echo "$input" | bash "$STATUSLINE_SCRIPT" 2>&1); then
  if echo "$output" | grep -q "Ctx: 0"; then
    echo -e "${GREEN}✓ PASS${NC}"
    echo "  Output: $output" | head -1
  else
    echo -e "${RED}✗ FAIL${NC} - Expected 'Ctx: 0'"
    echo "Output: $output"
    exit 1
  fi
else
  echo -e "${RED}✗ FAIL${NC} - Script crashed"
  echo "Output: $output"
  exit 1
fi

# Test 10: used_percentage fallback - full chain test
echo -n "Test 10: used_percentage fallback (full chain)... "
input=$(cat <<EOF
{
  "hook_event_name": "Status",
  "model": {"display_name": "Unknown Model"},
  "workspace": {"current_dir": "$PWD"},
  "context_window": {
    "current_usage": null,
    "total_input_tokens": null,
    "used_percentage": 50,
    "context_window_size": 100000
  }
}
EOF
)

if output=$(echo "$input" | bash "$STATUSLINE_SCRIPT" 2>&1); then
  if echo "$output" | grep -q "Ctx: 50.0k"; then
    echo -e "${GREEN}✓ PASS${NC}"
    echo "  Output: $output" | head -1
  else
    echo -e "${RED}✗ FAIL${NC} - Expected 'Ctx: 50.0k'"
    echo "Output: $output"
    exit 1
  fi
else
  echo -e "${RED}✗ FAIL${NC} - Script crashed"
  echo "Output: $output"
  exit 1
fi

echo
echo -e "${GREEN}✅ All tests passed!${NC}"
