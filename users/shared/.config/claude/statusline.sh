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
# 🐍 Python virtual environment
# ⬢  Node.js version
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
IFS=$'\t' read -r model_name current_dir max_context transcript_path <<< "$(echo "$input" | jq -r '[
    .model.display_name // "Claude",
    .workspace.current_dir // ".",
    .context_window.context_window_size // 200000,
    .transcript_path // ""
] | @tsv')"

# Calculate context percentage from transcript (more accurate than JSON totals)
# See: github.com/anthropics/claude-code/issues/13652
if [[ -n "$transcript_path" && -f "$transcript_path" ]]; then
    # Get baseline (system prompt + tools + memory) from first message
    # and current context from last message
    IFS=$'\t' read -r baseline context_length <<< "$(jq -rs '
        map(select(.message.usage and .isSidechain != true and .isApiErrorMessage != true)) |
        [(first | if . then
            (.message.usage.input_tokens // 0) +
            (.message.usage.cache_read_input_tokens // 0) +
            (.message.usage.cache_creation_input_tokens // 0)
        else 20000 end),
        (last | if . then
            (.message.usage.input_tokens // 0) +
            (.message.usage.cache_read_input_tokens // 0) +
            (.message.usage.cache_creation_input_tokens // 0)
        else 0 end)] | @tsv
    ' < "$transcript_path" 2>/dev/null)"

    # If no messages yet, use baseline estimate
    if [[ -z "$baseline" || "$baseline" == "0" ]]; then
        baseline=20000
    fi
    if [[ -z "$context_length" || "$context_length" == "0" ]]; then
        context_length=$baseline
        pct_prefix="~"
    else
        pct_prefix=""
    fi
else
    # No transcript available - use baseline estimate
    baseline=20000
    context_length=$baseline
    pct_prefix="~"
fi

# Format context display as absolute value (e.g., "20k", "~20k")
if [[ "$context_length" -ge 1000 ]]; then
    ctx_k=$((context_length / 1000))
    ctx_display="${pct_prefix}${ctx_k}k"
else
    ctx_display="${pct_prefix}${context_length}"
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

        # Check for open PRs using GitHub CLI if available
        pr_info=""
        if command -v gh >/dev/null 2>&1; then
            # Only check for PRs if we're in a GitHub repo
            remote_url=$(git -C "$current_dir" config --get remote.origin.url 2>/dev/null)
            if [[ "$remote_url" == *"github.com"* ]]; then
                # Quick PR check with timeout to prevent hanging
                # gh has internal caching, so this is fast after first run
                pr_number=$(timeout 0.5 gh pr view --json number -q .number 2>/dev/null || echo "")
                if [[ -n "$pr_number" ]]; then
                    pr_info=" ${CYAN}PR#${pr_number}${RESET}"
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
        git_branch_info="${git_color}${branch}${RESET}${worktree_info}${ahead_behind}${pr_info}"

        # Always show branch and git diff indicator if present
        git_info=" ${GRAY}│${RESET} ${git_branch_info}${git_diff_indicator}"
    fi
fi

# Get Python virtual environment info
venv_info=""
if [[ -n "$VIRTUAL_ENV" ]]; then
    venv_name=$(basename "$VIRTUAL_ENV")
    venv_info=" ${GRAY}│${RESET} ${CYAN}🐍${venv_name}${RESET}"
fi

# Get Node.js version if in a Node project
node_info=""
if [[ -f "$current_dir/package.json" ]]; then
    node_version=$(node --version 2>/dev/null | sed 's/v//')
    if [[ -n "$node_version" ]]; then
        # Truncate to major.minor version
        node_version=${node_version%.*}
        node_info=" ${GRAY}│${RESET} ${GREEN}⬢ ${node_version}${RESET}"
    fi
fi

# Build simple linear output - always show all components
output_string="${BOLD}${BLUE}${model_name}${RESET} ${GRAY}│${RESET} ${CYAN}${ctx_display}${RESET} ${GRAY}│${RESET} ${PURPLE}${dir_display}${RESET}"

# Add git info if available
if [[ -n "$git_info" ]]; then
    output_string="${output_string}${git_info}"
fi

# Add venv info if available
if [[ -n "$venv_info" ]]; then
    output_string="${output_string}${venv_info}"
fi

# Add node info if available
if [[ -n "$node_info" ]]; then
    output_string="${output_string}${node_info}"
fi

# Output the complete string
echo -e "$output_string"
