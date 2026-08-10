# Git Worktree wrapper for Zsh
#
# Returns a pure string of shell code defining the wt function.
# Usage: wt                  | wt <branch-name> | wt new | wt ls
#        wt rm <path> [...]  | wt prune [--stale] [--yes]

''
  # Git Worktree wrapper
  # Usage: wt                  Pick a worktree with fzf and cd into it
  #        wt <branch-name>    Create worktree and cd into it
  #        wt new              Create a randomly named worktree
  #        wt ls               List worktrees left on this machine (all repos)
  #        wt rm <path> [...]  Remove worktree, then run nix store gc in background
  #        wt prune [--stale] [--yes]
  #                            Remove merged+clean worktrees (dry-run by default)
  wt() {
    local _wt_random=0
    local herdr_workspace="''${HERDR_WORKSPACE_ID:-}"

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

    # Helper: Classify a worktree for pruning.
    # Echoes one of: safe | stale | keep
    #   safe  - merged into the base branch and has no uncommitted changes
    #   stale - unmerged, clean, and untouched for 30+ days
    #   keep  - has uncommitted changes, or is where we are standing right now
    local _classify_worktree() {
      local wt_path="$1"
      local base="$2"
      local main_root="$3"

      # Never touch the main worktree or the one we are standing in.
      local here=$(pwd -P)
      local target=$(cd "$wt_path" 2>/dev/null && pwd -P)
      if [[ -z "$target" || "$target" == "$main_root" || "$target" == "$here" ]]; then
        echo "keep"
        return 0
      fi

      # Uncommitted work always wins.
      if [[ -n $(git -C "$wt_path" status --porcelain 2>/dev/null) ]]; then
        echo "keep"
        return 0
      fi

      local branch=$(git -C "$wt_path" rev-parse --abbrev-ref HEAD 2>/dev/null)
      if [[ -z "$branch" || "$branch" == "HEAD" ]]; then
        echo "keep"
        return 0
      fi

      # A worktree checked out on the base branch itself is never safe to
      # drop, even though "merged into base" is trivially true for it.
      if [[ "$branch" == "$base" ]]; then
        echo "keep"
        return 0
      fi

      # Merged into base => safe to drop.
      if [[ -n $(git -C "$main_root" branch --merged "$base" --list "$branch" 2>/dev/null) ]]; then
        echo "safe"
        return 0
      fi

      # Unmerged but untouched for 30+ days => stale.
      if [[ -z $(find "$wt_path" -maxdepth 0 -mtime -30 2>/dev/null) ]]; then
        echo "stale"
        return 0
      fi

      echo "keep"
    }

    # Helper: fzf picker over this repo's worktrees.
    # Echoes the chosen absolute path, or nothing if cancelled.
    #
    # Scoped to the current repo rather than the machine-wide `wt ls`, which
    # indexes nix-direnv gc-roots and therefore only sees worktrees that have
    # been entered via direnv at least once.
    # Rows are "<branch>  <path relative to main root>  <age>\t<absolute path>",
    # sorted most-recently-committed first.
    #
    # Every worktree shares the main root as a prefix, so printing it on every
    # row would push the distinguishing part off-screen. The absolute path rides
    # in a trailing tab-separated field that --with-nth hides and cut recovers
    # for the cd.
    #
    # Age comes from the branch's last commit, not the directory mtime: build
    # output and direnv keep touching the directory long after the work stops,
    # so mtime says "recent" for worktrees nobody has actually worked in. One
    # for-each-ref call covers every branch (~0.03s), which per-worktree
    # `git log` calls would not.
    local _pick_worktree() {
      local line root
      root=$(git worktree list --porcelain | sed -n 's/^worktree //p' | head -1)
      line=$(
        {
          git for-each-ref --format='T %(refname:short) %(committerdate:unix)' refs/heads
          git worktree list --porcelain
        } |
          awk -v root="$root" -v now="$(date +%s)" '
          function age(ts,   s, d) {
            if (ts == "") return "-"
            s = now - ts
            d = int(s / 86400)
            if (d >= 365) return int(d / 365) "y"
            if (d >= 30) return int(d / 30) "mo"
            if (d >= 7) return int(d / 7) "w"
            if (d >= 1) return d "d"
            if (s >= 3600) return int(s / 3600) "h"
            if (s >= 60) return int(s / 60) "m"
            return "now"
          }
          function emit(label, ts) {
            printf "%-36s  %-50s %5s\t%s\t%s\n", label, d, age(ts), p, (ts == "" ? 0 : ts)
          }
          $1 == "T" {seen[$2] = $3; next}
          /^worktree /{
            p = substr($0, 10)
            d = p
            if (p == root) d = "."
            else if (index(p, root "/") == 1) d = substr(p, length(root) + 2)
          }
          /^branch /{b = substr($0, 8); sub("refs/heads/", "", b); emit(b, seen[b])}
          /^detached$/{emit("(detached)", "")}
          /^bare$/{emit("(bare)", "")}' |
          sort -t"$(printf '\t')" -k3,3nr |
          cut -f1,2 |
          fzf --no-multi \
            --delimiter='\t' \
            --with-nth=1 \
            --prompt='worktree> ' \
            --header='enter: cd   esc: cancel' \
            --height='60%' \
            --reverse \
            --cycle \
            --no-preview
      ) || return 0
      [[ -n "$line" ]] && echo "$line" | cut -f2
    }

    # Subcommands. Note: "help", "ls", "rm", "new", and "prune" are reserved
    # and cannot be used as branch names via wt.
    case "$1" in
      help | -h | --help)
        echo "Usage: wt                  Pick a worktree with fzf and cd into it"
        echo "       wt <branch-name>    Create worktree and cd into it"
        echo "       wt new              Create a randomly named worktree"
        echo "       wt ls               List worktrees left on this machine (all repos)"
        echo "       wt rm <path> [...]  Remove worktree, then run nix store gc in background"
        echo "       wt prune [--stale] [--yes]"
        echo "                           Remove merged+clean worktrees (dry-run by default)"
        return 0
        ;;
      ls)
        # List worktrees left on this machine, not just this repo's.
        # Every direnv-entered worktree registers a nix-direnv gc-root
        # symlink under /nix/var/nix/gcroots/auto pointing into its
        # .direnv/, so those targets serve as a machine-wide index.
        # Single readlink invocation over all roots — forking readlink per
        # symlink takes ~5s with hundreds of roots.
        local _gc_target _wt_dir
        readlink /nix/var/nix/gcroots/auto/*(N@) 2>/dev/null | while IFS= read -r _gc_target; do
          [[ "$_gc_target" == */.worktrees/*/.direnv/* ]] || continue
          echo "''${_gc_target%/.direnv/*}"
        done | sort -u | while IFS= read -r _wt_dir; do
          if [[ -d "$_wt_dir" ]]; then
            echo "$_wt_dir"
          else
            echo "$_wt_dir (removed, gc pending)"
          fi
        done
        return 0
        ;;
      rm)
        shift
        if [[ $# -eq 0 ]]; then
          echo "Usage: wt rm <worktree-path> [--force]" >&2
          return 1
        fi
        # Removing the worktree alone leaves nix-direnv gc-roots behind
        # (/nix/var/nix/gcroots/per-user/ -> .direnv/flake-profile-*), so
        # pair it with a GC run. GC can take minutes, so it runs detached
        # in the background. nix store gc only collects unrooted paths,
        # keeping system generations intact for rollback.
        git worktree remove "$@" || return 1
        (nix store gc >/dev/null 2>&1 &)
        echo "Worktree removed. nix store gc running in background." >&2
        return 0
        ;;
      prune)
        shift
        local include_stale=0 confirmed=0 arg
        for arg in "$@"; do
          case "$arg" in
            --stale) include_stale=1 ;;
            --yes | -y) confirmed=1 ;;
            *)
              echo "Unknown option: $arg" >&2
              echo "Usage: wt prune [--stale] [--yes]" >&2
              return 1
              ;;
          esac
        done

        local _main_root=$(git worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p' | head -1)
        if [[ -z "$_main_root" ]]; then
          echo "Not a git repository" >&2
          return 1
        fi

        local _base
        if git -C "$_main_root" rev-parse --verify main >/dev/null 2>&1; then
          _base="main"
        elif git -C "$_main_root" rev-parse --verify master >/dev/null 2>&1; then
          _base="master"
        else
          echo "No main or master branch found" >&2
          return 1
        fi

        # Collect targets. git worktree list's first line is the main worktree.
        local _wt _class
        local -a _safe _stale _keep
        while IFS= read -r _wt; do
          [[ -n "$_wt" ]] || continue
          _class=$(_classify_worktree "$_wt" "$_base" "$_main_root")
          case "$_class" in
            safe) _safe+=("$_wt") ;;
            stale) _stale+=("$_wt") ;;
            keep) _keep+=("$_wt") ;;
          esac
        done < <(git worktree list --porcelain | sed -n 's/^worktree //p' | tail -n +2)

        local -a _targets
        _targets=("''${_safe[@]}")
        if [[ $include_stale -eq 1 ]]; then
          _targets+=("''${_stale[@]}")
        fi

        # git worktree remove deletes the target directory recursively, so a
        # target that is an ancestor directory of a kept worktree (e.g. a
        # nested worktree under <target>/.worktrees/) would take the kept
        # worktree's uncommitted work down with it. Drop those targets and
        # say why.
        local -a _filtered_targets
        local _k _is_ancestor
        for _wt in "''${_targets[@]}"; do
          _is_ancestor=0
          for _k in "''${_keep[@]}"; do
            if [[ "$_k" == "$_wt"/* ]]; then
              _is_ancestor=1
              break
            fi
          done
          if [[ $_is_ancestor -eq 1 ]]; then
            echo "skipped (protects nested worktree): $_wt"
          else
            _filtered_targets+=("$_wt")
          fi
        done
        _targets=("''${_filtered_targets[@]}")

        if [[ ''${#_targets[@]} -eq 0 ]]; then
          echo "Nothing to prune."
          [[ ''${#_stale[@]} -gt 0 ]] &&
            echo "(''${#_stale[@]} stale worktree(s) available with --stale)"
          return 0
        fi

        echo "merged + clean (safe):    ''${#_safe[@]}"
        echo "old + unmerged (stale):   ''${#_stale[@]}$([[ $include_stale -eq 1 ]] && echo " (included)")"
        echo ""
        printf '%s\n' "''${_targets[@]}"
        echo ""

        if [[ $confirmed -ne 1 ]]; then
          echo "Dry run. Re-run with --yes to remove ''${#_targets[@]} worktree(s)."
          return 0
        fi

        local _failed=0
        for _wt in "''${_targets[@]}"; do
          if git worktree remove "$_wt"; then
            echo "removed: $_wt"
          else
            echo "failed:  $_wt" >&2
            _failed=1
          fi
        done

        # One GC for the whole batch, not one per removal.
        (nix store gc >/dev/null 2>&1 &)
        echo "nix store gc running in background." >&2
        return $_failed
        ;;
      new)
        _wt_random=1
        ;;
    esac

    # Bare `wt` opens the picker. Creating now lives behind `wt new` or an
    # explicit name, since with dozens of worktrees around, finding one is the
    # more common need.
    if [[ $# -eq 0 ]]; then
      if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "Not a git repository" >&2
        return 1
      fi
      local _picked=$(_pick_worktree)
      [[ -n "$_picked" ]] && cd "$_picked"
      return 0
    fi

    local branch_name="$1"

    # Set by the `new` subcommand below.
    if [[ $_wt_random -eq 1 ]]; then
      local _attempt
      for _attempt in 1 2 3 4 5; do
        branch_name=$(_random_branch_name)
        git rev-parse --verify "$branch_name" >/dev/null 2>&1 || break
      done
    fi

    local branch_existed=0
    if git rev-parse --verify "refs/heads/$branch_name" >/dev/null 2>&1; then
      branch_existed=1
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

    # Resolve the repository parent workspace. Herdr panes expose the current
    # workspace ID, which is a linked-worktree workspace when wt runs there.
    local _resolve_herdr_workspace() {
      local source_workspace
      source_workspace=$(herdr worktree list --workspace "$herdr_workspace" 2>/dev/null |
        sed -n 's/.*"source_workspace_id":"\([^"]*\)".*/\1/p')
      if [[ -z "$source_workspace" ]]; then
        _error "Failed to resolve Herdr parent workspace"
        return 1
      fi
      herdr_workspace="$source_workspace"
    }

    # Open an existing Git worktree in Herdr while the current workspace is
    # still the parent repository workspace. Herdr's linked-worktree actions
    # reject a request made after the shell has already cd-ed into the checkout.
    local _open_in_herdr() {
      local worktree_dir="$1"
      herdr worktree open --workspace "$herdr_workspace" --path "$worktree_dir" --focus >/dev/null 2>&1
    }

    # Helper: Sanitize branch name for directory (replace / with -)
    # Place worktrees in the repository-local .worktrees directory.
    # Always resolve the main worktree so wt works correctly from inside a
    # linked worktree without nesting another .worktrees directory.
    local _sanitize_branch() {
      local repo_root=$(git worktree list --porcelain | sed -n 's/^worktree //p' | head -1)
      echo "''${repo_root}/.worktrees/''${1//\//-}"
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

    # Helper: Find the worktree where the base branch is checked out.
    local _find_base_worktree() {
      local base_branch="$1"
      git worktree list --porcelain |
        awk -v branch="refs/heads/$base_branch" '
          /^worktree / { path = substr($0, 10) }
          /^branch / && $2 == branch { print path; exit }
        '
    }

    # Helper: Update the base branch before creating a new branch.
    local _update_base_branch() {
      local base_branch="$1"
      local base_root=$(_find_base_worktree "$base_branch")

      if [[ -z "$base_root" ]]; then
        _error "Base branch is not checked out: $base_branch"
        return 1
      fi

      if [[ -n $(git -C "$base_root" status --porcelain 2>/dev/null) ]]; then
        _error "Base worktree has uncommitted changes: $base_root"
        return 1
      fi

      _msg "$BLUE" "Updating base branch '$base_branch'..."
      if ! git -C "$base_root" fetch origin; then
        _error "Failed to fetch origin"
        return 1
      fi
      if ! git -C "$base_root" pull --ff-only origin "$base_branch"; then
        _error "Failed to fast-forward '$base_branch'"
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

      if [[ "''${HERDR_ENV:-}" == "1" && -n "$herdr_workspace" ]]; then
        if git rev-parse --verify "$branch" >/dev/null 2>&1; then
          _msg "$BLUE" "Branch '$branch' already exists. Using existing branch through Herdr."
        else
          _msg "$GREEN" "Creating new branch '$branch' through Herdr (base: $base_branch)"
        fi
        herdr worktree create \
          --workspace "$herdr_workspace" \
          --branch "$branch" \
          --base "$base_branch" \
          --path "$worktree_dir" \
          --focus \
          2>&1
      elif git rev-parse --verify "$branch" >/dev/null 2>&1; then
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

    if [[ "''${HERDR_ENV:-}" == "1" && -n "$herdr_workspace" ]]; then
      _resolve_herdr_workspace || return 1
    fi

    local worktree_dir=$(_sanitize_branch "$branch_name")

    _check_worktree_exists "$worktree_dir" || return 1
    mkdir -p "$(dirname "$worktree_dir")"

    local base_branch=$(_find_base_branch)
    if [[ -z "$base_branch" ]]; then
      _error "No main or master branch found"
      return 1
    fi

    if [[ "$branch_existed" -eq 0 ]]; then
      _update_base_branch "$base_branch" || return 1
    fi

    local create_error
    if ! create_error=$(_create_worktree "$branch_name" "$worktree_dir" "$base_branch"); then
      # If branch is already checked out in another worktree, jump there.
      local existing_worktree=$(_handle_existing_worktree "$create_error")
      if [[ -n "$existing_worktree" ]]; then
        _msg "$YELLOW" "Warning: branch '$branch_name' is already checked out at $existing_worktree"
        _msg "$BLUE" "Switching to existing worktree instead."
        if [[ "''${HERDR_ENV:-}" == "1" && -n "$herdr_workspace" ]]; then
          _open_in_herdr "$existing_worktree" || return 1
        else
          cd "$existing_worktree"
        fi
        return 0
      fi

      # Try to handle hierarchical ref conflict
      local resolved_branch=$(_handle_ref_conflict "$branch_name" "$create_error")
      if [[ -n "$resolved_branch" ]]; then
        branch_name="$resolved_branch"
        branch_existed=1
        worktree_dir=$(_sanitize_branch "$resolved_branch")
        _check_worktree_exists "$worktree_dir" || return 1

        local resolved_error
        if ! resolved_error=$(_create_worktree "$resolved_branch" "$worktree_dir" "$base_branch"); then
          _error "Failed to create worktree"
          echo "$resolved_error" >&2
          return 1
        fi
      else
        if [[ "''${HERDR_ENV:-}" == "1" && -n "$herdr_workspace" && "$branch_existed" -eq 0 && "$create_error" == *'"code":"worktree_open_failed"'* ]]; then
          git worktree remove --force "$worktree_dir" >/dev/null 2>&1 || true
          git branch -D "$branch_name" >/dev/null 2>&1 || true
        fi
        _error "Failed to create worktree"
        echo "$create_error" >&2
        return 1
      fi
    fi

    _msg "$GREEN" "Worktree created: $worktree_dir"
    if [[ "''${HERDR_ENV:-}" == "1" && -n "$herdr_workspace" ]]; then
      :
    else
      cd "$worktree_dir"
    fi

    # Opportunistic cleanup: reclaim store space left behind by previously
    # removed worktrees. Detached background run, so it never blocks the
    # new worktree. Concurrent GC is safe — live builds and devshells are
    # protected by temp roots.
    (nix store gc >/dev/null 2>&1 &)
  }
''
