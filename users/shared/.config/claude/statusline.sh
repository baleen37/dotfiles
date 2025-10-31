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
readonly WHITE='\033[97m'     # Bright white for time
readonly GRAY='\033[37m' # Gray for separators
readonly RESET='\033[0m'      # Reset colors
readonly BOLD='\033[1m'       # Bold text

# Read JSON input from stdin
input=$(cat)

# Extract data from JSON input using jq
model_name=$(echo "$input" | jq -r '.model.display_name // "Claude"')
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // "."')

# Extract context information using proper getTokenMetrics implementation
# Find the most recent main chain entry (where isSidechain !== true) and calculate context length
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')

if [[ -n "$transcript_path" && -f "$transcript_path" ]]; then
    # Read transcript file (JSONL format) and calculate context length
    # Each line is a separate JSON object, find the most recent main chain entry
    context_length=$(tac "$transcript_path" 2>/dev/null | while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            # Check if this line has isSidechain !== true and has message.usage
            is_main_chain=$(echo "$line" | jq -r 'if .isSidechain == true then "false" else "true" end' 2>/dev/null)
            has_usage=$(echo "$line" | jq -r 'if .message.usage then "true" else "false" end' 2>/dev/null)

            if [[ "$is_main_chain" == "true" && "$has_usage" == "true" ]]; then
                # Calculate context length from this entry
                echo "$line" | jq -r '
                    (.message.usage.input_tokens // 0) +
                    (.message.usage.cache_read_input_tokens // 0) +
                    (.message.usage.cache_creation_input_tokens // 0)
                ' 2>/dev/null
                break
            fi
        fi
    done)

    # If context_length is empty or null, set to 0
    if [[ -z "$context_length" || "$context_length" == "null" ]]; then
        context_length=0
    fi
else
    context_length=0
fi

# Fallback to simple context.length if transcript parsing fails
if [[ "$context_length" == "null" || "$context_length" == "0" || -z "$context_length" ]]; then
    context_length=$(echo "$input" | jq -r '.context.length // 0')
fi

# Format context length (e.g., 18.6k)
if [[ "$context_length" -ge 1000 ]]; then
    ctx_display=$(awk "BEGIN {printf \"%.1fk\", $context_length/1000}")
else
    ctx_display="$context_length"
fi

# Get current directory relative to home directory
if [[ "$current_dir" == "$HOME"* ]]; then
    # Replace home path with ~ for display
    dir_display="${current_dir/#$HOME/~}"
else
    # Keep full path if not under home directory
    dir_display="$current_dir"
fi
# Get git status and worktree information with enhanced detection
git_info=""
if git -C "$current_dir" rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git -C "$current_dir" branch --show-current 2>/dev/null)

    # If no branch (detached HEAD), show short commit hash
    if [[ -z "$branch" ]]; then
        branch=$(git -C "$current_dir" rev-parse --short HEAD 2>/dev/null)
        branch="detached:${branch}"
    fi

    # Enhanced worktree detection
    worktree_info=""
    git_dir=$(git -C "$current_dir" rev-parse --git-dir 2>/dev/null)

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
            # Count untracked files (starts with ??)
            untracked=$(echo "$git_status" | grep -c '^??')
            # Count modified files (M in second column or first column with space)
            modified=$(echo "$git_status" | grep -c '^.M\|^ M')
            # Count staged files (non-space in first column, excluding ??)
            staged=$(echo "$git_status" | grep -c '^[ADMR]')
            # Count conflicts (UU, AA, DD)
            conflicts=$(echo "$git_status" | grep -c '^UU\|^AA\|^DD')
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

        # Check for ahead/behind status
        ahead_behind=""
        upstream=$(git -C "$current_dir" rev-parse --abbrev-ref '@{u}' 2>/dev/null)
        if [[ -n "$upstream" ]]; then
            ahead=$(git -C "$current_dir" rev-list --count '@{u}..HEAD' 2>/dev/null)
            behind=$(git -C "$current_dir" rev-list --count 'HEAD..@{u}' 2>/dev/null)

            if [[ "$ahead" -gt 0 ]] && [[ "$behind" -gt 0 ]]; then
                ahead_behind=" ${YELLOW}↕${ahead}/${behind}${RESET}"
            elif [[ "$ahead" -gt 0 ]]; then
                ahead_behind=" ${GREEN}↑${ahead}${RESET}"
            elif [[ "$behind" -gt 0 ]]; then
                ahead_behind=" ${YELLOW}↓${behind}${RESET}"
            fi
        fi

        # Check for open PRs using GitHub CLI if available
        pr_info=""
        if command -v gh >/dev/null 2>&1; then
            # Only check for PRs if we're in a GitHub repo
            remote_url=$(git -C "$current_dir" config --get remote.origin.url 2>/dev/null)
            if [[ "$remote_url" == *"github.com"* ]]; then
                # Quick PR check (gh caches this, so it's usually fast after first run)
                pr_number=$(gh pr view --json number -q .number 2>/dev/null)
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

# Get current time
current_time="$(date '+%H:%M')"

# Build simple linear output - always show all components
output_string=" ${BOLD}${BLUE}${model_name}${RESET} ${GRAY}│${RESET} ${CYAN}Ctx: ${ctx_display}${RESET} ${GRAY}│${RESET} ${PURPLE}${dir_display}${RESET}"

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

# Add time
output_string="${output_string} ${GRAY}│${RESET} ${WHITE}${current_time}${RESET} "

# Output the complete string
echo -e "$output_string"
