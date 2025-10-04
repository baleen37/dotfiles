#!/bin/sh
# Progress Display Module for Build Scripts
# Contains progress indicators, spinners, and real-time feedback functions

# Progress display variables
PROGRESS_PID=""
PROGRESS_ACTIVE=false
PROGRESS_SPINNER_CHARS="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
PROGRESS_CURRENT_STEP=0
PROGRESS_TOTAL_STEPS=0
PROGRESS_STEP_NAME=""

# Progress bar characters
PROGRESS_BAR_FILLED="█"
PROGRESS_BAR_EMPTY="░"
PROGRESS_BAR_WIDTH=30

# Initialize progress system
progress_init() {
  PROGRESS_ACTIVE=true
  PROGRESS_CURRENT_STEP=0

  # Set total steps based on platform
  if [ "$PLATFORM_TYPE" = "darwin" ]; then
    PROGRESS_TOTAL_STEPS=4 # build, switch, cleanup, summary
  else
    PROGRESS_TOTAL_STEPS=3 # build+switch, cleanup, summary
  fi
}

# Start progress indicator for a specific step
progress_start() {
  local step_name="$1"
  local estimated_time="$2"

  PROGRESS_CURRENT_STEP=$((PROGRESS_CURRENT_STEP + 1))
  PROGRESS_STEP_NAME="$step_name"

  if [ "$VERBOSE" = "false" ]; then
    # Start spinner in background for non-verbose mode
    progress_spinner &
    PROGRESS_PID=$!

    # Show progress bar
    progress_show_bar

    # Show estimated time if provided
    if [ -n "$estimated_time" ]; then
      echo "${DIM}  예상 소요 시간: ${estimated_time}${NC}"
    fi
  else
    # In verbose mode, just show the step
    progress_show_bar
  fi
}

# Stop progress indicator
progress_stop() {
  if [ -n "$PROGRESS_PID" ]; then
    # Graceful shutdown with proper signal handling
    if kill -0 "$PROGRESS_PID" 2>/dev/null; then
      kill -TERM "$PROGRESS_PID" 2>/dev/null || true
      sleep 0.1
      if kill -0 "$PROGRESS_PID" 2>/dev/null; then
        kill -KILL "$PROGRESS_PID" 2>/dev/null || true
      fi
    fi
    PROGRESS_PID=""
  fi

  # Clear the spinner line
  if [ "$VERBOSE" = "false" ]; then
    printf "\r\033[K"
  fi
}

# Show progress bar
progress_show_bar() {
  local filled=$((PROGRESS_BAR_WIDTH * PROGRESS_CURRENT_STEP / PROGRESS_TOTAL_STEPS))
  local empty=$((PROGRESS_BAR_WIDTH - filled))

  local bar=""
  local i=0

  # Build filled part
  while [ $i -lt $filled ]; do
    bar="${bar}${PROGRESS_BAR_FILLED}"
    i=$((i + 1))
  done

  # Build empty part
  i=0
  while [ $i -lt $empty ]; do
    bar="${bar}${PROGRESS_BAR_EMPTY}"
    i=$((i + 1))
  done

  local percentage=$((100 * PROGRESS_CURRENT_STEP / PROGRESS_TOTAL_STEPS))

  echo "${BLUE}[${bar}] ${percentage}% - ${PROGRESS_STEP_NAME}${NC}"
}

# Spinner animation (runs in background)
progress_spinner() {
  local i=0
  local spinner_len=${#PROGRESS_SPINNER_CHARS}

  # Set up signal handlers for graceful shutdown
  trap 'exit 0' TERM INT

  while true; do
    # Get current spinner character
    local char_pos=$((i % spinner_len))
    local spinner_char=$(echo "$PROGRESS_SPINNER_CHARS" | cut -c$((char_pos + 1)))

    # Show spinner
    printf "\r${YELLOW}%s${NC} %s" "$spinner_char" "$PROGRESS_STEP_NAME"

    sleep 0.1
    i=$((i + 1))
  done
}

# Show detailed progress for nix operations
progress_nix_detailed() {
  local operation="$1"
  local logfile="$2"

  if [ "$VERBOSE" = "false" ] && [ -f "$logfile" ]; then
    # Parse nix output for progress information
    tail -f "$logfile" | while read -r line; do
      case "$line" in
      *"downloading"*)
        echo "${DIM}  📥 의존성 다운로드 중...${NC}"
        ;;
      *"building"*)
        echo "${DIM}  🔨 빌드 중...${NC}"
        ;;
      *"copying"*)
        echo "${DIM}  📋 파일 복사 중...${NC}"
        ;;
      *"substituting"*)
        echo "${DIM}  🔄 캐시에서 가져오는 중...${NC}"
        ;;
      esac
    done
  fi
}

# Show progress for long-running operations
progress_long_operation() {
  local operation="$1"
  local pid="$2"
  local dots=""

  if [ "$VERBOSE" = "false" ]; then
    while kill -0 "$pid" 2>/dev/null; do
      dots="${dots}."
      if [ ${#dots} -gt 3 ]; then
        dots=""
      fi

      printf "\r${YELLOW}⏳${NC} %s%s   " "$operation" "$dots"
      sleep 1
    done
    printf "\r\033[K"
  fi
}

# Estimate time for operations
progress_estimate_time() {
  local operation="$1"

  case "$operation" in
  "build")
    if [ "$PLATFORM_TYPE" = "darwin" ]; then
      echo "3-5분"
    else
      echo "5-10분"
    fi
    ;;
  "switch")
    echo "1-2분"
    ;;
  "cleanup")
    echo "10초"
    ;;
  *)
    echo ""
    ;;
  esac
}

# Show completion message
progress_complete() {
  local operation="$1"
  local duration="$2"

  if [ -n "$duration" ]; then
    echo "${GREEN}✅ ${operation} 완료 (${duration}초)${NC}"
  else
    echo "${GREEN}✅ ${operation} 완료${NC}"
  fi
}

# Cleanup progress system
progress_cleanup() {
  progress_stop
  PROGRESS_ACTIVE=false
  PROGRESS_CURRENT_STEP=0
  PROGRESS_TOTAL_STEPS=0
  PROGRESS_STEP_NAME=""
}
