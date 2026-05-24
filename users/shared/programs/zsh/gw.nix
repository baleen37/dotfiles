# Git Worktree wrapper for Zsh
#
# Returns a pure string of shell code defining the gw function.
# Usage: gw [branch-name]

''
  # Git Worktree wrapper - Create git worktree and cd into it
  # Usage: gw [branch-name]  (generates a random name if omitted)
  gw() {
    # Helper: Generate a random branch name like "snappy-greeting-bachman"
    local _random_branch_name() {
      local adjectives=(snappy brave calm clever eager fuzzy gentle happy jolly
        keen lively mellow nimble proud quick silly swift witty zesty bold
        bright chill cosmic cozy crisp daring dapper epic fancy fierce
        glossy humble lucky mighty peppy plucky quirky royal sunny tidy)
      local nouns=(greeting falcon otter panda harbor meadow canyon comet
        lantern beacon cipher nebula pebble prairie quartz ripple summit
        thicket tundra voyage willow anchor badger cactus dahlia ember
        fjord glacier horizon iris juniper kettle lagoon mango)
      local surnames=(bachman turing lovelace hopper knuth ritchie torvalds
        dijkstra kernighan stallman carmack abramov hickey armstrong rossum
        wall matz gosling stroustrup liskov hamilton feynman curie tesla
        darwin newton galileo kepler hubble sagan)
      local a=''${adjectives[RANDOM % ''${#adjectives[@]} + 1]}
      local n=''${nouns[RANDOM % ''${#nouns[@]} + 1]}
      local s=''${surnames[RANDOM % ''${#surnames[@]} + 1]}
      echo "''${a}-''${n}-''${s}"
    }

    # Help flag
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
      echo "Usage: gw <branch-name>"
      echo "       gw               (generates a random name)"
      return 0
    fi

    local branch_name="$1"

    # If no branch name provided, generate a random one.
    # Retry a few times if the random name collides with an existing branch,
    # since reusing an existing branch may also be checked out in another worktree.
    if [[ $# -eq 0 ]]; then
      local _attempt
      for _attempt in 1 2 3 4 5; do
        branch_name=$(_random_branch_name)
        git rev-parse --verify "$branch_name" >/dev/null 2>&1 || break
      done
    fi

    # ANSI color codes
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[0;33m'
    local BLUE='\033[0;34m'
    local RESET='\033[0m'

    # Helper: Print colored message to stderr (so command substitution doesn't capture it)
    local _msg() {
      local color="$1"
      shift
      echo "''${color}$*''${RESET}" >&2
    }

    # Helper: Print error and exit
    local _error() {
      _msg "$RED" "$@"
      return 1
    }

    # Helper: Sanitize branch name for directory (replace / with -)
    # Prefix with zero-padded sequential number based on existing worktree count
    # Always returns an absolute path based on the main worktree root so gw works
    # correctly from inside a worktree (flat, not nested).
    local _sanitize_branch() {
      local repo_root=$(git worktree list | head -1 | awk '{print $1}')
      local next_num=$(printf "%05d" $(( $(git worktree list | tail -n +2 | wc -l | tr -d ' ') + 1 )))
      echo "''${repo_root}/.worktrees/''${next_num}-''${1//\//-}"
    }

    # Helper: Find base branch (main or master)
    local _find_base_branch() {
      if git rev-parse --verify main >/dev/null 2>&1; then
        echo "main"
      elif git rev-parse --verify master >/dev/null 2>&1; then
        echo "master"
      else
        return 1
      fi
    }

    # Helper: Check if worktree directory exists
    local _check_worktree_exists() {
      if [[ -d "$1" ]]; then
        _error "Worktree already exists: $1"
        return 1
      fi
      return 0
    }

    # Helper: Create worktree with existing or new branch.
    # Echoes git's combined stdout+stderr so the caller can capture and parse it
    # via $(...). Returns git's exit code.
    local _create_worktree() {
      local branch="$1"
      local worktree_dir="$2"
      local base_branch="$3"

      if git rev-parse --verify "$branch" >/dev/null 2>&1; then
        _msg "$BLUE" "Branch '$branch' already exists. Using existing branch."
        git worktree add "$worktree_dir" "$branch" 2>&1
      else
        _msg "$GREEN" "Creating new branch '$branch' (base: $base_branch)"
        git worktree add -b "$branch" "$worktree_dir" "$base_branch" 2>&1
      fi
    }

    # Helper: Handle "branch already used by another worktree" case
    # Parses the path out of git's error and echoes it, so caller can cd there.
    local _handle_existing_worktree() {
      local error_output="$1"
      local existing_path=$(echo "$error_output" | sed -n "s/.*already used by worktree at '\(.*\)'.*/\1/p" | head -1)
      [[ -n "$existing_path" ]] && echo "$existing_path"
    }

    # Helper: Handle hierarchical branch conflicts
    local _handle_ref_conflict() {
      local branch="$1"
      local error_output="$2"

      if ! echo "$error_output" | grep -q "cannot lock ref"; then
        return 1
      fi

      local existing_branch=$(git branch --list | sed 's/^[* ]*//' | awk -v b="$branch/" 'index($0, b) == 1' | head -1)
      if [[ -z "$existing_branch" ]]; then
        return 1
      fi

      _msg "$YELLOW" "Branch '$branch' conflicts with existing branch '$existing_branch'"
      _msg "$BLUE" "Using existing branch: $existing_branch"
      echo "$existing_branch"
      return 0
    }

    # Main logic
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
      _error "Not a git repository"
      return 1
    fi

    local worktree_dir=$(_sanitize_branch "$branch_name")

    _check_worktree_exists "$worktree_dir" || return 1

    local base_branch=$(_find_base_branch)
    if [[ -z "$base_branch" ]]; then
      _error "No main or master branch found"
      return 1
    fi

    local create_error
    if ! create_error=$(_create_worktree "$branch_name" "$worktree_dir" "$base_branch"); then
      # If branch is already checked out in another worktree, jump there.
      local existing_worktree=$(_handle_existing_worktree "$create_error")
      if [[ -n "$existing_worktree" ]]; then
        _msg "$YELLOW" "Warning: branch '$branch_name' is already checked out at $existing_worktree"
        _msg "$BLUE" "Switching to existing worktree instead."
        cd "$existing_worktree"
        return 0
      fi

      # Try to handle hierarchical ref conflict
      local resolved_branch=$(_handle_ref_conflict "$branch_name" "$create_error")
      if [[ -n "$resolved_branch" ]]; then
        worktree_dir=$(_sanitize_branch "$resolved_branch")
        _check_worktree_exists "$worktree_dir" || return 1

        if ! git worktree add "$worktree_dir" "$resolved_branch" >/dev/null 2>&1; then
          _error "Failed to create worktree"
          return 1
        fi
      else
        _error "Failed to create worktree"
        echo "$create_error" >&2
        return 1
      fi
    fi

    _msg "$GREEN" "Worktree created: $worktree_dir"
    cd "$worktree_dir"
  }
''
