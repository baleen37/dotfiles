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
readonly BLUE=$'\033[94m'      # Bright blue for model/main info
readonly GREEN=$'\033[92m'     # Bright green for clean git status
readonly YELLOW=$'\033[93m'    # Bright yellow for modified git status
readonly RED=$'\033[91m'       # Bright red for conflicts/errors
readonly PURPLE=$'\033[95m'    # Bright purple for directory
readonly CYAN=$'\033[96m'      # Bright cyan for python venv
readonly GRAY=$'\033[37m'      # Gray for separators
readonly RESET=$'\033[0m'      # Reset colors
readonly BOLD=$'\033[1m'       # Bold text

# Fallback for `timeout`: macOS has no built-in timeout and Claude Code's
# shell snapshot PATH may omit coreutils on some accounts.
if ! command -v timeout >/dev/null 2>&1; then
    timeout() { shift; "$@"; }
fi

# Read JSON input from stdin
input=$(cat)

# Login indicator: show email local part (before @) in green
login_indicator=""
whoami_json=$(timeout 0.5 claude auth status 2>/dev/null || echo "")
if [[ -n "$whoami_json" ]]; then
    email=$(echo "$whoami_json" | jq -r '.email // empty')
    if [[ -n "$email" ]]; then
        email_local="${email%%@*}"
        login_indicator="${GREEN}${email_local}${RESET} ${GRAY}│${RESET} "
    fi
fi

# Extract data from JSON input using single jq call for performance
# Use tab as IFS to handle spaces in model names correctly
IFS=$'\t' read -r model_name current_dir <<< "$(echo "$input" | jq -r '[
    .model.display_name // "Claude",
    .workspace.current_dir // "."
] | @tsv')"

# Calculate context info from JSON input
# See: code.claude.com/docs/en/statusline
ctx_display=""
context_length=$(echo "$input" | jq -r '
    .context_window.current_usage as $cu |
    if $cu == null or ($cu | length) == 0 then
        .context_window.total_input_tokens // 0
    else
        (($cu.input_tokens // 0) + ($cu.cache_read_input_tokens // 0) + ($cu.cache_creation_input_tokens // 0)) as $sum |
        if $sum == 0 then
            .context_window.total_input_tokens // 0
        else
            $sum
        end
    end
' 2>/dev/null)

if [[ -n "$context_length" && "$context_length" -gt 0 ]]; then
    if [[ "$context_length" -ge 1000 ]]; then
        ctx_display="$((context_length / 1000))k"
    else
        ctx_display="$context_length"
    fi
fi

# Get current directory relative to home directory
if [[ "$current_dir" == "$HOME"* ]]; then
    dir_display="~${current_dir:${#HOME}}"
else
    dir_display="$current_dir"
fi

# Git info
git_info=""
git_dir=$(git -C "$current_dir" rev-parse --git-dir 2>/dev/null)
if [[ -n "$git_dir" ]]; then
    branch=$(git -C "$current_dir" branch --show-current 2>/dev/null)

    if [[ -z "$branch" ]]; then
        branch=$(git -C "$current_dir" rev-parse --short HEAD 2>/dev/null)
        branch="detached:${branch}"
    fi

    # Worktree detection
    worktree_info=""
    if [[ "$git_dir" == *".git/worktrees/"* ]] || [[ -f "$git_dir/gitdir" ]]; then
        worktree_name=$(basename "$current_dir")
        if [[ "$worktree_name" =~ ^TOK ]] && [[ "$branch" != *"$worktree_name"* ]]; then
            worktree_info=" ${CYAN}🌳${RESET}"
        elif [[ ! "$worktree_name" =~ ^TOK ]] && [[ "$branch" != "$worktree_name" ]]; then
            worktree_info=" ${CYAN}🌳${RESET}"
        fi
    fi

    # Git status
    git_status=$(git --no-optional-locks -C "$current_dir" status --porcelain 2>/dev/null)

    if [[ -n "$git_status" ]]; then
        read -r untracked modified staged conflicts <<< "$(echo "$git_status" | awk '
            BEGIN {u=0; m=0; s=0; c=0}
            /^\?\?/ {u++}
            /^.M|^ M/ {m++}
            /^[ADMR]/ {s++}
            /^UU|^AA|^DD/ {c++}
            END {print u, m, s, c}
        ')"
    else
        untracked=0; modified=0; staged=0; conflicts=0
    fi

    # Ahead/behind
    ahead_behind=""
    upstream=$(git -C "$current_dir" rev-parse --abbrev-ref '@{u}' 2>/dev/null)
    if [[ -n "$upstream" ]]; then
        counts=$(timeout 0.5s git -C "$current_dir" rev-list --left-right --count '@{u}...HEAD' 2>/dev/null)
        if [[ $? -eq 124 ]]; then
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

    # GitHub URL and OSC 8 branch link
    ESC=$'\033'
    ST="${ESC}\\"
    remote_url=$(git -C "$current_dir" config --get remote.origin.url 2>/dev/null)
    github_base_url=""
    if [[ "$remote_url" == *"github.com"* ]]; then
        github_base_url=$(echo "$remote_url" | sed -E \
            's|git@github\.com:|https://github.com/|;s|\.git$||;s|https://github\.com/(.+)\.git|\1|')
        if [[ "$github_base_url" != https://* ]]; then
            github_base_url="https://github.com/${github_base_url#https://github.com/}"
        fi
    fi

    if [[ -n "$github_base_url" && "$branch" != detached:* ]]; then
        branch_url="${github_base_url}/tree/${branch}"
        branch_link="${ESC}]8;;${branch_url}${ST}${branch}${ESC}]8;;${ST}"
    else
        branch_link="${branch}"
    fi

    # PR info
    pr_info=""
    if command -v gh >/dev/null 2>&1 && [[ "$remote_url" == *"github.com"* ]]; then
        pr_json=$(timeout 0.5 gh pr view --json number,url 2>/dev/null || echo "")
        if [[ -n "$pr_json" ]]; then
            pr_number=$(echo "$pr_json" | jq -r '.number // empty')
            pr_url=$(echo "$pr_json" | jq -r '.url // empty')
            if [[ -n "$pr_number" && -n "$pr_url" ]]; then
                pr_link="${ESC}]8;;${pr_url}${ST}PR#${pr_number}${ESC}]8;;${ST}"
                pr_info=" ${CYAN}${pr_link}${RESET}"
            fi
        fi
    fi

    # Git color
    if [[ "$conflicts" -gt 0 ]]; then
        git_color="${RED}"
    elif [[ -n "$git_status" ]]; then
        git_color="${YELLOW}"
    else
        git_color="${GREEN}"
    fi

    git_branch_info="${git_color}${branch_link}"$'\033[0m'"${worktree_info}${ahead_behind}${pr_info}"
    git_info=" ${GRAY}│${RESET} ${git_branch_info}"
fi

# Build output string
if [[ -n "$ctx_display" ]]; then
    output_string="${login_indicator}${BOLD}${BLUE}${model_name}${RESET} ${GRAY}│${RESET} ${CYAN}${ctx_display}${RESET} ${GRAY}│${RESET} ${PURPLE}${dir_display}${RESET}"
else
    output_string="${login_indicator}${BOLD}${BLUE}${model_name}${RESET} ${GRAY}│${RESET} ${PURPLE}${dir_display}${RESET}"
fi

if [[ -n "$git_info" ]]; then
    output_string="${output_string}${git_info}"
fi

printf '%s\n' "$output_string"
