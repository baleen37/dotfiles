require('hs.ipc')
hs.allowAppleScript(true)
hs.loadSpoon('Hyper')
hs.loadSpoon('Pomodoro')
hs.loadSpoon('VimImeGuard')


Hyper = spoon.Hyper

-- Window management replaces Magnet. Switch handles Cmd-Tab window switching;
-- these bindings keep the common tiling operations local to Hammerspoon.
local windowHotkeyMods = { 'cmd', 'ctrl', 'shift' }
local windowAnimationDuration = 0
local windowUnits = {
  left = hs.geometry.new(0, 0, 0.5, 1),
  right = hs.geometry.new(0.5, 0, 0.5, 1),
  top = hs.geometry.new(0, 0, 1, 0.5),
  bottom = hs.geometry.new(0, 0.5, 1, 0.5),
  leftTwoThirds = hs.geometry.new(0, 0, 2 / 3, 1),
  rightTwoThirds = hs.geometry.new(1 / 3, 0, 2 / 3, 1),
  fill = hs.geometry.new(0, 0, 1, 1),
}

local function isWindowInUnit(window, unit)
  local screenFrame = window:screen():frame()
  local frame = window:frame()
  local epsilon = 2
  local expected = {
    x = screenFrame.x + screenFrame.w * unit.x,
    y = screenFrame.y + screenFrame.h * unit.y,
    w = screenFrame.w * unit.w,
    h = screenFrame.h * unit.h,
  }

  return math.abs(frame.x - expected.x) < epsilon
    and math.abs(frame.y - expected.y) < epsilon
    and math.abs(frame.w - expected.w) < epsilon
    and math.abs(frame.h - expected.h) < epsilon
end

local function moveWindowToUnit(unit)
  local window = hs.window.focusedWindow()
  if window then
    window:moveToUnit(unit, windowAnimationDuration)
  end
end

local function moveWindowHorizontally(unit, direction)
  local window = hs.window.focusedWindow()
  if not window then
    return
  end

  local screen = window:screen()
  if isWindowInUnit(window, unit) then
    local nextScreen = direction == 'west'
      and screen:toWest(nil, true)
      or screen:toEast(nil, true)
    if nextScreen then
      window:moveToScreen(nextScreen, false, true, windowAnimationDuration)
    end
  end

  window:moveToUnit(unit, windowAnimationDuration)
end

hs.hotkey.bind(windowHotkeyMods, 'left', function()
  moveWindowHorizontally(windowUnits.left, 'west')
end)
hs.hotkey.bind(windowHotkeyMods, 'right', function()
  moveWindowHorizontally(windowUnits.right, 'east')
end)
hs.hotkey.bind(windowHotkeyMods, 'up', function()
  moveWindowToUnit(windowUnits.top)
end)
hs.hotkey.bind(windowHotkeyMods, 'down', function()
  moveWindowToUnit(windowUnits.bottom)
end)
hs.hotkey.bind(windowHotkeyMods, 'e', function()
  moveWindowToUnit(windowUnits.leftTwoThirds)
end)
hs.hotkey.bind(windowHotkeyMods, 't', function()
  moveWindowToUnit(windowUnits.rightTwoThirds)
end)
hs.hotkey.bind({ 'alt', 'ctrl' }, 'return', function()
  moveWindowToUnit(windowUnits.fill)
end)

-- F19 is emitted by Karabiner when right_command is held (see karabiner.nix).
-- Karabiner intercepts app-launcher and local-binding keys directly for Secure
-- Input immunity; Hammerspoon only handles logic-heavy bindings below.
Hyper:bindHotKeys({hyperKey = {{}, 'F19'}})

VimImeGuard = spoon.VimImeGuard
VimImeGuard:init({
  bundleIDs = {
    ['md.obsidian'] = true,
  },
})
VimImeGuard:start()

-- provide the ability to override config per computer
if (hs.fs.displayName('./localConfig.lua')) then
    require('localConfig')
end

-- Initialize Pomodoro Spoon
Pomodoro = spoon.Pomodoro
Pomodoro:init({
  onWorkStart = function()
    hs.alert.show("🚀 Pomodoro 시작!", 1)
  end,
  onBreakStart = function()
    hs.alert.show("🍅 25분 완료!\n5분 휴식하세요", 2)
  end,
  onComplete = function()
    hs.alert.show("✅ 세션 완료!\n수고하셨습니다", 2)
  end,
  onStopped = function()
    hs.alert.show("⏹️ Pomodoro 세션 중지됨", 2)
  end
}):start()

-- Bind Hyper+P to toggle Pomodoro session
Hyper:bind({}, 'p', function() Pomodoro:toggleSession() end)

-- Warn when Secure Input gets enabled (1Password is the usual culprit).
-- Why: Secure Input blocks Hammerspoon/Karabiner from receiving key events,
-- silently breaking the Hyper key. Surface it instead of debugging blind.
local secureInputTimer = hs.timer.new(2, function()
  if hs.eventtap.isSecureInputEnabled() then
    if not _G._secureInputWarned then
      hs.alert.show("⚠️ Secure Input ON — close 1Password window", 3)
      _G._secureInputWarned = true
    end
  else
    _G._secureInputWarned = false
  end
end)
secureInputTimer:start()
