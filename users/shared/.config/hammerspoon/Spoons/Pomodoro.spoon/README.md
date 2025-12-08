# Pomodoro.spoon

A simple Pomodoro timer for Hammerspoon with manual control.

## Features

- **25-minute work sessions** followed by **5-minute breaks**
- **Menubar countdown display** with emoji indicators (🍅 for work, ☕ for break)
- **Daily statistics tracking** stored in Hammerspoon settings
- **Manual control** via hotkeys

## Installation

1. Copy the `Pomodoro.spoon` directory to your Hammerspoon Spoons folder
2. Add to your Hammerspoon configuration:

```lua
hs.loadSpoon("Pomodoro")
spoon.Pomodoro:start()
```

## Usage

### Basic Usage

```lua
-- Load and start
hs.loadSpoon("Pomodoro")
spoon.Pomodoro:start()
```

### With Hotkeys

```lua
hs.loadSpoon("Pomodoro")
spoon.Pomodoro:bindHotkeys({
  start = {{"ctrl", "cmd"}, "p"},
  stop = {{"ctrl", "cmd"}, "s"},
  toggle = {{"ctrl", "cmd"}, "t"}
})
spoon.Pomodoro:start()
```

### Manual Control

```lua
-- Start a session
spoon.Pomodoro:startSession()

-- Stop current session
spoon.Pomodoro:stopSession()

-- Toggle between start/stop
spoon.Pomodoro:toggleSession()
```

### Getting Statistics

```lua
local stats = spoon.Pomodoro:getStatistics()
print("Today's sessions:", stats.today)
```

## API Reference

### Methods

- `start()` - Initialize and start the spoon
- `stop()` - Stop the spoon and clean up resources
- `bindHotkeys(mapping)` - Bind hotkeys for control
- `startSession()` - Start a work session
- `stopSession()` - Stop the current session
- `toggleSession()` - Toggle between start/stop
- `getStatistics()` - Get daily statistics

## Configuration

Constants can be modified in `init.lua`:

```lua
local WORK_DURATION = 25 * 60  -- Work session in seconds
local BREAK_DURATION = 5 * 60  -- Break duration in seconds
```

## Storage

Statistics are stored in Hammerspoon settings under the key `pomodoro.stats`.

## License

MIT License - see LICENSE file for details.