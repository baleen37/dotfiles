#!/usr/bin/env bash

# bl - Baleen's small, safety-first command toolkit.
#
# `bl gc` intentionally limits itself to regenerable development data. Git
# worktrees are handled separately and only clean worktrees with at least
# three days of inactivity are eligible.

set -uo pipefail

readonly STALE_WORKTREE_SECONDS=259200

WORKTREE_AVAILABLE=0
MAIN_WORKTREE=""
CURRENT_WORKTREE=""
WORKTREE_ALL_PATHS=()
WORKTREE_CANDIDATE_PATHS=()
WORKTREE_CANDIDATE_BRANCHES=()
WORKTREE_CANDIDATE_AGES=()
WORKTREE_CANDIDATE_SIZES=()
WORKTREE_REMOVAL_TARGETS=()
WORKTREE_REMOVED_COUNT=0

command_exists() {
  command -v "$1" > /dev/null 2>&1
}

usage() {
  cat << 'EOF'
bl - Baleen toolkit

Usage: bl <command> [options]

Commands:
  gc [stats|--dry-run]  Clean regenerable development data
  list                  List available commands

Options:
  -h, --help            Show this help

Examples:
  bl gc                 Show candidates, then clean after confirmation
  bl gc stats           Show cache, disk, and stale worktree sizes
  bl gc --dry-run       Show the plan without deleting anything
EOF
}

gc_usage() {
  cat << 'EOF'
Usage: bl gc [stats|--dry-run|help]

  bl gc                 Show candidates and ask before cleanup
  bl gc stats           Show sizes without deleting
  bl gc --dry-run       Show sizes and planned cleanup without deleting
  bl gc help            Show this help

Safe boundaries:
  - Nix store GC removes unreachable paths only.
  - Worktree cleanup considers clean worktrees inactive for at least 3 days.
  - Running worktrees, dirty worktrees, and the current/main worktree stay.
  - Docker cleanup never removes running containers or named volumes.
  - Docker image cleanup keeps the default dangling-image scope.
EOF
}

list_commands() {
  cat << 'EOF'
Available bl commands:
  bl gc [stats|--dry-run]
EOF
}

print_size() {
  local label="$1"
  local path="$2"
  local size

  if [[ -d $path && ! -L $path ]]; then
    size=$(du -sh "$path" 2> /dev/null | awk 'NR == 1 { print $1 }')
    [[ -n $size ]] || size="?"
  else
    size="0B"
  fi
  printf '  %-24s %s\n' "$label" "$size"
}

disk_free_kb() {
  local available
  available=$(df -Pk "$HOME" 2> /dev/null | awk 'NR == 2 { print $4 }')
  [[ $available =~ ^[0-9]+$ ]] || return 1
  printf '%s\n' "$available"
}

print_disk_status() {
  local status
  status=$(df -h "$HOME" 2> /dev/null | awk 'NR == 2 { print $4 " free (" $5 " used)" }')
  if [[ -n $status ]]; then
    printf 'Disk: %s\n' "$status"
  else
    printf 'Disk: unavailable\n'
  fi
}

