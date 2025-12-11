# FocusTracker.spoon

FocusTracker는 macOS의 모든 Focus Mode를 추적하고 집중 시간을 실시간으로 표시하는 Hammerspoon Spoon입니다.

## Features

- 모든 Focus Mode 자동 추적
- 실시간 카운트업 타이머
- Menubar 경과 시간 표시 (🔵 25:30)
- 콜백 기반 알림 시스템

## Requirements

- macOS Sequoia (15.x) or later
- Hammerspoon
- Full Disk Access permission (권장)

## Installation

1. Copy `FocusTracker.spoon` to `~/.hammerspoon/Spoons/`
2. Add configuration to `~/.hammerspoon/init.lua`

## Usage

```lua
hs.loadSpoon("FocusTracker")

spoon.FocusTracker:init({
  onFocusStart = function(focusModeName)
    hs.alert.show("🔵 " .. focusModeName, 2)
  end,

  onFocusEnd = function(focusModeName, durationInSeconds)
    local minutes = math.floor(durationInSeconds / 60)
    local seconds = durationInSeconds % 60
    local timeStr = minutes == 0
      and string.format("%d초", seconds)
      or string.format("%d분 %d초", minutes, seconds)

    hs.alert.show(focusModeName .. "\n" .. timeStr, 3)
  end
}):start()
```

## API

- `FocusTracker:init(config)` - Configure callbacks
- `FocusTracker:start()` - Start tracking
- `FocusTracker:stop()` - Stop tracking

## License

MIT