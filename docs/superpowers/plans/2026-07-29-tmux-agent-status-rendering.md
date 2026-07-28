# tmux Agent Status Rendering Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render bstack `me` plugin agent state in tmux window labels and a server-wide `status-right` summary without Herdr.

**Architecture:** A small Bash program counts pane-local `@agent_status` values by querying tmux once. Home Manager packages that program and references its immutable path from the existing pre-Continuum `status-right`; tmux formats map the same semantic option to glyphs in window labels.

**Tech Stack:** Nix, Home Manager, Bash, tmux formats

## Global Constraints

- Herdr and its Nix input/package/configuration must not be referenced.
- The only state input is pane-local `@agent_status`.
- State glyphs are exactly `running=●`, `needs_input=▲`, `ready=○`, `error=✕`.
- Summary order is exactly `●N ▲N ○N ✕N`, omitting zero-count and unknown states.
- The existing OSC `pane_title` and window-name fallback must remain intact.
- The one `status-right` assignment must remain before Continuum loads and must retain `%d/%m` and `%H:%M`.
- The summary must not inspect transcripts, processes, pane contents, titles, or state files.
- Follow strict RED→GREEN TDD and touch only tmux configuration and its tests.

---

### Task 1: Add semantic agent status rendering and aggregation

**Files:**
- Create: `users/shared/programs/tmux-agent-status-summary.sh`
- Modify: `users/shared/programs/tmux.nix`
- Modify: `tests/integration/tmux-functionality-test.nix`

**Interfaces:**
- Consumes: `tmux list-panes -a -F '#{@agent_status}'`.
- Produces: a compact summary string and window-list glyphs.

- [ ] **Step 1: Write failing behavior and configuration tests**

In `tests/integration/tmux-functionality-test.nix`, add:

```nix
agentStatusSummarySource =
  toString ../../users/shared/programs + "/tmux-agent-status-summary.sh";
fakeAgentStatusTmux = pkgs.writeShellScriptBin "tmux" ''
  if [ "$1" = "list-panes" ]; then
    printf '%s\n' running ready running needs_input error unknown ""
    exit 0
  fi
  exit 1
'';
```

Add a `pkgs.runCommand` test that runs the real source with
`PATH=${fakeAgentStatusTmux}/bin` and asserts its stdout is exactly:

```text
●2 ▲1 ○1 ✕1
```

Add a second fake tmux that exits 1 and assert the script exits 0 with empty
stdout. Add config assertions proving:

- both window status formats contain `#{@agent_status}`;
- both still contain `#{pane_title}` and the `#W` fallback;
- generated `status-right` contains `tmux-agent-status-summary`, `%d/%m`, and
  `%H:%M`;
- generated config contains exactly one `set -g status-right`;
- that line remains before the `tmuxplugin-continuum` marker.

- [ ] **Step 2: Run focused checks and verify RED**

Run the new summary/config checks with:

```bash
env USER="$(id -un)" nix build \
  '.#checks.aarch64-darwin.integration-tmux-functionality-tmux-agent-status-summary' \
  '.#checks.aarch64-darwin.integration-tmux-functionality-tmux-agent-status-window-format' \
  --impure --accept-flake-config
```

Expected: FAIL because the summary source and agent-status formats do not
exist. Confirm the failures name those missing behaviors.

- [ ] **Step 3: Implement the summary program**

Create `users/shared/programs/tmux-agent-status-summary.sh` with:

```bash
set -euo pipefail

command -v tmux >/dev/null 2>&1 || exit 0
states="$(tmux list-panes -a -F '#{@agent_status}' 2>/dev/null)" || exit 0

running=0
needs_input=0
ready=0
error=0

while IFS= read -r state; do
    case "$state" in
        running) ((running += 1)) ;;
        needs_input) ((needs_input += 1)) ;;
        ready) ((ready += 1)) ;;
        error) ((error += 1)) ;;
    esac
done <<<"$states"

parts=()
((running > 0)) && parts+=("●$running")
((needs_input > 0)) && parts+=("▲$needs_input")
((ready > 0)) && parts+=("○$ready")
((error > 0)) && parts+=("✕$error")

if ((${#parts[@]} > 0)); then
    printf '%s\n' "${parts[*]}"
fi
```

- [ ] **Step 4: Package and render the status**

In `users/shared/programs/tmux.nix`, extend the existing `let` with:

```nix
agentStatusSummary = pkgs.writeShellApplication {
  name = "tmux-agent-status-summary";
  runtimeInputs = [ pkgs.tmux ];
  text = builtins.readFile ./tmux-agent-status-summary.sh;
};
agentStatusGlyph = "#{?#{==:#{@agent_status},running},●,#{?#{==:#{@agent_status},needs_input},▲,#{?#{==:#{@agent_status},ready},○,#{?#{==:#{@agent_status},error},✕,}}}}";
```

Prepend this command to the existing Continuum `status-right` value:

```tmux
#(${agentStatusSummary}/bin/tmux-agent-status-summary)
```

Keep the date/time styling in the same assignment. Insert
`${agentStatusGlyph}` immediately after `#I` in both window status formats.
Do not change their existing `pane_title` and `#W` conditional.

- [ ] **Step 5: Run focused verification and verify GREEN**

Run:

```bash
nix fmt
env USER="$(id -un)" nix build \
  '.#checks.aarch64-darwin.integration-tmux-functionality-tmux-agent-status-summary' \
  '.#checks.aarch64-darwin.integration-tmux-functionality-tmux-agent-status-window-format' \
  '.#checks.aarch64-darwin.integration-tmux-functionality-tmux-continuum-config-order' \
  --impure --accept-flake-config
```

Expected: all derivations build and formatting produces no unrelated changes.

- [ ] **Step 6: Run the full baseline-equivalent suite**

Run:

```bash
env USER="$(id -un)" make test
```

Expected: validation completes successfully with exit code 0.

- [ ] **Step 7: Commit**

```bash
git add users/shared/programs/tmux-agent-status-summary.sh \
  users/shared/programs/tmux.nix \
  tests/integration/tmux-functionality-test.nix
git commit -m "feat(tmux): show coding agent status"
```
