#!/bin/bash
# Make sure this file is executable: chmod +x ~/.claude/statusline-command.sh

# Claude Code statusline script
# Reads JSON input from stdin and outputs a formatted status line to stdout
#
# Add to your ~/.claude/settings.json
#
# "statusLine": {
#   "type": "command",
#   "command": "bash ~/.claude/statusline-command.sh"
# }
#
# SYMBOL LEGEND:
# 🤖 Model indicator
# 📁 Current directory
# Git information:
#   +N Staged files count (green)
#   ~N Modified files count (yellow)
#   ?N Untracked files count (gray)
#   ↑N Commits ahead of remote (green)
#   ↓N Commits behind remote (yellow)
#   ↕N/M Diverged from remote (yellow)
#   PR#N Open pull request number (cyan)
# 🌳 Git worktree indicator
# 🕐 Current time

# Color codes for better visual separation
readonly BLUE='\033[94m'      # Bright blue for model/main info
readonly GREEN='\033[92m'     # Bright green for clean git status
readonly YELLOW='\033[93m'    # Bright yellow for modified git status
readonly RED='\033[91m'       # Bright red for conflicts/errors
readonly PURPLE='\033[95m'    # Bright purple for directory
readonly CYAN='\033[96m'      # Bright cyan for python venv
readonly GRAY='\033[37m'      # Gray for separators
readonly RESET='\033[0m'      # Reset colors
readonly BOLD='\033[1m'       # Bold text

# Read JSON input from stdin
input=$(cat)

# Extract data from JSON input using single jq call for performance
# Use tab as IFS to handle spaces in model names correctly
IFS=$'\t' read -r model_name current_dir <<< "$(echo "$input" | jq -r '[
    .model.display_name // "Claude",
    .workspace.current_dir // "."
] | @tsv')"

# Calculate context and cache info from JSON input
# See: code.claude.com/docs/en/statusline
# Note: current_usage fields are not in official docs but may be provided
ctx_display=""
usage=$(echo "$input" | jq '.context_window.current_usage // empty')
if [[ -n "$usage" && "$usage" != "null" ]]; then
    input_tokens=$(echo "$usage" | jq '.input_tokens // 0')
    cache_read=$(echo "$usage" | jq '.cache_read_input_tokens // 0')
    cache_creation=$(echo "$usage" | jq '.cache_creation_input_tokens // 0')

    # Total context length
    context_length=$((input_tokens + cache_read + cache_creation))

    # Format helper function
    format_tokens() {
        local val=$1
        if [[ "$val" -ge 1000 ]]; then
            echo "$((val / 1000))k"
        else
            echo "$val"
        fi
    }

    # Build context display: "20k" format
    if [[ "$context_length" -gt 0 ]]; then
        ctx_display=$(format_tokens "$context_length")
    fi
fi

# Get current directory relative to home directory
if [[ "$current_dir" == "$HOME"* ]]; then
    # Replace home path with ~ for display
    dir_display="~${current_dir:${#HOME}}"
else
    # Keep full path if not under home directory
    dir_display="$current_dir"
