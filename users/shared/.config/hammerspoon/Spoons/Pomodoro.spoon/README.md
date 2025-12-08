# Pomodoro.spoon

A robust Pomodoro timer for Hammerspoon with error handling, encapsulated state, and comprehensive testing.

## Features

- **25-minute work sessions** followed by **5-minute breaks**
- **Menubar countdown display** with emoji indicators (🍅 for work, ☕ for break)
- **Daily statistics tracking** stored in Hammerspoon settings
- **Error handling** for invalid inputs and timer failures
- **Encapsulated state management** (no global variables)
- **Comprehensive test coverage**
- **Input validation** for all timer operations

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

-- Start with custom duration (in seconds)
spoon.Pomodoro:startSessionWithDuration(1500)  -- 25 minutes

-- Stop current session
spoon.Pomodoro:stopSession()

-- Toggle between start/stop
spoon.Pomodoro:toggleSession()
```

### Getting Statistics

```lua
local stats = spoon.Pomodoro:getStatistics()
print("Today's sessions:", stats.today)
print("All statistics:", hs.inspect(stats.all))
```

### Settings Validation

```lua
-- Validate current settings
local isValid = spoon.Pomodoro:validateSettings()
if not isValid then
  print("Settings are invalid!")
end
```

## API Reference

### Methods

- `start()` - Initialize and start the spoon
- `stop()` - Stop the spoon and clean up resources
- `bindHotkeys(mapping)` - Bind hotkeys for control
- `startSession()` - Start a work session with default duration
- `startSessionWithDuration(duration)` - Start with custom duration
- `stopSession()` - Stop the current session
- `toggleSession()` - Toggle between start/stop
- `getStatistics()` - Get daily statistics
- `validateSettings()` - Validate timer settings

## Testing

Run the test suite:

```bash
# Run all tests
lua test/integration_test.lua

# Run specific test modules
lua test/utils_test.lua
lua test/state_manager_test.lua
lua test/ui_manager_test.lua
```

## Architecture

The spoon is organized into several modules:

- `init.lua` - Main spoon implementation and public API
- `state_manager.lua` - Encapsulates all timer state
- `ui_manager.lua` - Handles menubar updates
- `utils.lua` - Error handling and validation utilities

## Configuration

Constants can be modified in `init.lua`:

```lua
local WORK_DURATION = 25 * 60  -- Work session in seconds
local BREAK_DURATION = 5 * 60  -- Break duration in seconds
```

## Error Handling

The spoon includes robust error handling:

- Invalid durations are rejected with user notifications
- Timer creation failures are handled gracefully
- All operations include proper validation
- Error messages are logged to the Hammerspoon console

## Storage

Statistics are stored in Hammerspoon settings under the key `pomodoro.stats`.

## License

MIT License - see LICENSE file for details.