resolve_cache_path() {
  local fallback="$1"
  local command_name="$2"
  shift 2
  local resolved

  resolved=""
  if command_exists "$command_name"; then
    resolved=$("$command_name" "$@" 2> /dev/null || true)
  fi
  if [[ $resolved == /* && -d $resolved && ! -L $resolved ]]; then
    printf '%s\n' "$resolved"
  else
    printf '%s\n' "$fallback"
  fi
}

print_cache_stats() {
  local npm_cache pnpm_cache uv_cache pip_cache

  npm_cache=$(resolve_cache_path "$HOME/.npm" npm config get cache)
  pnpm_cache=$(resolve_cache_path "$HOME/Library/pnpm/store" pnpm store path)
  uv_cache=$(resolve_cache_path "$HOME/.cache/uv" uv cache dir)
  pip_cache=$(resolve_cache_path "$HOME/Library/Caches/pip" pip cache dir)

  printf 'Regenerable development data:\n'
  print_size "Homebrew cache" "${HOMEBREW_CACHE:-$HOME/Library/Caches/Homebrew}"
  print_size "Nix store (total)" "/nix/store"
  print_size "npm cache" "$npm_cache"
  print_size "pnpm store" "$pnpm_cache"
  print_size "Yarn cache" "$HOME/Library/Caches/Yarn"
  print_size "uv cache" "$uv_cache"
  print_size "pip cache" "$pip_cache"
  print_size "Gradle caches" "$HOME/.gradle/caches"
  print_size "Xcode DerivedData" "$HOME/Library/Developer/Xcode/DerivedData"
}

canonical_path() {
  local path="$1"
  (cd "$path" 2> /dev/null && pwd -P)
}

file_mtime() {
  local path="$1"
  local value

  if value=$(stat -c %Y "$path" 2> /dev/null); then
    printf '%s\n' "$value"
  elif value=$(stat -f %m "$path" 2> /dev/null); then
    printf '%s\n' "$value"
  else
    return 1
  fi
}

worktree_age_seconds() {
  local path="$1"
  local directory_time commit_time last_activity now

  directory_time=$(file_mtime "$path") || return 1
  commit_time=$(git -C "$path" log -1 --format=%ct HEAD 2> /dev/null) || return 1
  [[ $directory_time =~ ^[0-9]+$ && $commit_time =~ ^[0-9]+$ ]] || return 1

  last_activity="$directory_time"
  if ((commit_time > last_activity)); then
    last_activity="$commit_time"
  fi

  now=$(date +%s)
  if ((now > last_activity)); then
    printf '%s\n' "$((now - last_activity))"
  else
    printf '0\n'
  fi
}

age_label() {
  local seconds="$1"
  local days
  days=$((seconds / 86400))

  if ((days >= 1)); then
    printf '%sd\n' "$days"
  else
    printf '<1d\n'
  fi
}

directory_size() {
  local path="$1"
  local size

  size=$(du -sh "$path" 2> /dev/null | awk 'NR == 1 { print $1 }')
  [[ -n $size ]] || size="?"
  printf '%s\n' "$size"
}

reset_worktree_inventory() {
  MAIN_WORKTREE=""
  CURRENT_WORKTREE=""
  WORKTREE_ALL_PATHS=()
  WORKTREE_CANDIDATE_PATHS=()
  WORKTREE_CANDIDATE_BRANCHES=()
  WORKTREE_CANDIDATE_AGES=()
  WORKTREE_CANDIDATE_SIZES=()
  WORKTREE_REMOVAL_TARGETS=()
  WORKTREE_REMOVED_COUNT=0
}

record_worktree() {
  local path="$1"
  local branch="$2"
  local locked="$3"
  local target age

  target=$(canonical_path "$path" || true)
  [[ -n $target ]] || return 0

  if [[ -z $MAIN_WORKTREE ]]; then
    MAIN_WORKTREE="$target"
  fi
  WORKTREE_ALL_PATHS+=("$target")

  # The base, current, detached, bare, and unrecognizable worktrees are
  # protected because they cannot be safely identified as disposable.
  if [[ $target == "$MAIN_WORKTREE" ]]; then
    return 0
  fi
  if [[ $target == "$CURRENT_WORKTREE" ]]; then
    return 0
  fi
  if [[ $locked == 1 ]]; then
    return 0
  fi
  case "$branch" in
    "" | "(detached)" | "(bare)" | "main" | "master")
      return 0
      ;;
  esac

  if [[ -n "$(git -C "$target" status --porcelain 2> /dev/null)" ]]; then
    return 0
  fi

  age=$(worktree_age_seconds "$target" || true)
  if [[ ! $age =~ ^[0-9]+$ || $age -lt $STALE_WORKTREE_SECONDS ]]; then
    return 0
  fi

  WORKTREE_CANDIDATE_PATHS+=("$target")
  WORKTREE_CANDIDATE_BRANCHES+=("$branch")
  WORKTREE_CANDIDATE_AGES+=("$age")
  WORKTREE_CANDIDATE_SIZES+=("$(directory_size "$target")")
}

collect_worktrees() {
  local repo_root field path branch locked

  reset_worktree_inventory
  command_exists git || return 1
  repo_root=$(git rev-parse --show-toplevel 2> /dev/null) || return 1
  CURRENT_WORKTREE=$(canonical_path "$repo_root" || true)
  [[ -n $CURRENT_WORKTREE ]] || return 1

  path=""
  branch=""
  locked=0
  while IFS= read -r -d '' field; do
    if [[ -z $field ]]; then
      if [[ -n $path ]]; then
        record_worktree "$path" "$branch" "$locked"
        path=""
        branch=""
        locked=0
      fi
      continue
    fi

    case "$field" in
      worktree\ *)
        if [[ -n $path ]]; then
          record_worktree "$path" "$branch" "$locked"
        fi
        path="${field#worktree }"
        branch=""
        locked=0
        ;;
      branch\ *) branch="${field#branch refs/heads/}" ;;
      detached) branch="(detached)" ;;
      bare) branch="(bare)" ;;
      locked | locked\ *) locked=1 ;;
    esac
  done < <(
    git worktree list --porcelain -z 2> /dev/null
  )

  if [[ -n $path ]]; then
    record_worktree "$path" "$branch" "$locked"
  fi

  [[ -n $MAIN_WORKTREE ]]
}

print_worktree_stats() {
  local index

  if ((WORKTREE_AVAILABLE == 0)); then
    printf 'Worktrees: not in a Git repository (skipped)\n'
    return 0
  fi

  printf 'Stale clean worktrees (>= 3 days): %s\n' "${#WORKTREE_CANDIDATE_PATHS[@]}"
  for index in "${!WORKTREE_CANDIDATE_PATHS[@]}"; do
    printf '  %-24s %4s  %6s  %s\n' \
      "${WORKTREE_CANDIDATE_BRANCHES[$index]}" \
      "$(age_label "${WORKTREE_CANDIDATE_AGES[$index]}")" \
      "${WORKTREE_CANDIDATE_SIZES[$index]}" \
      "${WORKTREE_CANDIDATE_PATHS[$index]}"
  done
}

docker_available() {
  command_exists docker && docker info > /dev/null 2>&1
}

print_docker_stats() {
  if docker_available; then
    printf 'Docker data:\n'
    docker system df 2> /dev/null || printf '  Docker usage: unavailable\n'
  else
    printf 'Docker: daemon unavailable (skipped)\n'
  fi
}

show_gc_stats() {
  print_disk_status
  printf '\n'
  print_cache_stats
  printf '\n'
  if collect_worktrees; then
    WORKTREE_AVAILABLE=1
  else
    WORKTREE_AVAILABLE=0
  fi
  print_worktree_stats
  printf '\n'
  print_docker_stats
}

print_gc_plan() {
  cat << 'EOF'

Planned cleanup:
  - Homebrew cleanup, package-manager caches, Gradle caches, and Xcode DerivedData
  - Nix unreachable store paths after cache/worktree cleanup
  - Clean worktrees inactive for at least 3 days, after a separate confirmation
  - Docker stopped containers, dangling images, and builder cache, after a separate confirmation
EOF
}

confirm() {
  local prompt="$1"
  local answer

  read -r -p "$prompt" answer || {
    printf '\n'
    return 1
  }
  printf '\n'
  [[ $answer =~ ^[Yy]$ ]]
}

run_cleanup() {
  local label="$1"
  shift

  printf '  %-24s' "$label"
  if "$@"; then
    printf ' done\n'
  else
    printf ' failed, continuing\n' >&2
  fi
}

clear_known_directory() {
  local path="$1"

  case "$path" in
    "$HOME/.gradle/caches" | "$HOME/Library/Developer/Xcode/DerivedData") ;;
    *)
      printf 'Refusing unknown cleanup path: %s\n' "$path" >&2
      return 1
      ;;
  esac

  [[ -d $path && ! -L $path ]] || return 0
  rm -rf "$path" || return 1
  mkdir -p "$path"
}

clean_development_caches() {
  printf 'Cleaning regenerable development data...\n'

  if command_exists brew; then
    run_cleanup "Homebrew" brew cleanup
  fi
  if command_exists npm; then
    run_cleanup "npm" npm cache clean --force
  fi
  if command_exists pnpm; then
    run_cleanup "pnpm" pnpm store prune
  fi
  if command_exists yarn; then
    run_cleanup "Yarn" yarn cache clean
  fi
  if command_exists uv; then
    run_cleanup "uv" uv cache clean
  fi
  if command_exists pip; then
    run_cleanup "pip" pip cache purge
  fi
  if [[ -d "$HOME/.gradle/caches" && ! -L "$HOME/.gradle/caches" ]]; then
    run_cleanup "Gradle" clear_known_directory "$HOME/.gradle/caches"
  fi
  if [[ -d "$HOME/Library/Developer/Xcode/DerivedData" ]]; then
    if [[ ! -L "$HOME/Library/Developer/Xcode/DerivedData" ]]; then
      run_cleanup "Xcode DerivedData" \
        clear_known_directory "$HOME/Library/Developer/Xcode/DerivedData"
    fi
  fi
}

prepare_worktree_targets() {
  local candidate other nested

  WORKTREE_REMOVAL_TARGETS=()
  for candidate in "${WORKTREE_CANDIDATE_PATHS[@]}"; do
    nested=0
    for other in "${WORKTREE_ALL_PATHS[@]}"; do
      [[ $other == "$candidate" ]] && continue
      case "$other" in
        "$candidate"/*)
          nested=1
          break
          ;;
      esac
    done
    if ((nested == 0)); then
      WORKTREE_REMOVAL_TARGETS+=("$candidate")
    else
      printf '  skipped nested worktree parent: %s\n' "$candidate"
    fi
  done
}

remove_stale_worktrees() {
  local target failed

  prepare_worktree_targets
  WORKTREE_REMOVED_COUNT=0
  failed=0
  for target in "${WORKTREE_REMOVAL_TARGETS[@]}"; do
    if git worktree remove "$target"; then
      printf '  removed worktree: %s\n' "$target"
      WORKTREE_REMOVED_COUNT=$((WORKTREE_REMOVED_COUNT + 1))
    else
      printf '  failed worktree: %s\n' "$target" >&2
      failed=1
    fi
  done
  return "$failed"
}

run_nix_gc() {
  if command_exists nix; then
    run_cleanup "Nix store GC" nix store gc
  fi
}

clean_docker() {
  run_cleanup "Docker containers" docker container prune --force
  run_cleanup "Docker images" docker image prune --force
  run_cleanup "Docker builder" docker builder prune --force
}

print_disk_delta() {
  local before_kb="$1"
  local after_kb="$2"
  local delta_kb

  printf '\n'
  print_disk_status
  if [[ $before_kb =~ ^[0-9]+$ && $after_kb =~ ^[0-9]+$ ]]; then
    delta_kb=$((after_kb - before_kb))
    if ((delta_kb >= 0)); then
      printf 'Reclaimed since start: %s KiB\n' "$delta_kb"
    else
      printf 'Disk change since start: %s KiB\n' "$delta_kb"
    fi
  fi
}

run_gc() {
  local before_kb after_kb
  local cache_cleanup_requested=0
  local worktree_cleanup_requested=0

  before_kb=$(disk_free_kb || true)
  show_gc_stats
  printf '\n'

  if confirm "Clean listed development data? [y/N] "; then
    cache_cleanup_requested=1
    clean_development_caches
  else
    printf 'Development data cleanup skipped\n'
  fi

  if ((WORKTREE_AVAILABLE == 1 && ${#WORKTREE_CANDIDATE_PATHS[@]} > 0)); then
    if confirm "Remove listed clean worktrees older than 3 days? [y/N] "; then
      worktree_cleanup_requested=1
      remove_stale_worktrees || true
    else
      printf 'Worktree cleanup skipped\n'
    fi
  fi

  if ((cache_cleanup_requested == 1 || worktree_cleanup_requested == 1)); then
    run_nix_gc
  fi

  if docker_available; then
    if confirm "Run Docker cleanup (no volumes/running containers)? [y/N] "; then
      clean_docker
    else
      printf 'Docker cleanup skipped\n'
    fi
  fi

  after_kb=$(disk_free_kb || true)
  print_disk_delta "$before_kb" "$after_kb"
}

gc_command() {
  case "${1:-}" in
    "") run_gc ;;
    stats)
      [[ $# -eq 1 ]] || {
        gc_usage >&2
        return 2
      }
      show_gc_stats
      ;;
    --dry-run)
      [[ $# -eq 1 ]] || {
        gc_usage >&2
        return 2
      }
      show_gc_stats
      print_gc_plan
      ;;
    help | -h | --help)
      [[ $# -eq 1 ]] || {
        gc_usage >&2
        return 2
      }
      gc_usage
      ;;
    *)
      printf "Unknown bl gc option: %s\n" "$1" >&2
      gc_usage >&2
      return 2
      ;;
  esac
}

case "${1:-}" in
  "" | -h | --help)
    usage
    ;;
  list)
    list_commands
    ;;
  gc)
    shift
    gc_command "$@"
    ;;
  *)
    printf "Unknown bl command: %s\n" "$1" >&2
    usage >&2
    exit 2
    ;;
esac