fi
# Get git status and worktree information with enhanced detection
git_info=""
git_dir=$(git -C "$current_dir" rev-parse --git-dir 2>/dev/null)
if [[ -n "$git_dir" ]]; then
    branch=$(git -C "$current_dir" branch --show-current 2>/dev/null)

    # If no branch (detached HEAD), show short commit hash
    if [[ -z "$branch" ]]; then
        branch=$(git -C "$current_dir" rev-parse --short HEAD 2>/dev/null)
        branch="detached:${branch}"
    fi

    # Enhanced worktree detection
    worktree_info=""

    # Check if we're in a worktree
    if [[ "$git_dir" == *".git/worktrees/"* ]] || [[ -f "$git_dir/gitdir" ]]; then
        worktree_name=$(basename "$current_dir")
        # Only show worktree indicator if it adds information
        # Don't show if branch name already contains the worktree info
        if [[ "$worktree_name" =~ ^TOK ]] && [[ "$branch" != *"$worktree_name"* ]]; then
            # For TOK worktrees, just show the tree emoji
            worktree_info=" ${CYAN}🌳${RESET}"
        elif [[ ! "$worktree_name" =~ ^TOK ]] && [[ "$branch" != "$worktree_name" ]]; then
            # For other worktrees, just show tree emoji
            worktree_info=" ${CYAN}🌳${RESET}"
        fi
    fi

    if [[ -n "$branch" ]]; then
        # Comprehensive git status check
        # Git status format: XY filename
        # X = status of staging area, Y = status of working tree
        git_status=$(git --no-optional-locks -C "$current_dir" status --porcelain 2>/dev/null)

        # Count different types of changes (handle empty status gracefully)
        if [[ -n "$git_status" ]]; then
            # Use awk for single-pass counting (avoids grep -c exit code issues)
            read -r untracked modified staged conflicts <<< "$(echo "$git_status" | awk '
                BEGIN {u=0; m=0; s=0; c=0}
                /^\?\?/ {u++}
                /^.M|^ M/ {m++}
                /^[ADMR]/ {s++}
                /^UU|^AA|^DD/ {c++}
                END {print u, m, s, c}
            ')"
        else
            untracked=0
            modified=0
            staged=0
            conflicts=0
        fi

        # Debug output
        if [[ "$DEBUG" == "1" ]]; then
            echo "DEBUG: Git Status Raw:" >&2
            echo "$git_status" >&2
            echo "DEBUG: Counts - Staged:$staged Modified:$modified Untracked:$untracked Conflicts:$conflicts" >&2
        fi

        # Check for ahead/behind status with timeout to prevent hanging on slow repos
        ahead_behind=""
        upstream=$(git -C "$current_dir" rev-parse --abbrev-ref '@{u}' 2>/dev/null)
        if [[ -n "$upstream" ]]; then
            # Use timeout to prevent slow git operations from blocking status line
            counts=$(timeout 0.5s git -C "$current_dir" rev-list --left-right --count '@{u}...HEAD' 2>/dev/null)
            if [[ $? -eq 124 ]]; then
                # Timeout occurred
                ahead_behind=" ${GRAY}(checking...)${RESET}"
            elif [[ -n "$counts" ]]; then
                read -r ahead behind <<< "$counts"
                if [[ "$ahead" -gt 0 ]] && [[ "$behind" -gt 0 ]]; then
                    ahead_behind=" ${YELLOW}↕${ahead}/${behind}${RESET}"
                elif [[ "$ahead" -gt 0 ]]; then
                    ahead_behind=" ${GREEN}↑${ahead}${RESET}"
                elif [[ "$behind" -gt 0 ]]; then
                    ahead_behind=" ${YELLOW}↓${behind}${RESET}"
                fi
            fi
        fi

        # Build GitHub base URL from remote (used for branch and PR links)
        github_base_url=""
        remote_url=$(git -C "$current_dir" config --get remote.origin.url 2>/dev/null)
        if [[ "$remote_url" == *"github.com"* ]]; then
            # Normalize SSH (git@github.com:owner/repo.git) and HTTPS URLs to https://github.com/owner/repo
            github_base_url=$(echo "$remote_url" | sed -E \
                's|git@github\.com:|https://github.com/|;s|\.git$||;s|https://github\.com/(.+)\.git|\1|')
            # Ensure it starts with https://
            if [[ "$github_base_url" != https://* ]]; then
                github_base_url="https://github.com/${github_base_url#https://github.com/}"
            fi
        fi

        # Make branch name a clickable OSC 8 hyperlink if we have a GitHub URL
        if [[ -n "$github_base_url" && "$branch" != detached:* ]]; then
            branch_url="${github_base_url}/tree/${branch}"
            branch_link=$'\e]8;;'"${branch_url}"$'\e\\'"${branch}"$'\e]8;;\e\\'
        else
            branch_link="${branch}"
        fi

        # Check for open PRs using GitHub CLI if available
        pr_info=""
        if command -v gh >/dev/null 2>&1; then
            if [[ "$remote_url" == *"github.com"* ]]; then
                # Quick PR check with timeout to prevent hanging
                # gh has internal caching, so this is fast after first run
                pr_json=$(timeout 0.5 gh pr view --json number,url 2>/dev/null || echo "")
                if [[ -n "$pr_json" ]]; then
                    pr_number=$(echo "$pr_json" | jq -r '.number // empty')
                    pr_url=$(echo "$pr_json" | jq -r '.url // empty')
                    if [[ -n "$pr_number" && -n "$pr_url" ]]; then
                        # OSC 8 hyperlink using $'\e' for literal ESC byte
                        # RESET must also use literal ESC byte since pr_link contains real ESC bytes
                        pr_link=$'\e]8;;'"${pr_url}"$'\e\\''PR#'"${pr_number}"$'\e]8;;\e\\'
                        pr_info=" ${CYAN}${pr_link}"$'\033[0m'
                    fi
                fi
            fi
        fi

        # Get git diff stats for insertions/deletions
        insertions=0
        deletions=0
        if [[ -n "$git_status" ]]; then
            # Get diff stats using --numstat for accurate counts
            diff_stats=$(git --no-optional-locks -C "$current_dir" diff --numstat 2>/dev/null)
            if [[ -n "$diff_stats" ]]; then
                insertions=$(echo "$diff_stats" | awk '{sum+=$1} END {print sum+0}')
                deletions=$(echo "$diff_stats" | awk '{sum+=$2} END {print sum+0}')
            fi

            # Also check staged changes
            staged_stats=$(git --no-optional-locks -C "$current_dir" diff --cached --numstat 2>/dev/null)
            if [[ -n "$staged_stats" ]]; then
                staged_insertions=$(echo "$staged_stats" | awk '{sum+=$1} END {print sum+0}')
                staged_deletions=$(echo "$staged_stats" | awk '{sum+=$2} END {print sum+0}')
                insertions=$((insertions + staged_insertions))
                deletions=$((deletions + staged_deletions))
            fi
        fi

        # Build git diff indicator (+X,-Y)
        git_diff_indicator=""
        if [[ "$insertions" -gt 0 ]] || [[ "$deletions" -gt 0 ]]; then
            git_diff_indicator=" ${GRAY}│${RESET} ${GREEN}+${insertions}${RESET},${RED}-${deletions}${RESET}"
        fi

        # Set git color based on status (without icons)
        if [[ "$conflicts" -gt 0 ]]; then
            git_color="${RED}"
        elif [[ -n "$git_status" ]]; then
            git_color="${YELLOW}"
        else
            git_color="${GREEN}"
        fi

        # Construct git info string with separate sections (no icon)
        # branch_link may contain literal ESC bytes (OSC 8), so RESET uses $'\033[0m'
        git_branch_info="${git_color}${branch_link}"$'\033[0m'"${worktree_info}${ahead_behind}${pr_info}"

        # Always show branch and git diff indicator if present
        git_info=" ${GRAY}│${RESET} ${git_branch_info}${git_diff_indicator}"
    fi
fi

# Build output string
# Only show context if available
if [[ -n "$ctx_display" ]]; then
    output_string="${BOLD}${BLUE}${model_name}${RESET} ${GRAY}│${RESET} ${CYAN}${ctx_display}${RESET} ${GRAY}│${RESET} ${PURPLE}${dir_display}${RESET}"
else
    output_string="${BOLD}${BLUE}${model_name}${RESET} ${GRAY}│${RESET} ${PURPLE}${dir_display}${RESET}"
fi

# Add git info if available
if [[ -n "$git_info" ]]; then
    output_string="${output_string}${git_info}"
fi

# Output the complete string
echo -e "$output_string"
