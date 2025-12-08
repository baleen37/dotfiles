# Pomodoro Spoon Design Document

## Overview
A Hammerspoon Spoon that implements a Pomodoro timer with automatic Focus mode integration.

## Requirements
- Automatic start when macOS Focus mode changes to "Pomodoro"
- 25-minute work session followed by 5-minute break
- Automatic stop when Focus mode is changed away from "Pomodoro"
- Menubar integration with real-time countdown display
- Daily statistics tracking

## Architecture
```
/Users/jito.hello/dotfiles/users/shared/.config/hammerspoon/Spoons/Pomodoro.spoon/
├── init.lua      # Complete implementation
└── docs.json     # API documentation
```

## Design Decisions
- Single-file architecture (inspired by Cherry.spoon)
- Focus mode integration using hs.focus
- One-cycle-per-session approach (no automatic restart after break)
- State management with clear transitions

## State Management
- `timerRunning`: Whether timer is active
- `isBreak`: Whether in break period
- `sessionsCompleted`: Daily session count
- `timeLeft`: Seconds remaining
- `sessionStartTime`: When current session started

## User Interface
- Menu bar shows: "🍅 24:15" during work, "☕ 04:15" during break
- Click menu for: Stop/Reset, statistics, session info
- Notifications for session completion

## Integration Points
- Loaded via hs.loadSpoon('Pomodoro') in init.lua
- Works alongside existing Hyper.spoon and HyperModal.spoon
- No conflicts with current hotkey bindings