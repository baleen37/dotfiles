# Git Worktree wrapper for Zsh
#
# Returns a pure string of shell code defining the gw function.
# Usage: gw <branch-name>

''
  # Git Worktree wrapper - Create git worktree and cd into it
  # Usage: gw <branch-name>
  gw() {
    local branch_name="$1"

    # Validate arguments
    if [[ $# -eq 0 ]]; then
      echo "Usage: gw <branch-name>"
      return 1
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

    # Helper: Create worktree with existing or new branch
    # Outputs error messages to stderr on failure, returns exit code
    local _create_worktree() {
      local branch="$1"
      local worktree_dir="$2"
      local base_branch="$3"
      local error_output

      if git rev-parse --verify "$branch" >/dev/null 2>&1; then
        _msg "$BLUE" "Branch '$branch' already exists. Using existing branch."
        error_output=$(git worktree add "$worktree_dir" "$branch" 2>&1)
      else
        _msg "$GREEN" "Creating new branch '$branch' (base: $base_branch)"
        error_output=$(git worktree add -b "$branch" "$worktree_dir" "$base_branch" 2>&1)
      fi

      local result=$?
      if [[ $result -ne 0 ]]; then
        echo "$error_output" >&2
      fi
      return $result
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
