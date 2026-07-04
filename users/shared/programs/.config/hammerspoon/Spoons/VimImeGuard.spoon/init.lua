--- === VimImeGuard ===
---
--- Keeps Vim normal mode usable in configured apps when a non-English IME is
--- active.
---
--- The guard lets the original Escape clear IME composition, then switches to
--- ABC before rapid follow-up keys like "jjj" can leak composed text.

local obj = {}
obj.__index = obj

obj.name = "VimImeGuard"
obj.version = "1.0"
obj.author = "local"
obj.license = "MIT"
obj.homepage = "https://github.com/evantravers/dotfiles"
obj.description = "Switches configured Vim apps back to ABC after Escape."

obj.inputEnglish = 'com.apple.keylayout.ABC'
obj.bundleIDs = {}
obj.vimEscapePendingSeconds = 0.25
obj.vimEscapeReplayDelay = 0.01
obj.vimEscapeCtrlReplayDelay = 0
obj.vimEscapeSyntheticResetDelay = 0.05

function obj:init(config)
  config = config or {}
  self.inputEnglish = config.inputEnglish or self.inputEnglish
  self.bundleIDs = config.bundleIDs or self.bundleIDs
  self.vimEscapeSynthetic = false
  self.vimEscapePendingUntil = 0
  return self
end

function obj:frontmostAppUsesVimImeGuard()
  local app = hs.application.frontmostApplication()
  local bundleID = app and app:bundleID()
  return bundleID and self.bundleIDs[bundleID] == true
end

local function hasOnlyModifiers(flags, allowed)
  for _, name in ipairs({'cmd', 'alt', 'shift', 'ctrl', 'fn'}) do
    if flags[name] and not allowed[name] then
      return false
    end
  end
  return true
end

local function isPlainEscape(event)
  return event:getKeyCode() == 53 and hasOnlyModifiers(event:getFlags(), {})
end

local function isCtrlLeftBracket(event)
  return event:getKeyCode() == 33 and hasOnlyModifiers(event:getFlags(), {ctrl = true})
end

function obj:hasPendingVimEscape()
  return self.vimEscapePendingUntil > hs.timer.secondsSinceEpoch()
end

function obj:scheduleVimEscape(modifiers, key, delay)
  self.vimEscapePendingUntil = hs.timer.secondsSinceEpoch() + self.vimEscapePendingSeconds
  hs.timer.doAfter(delay, function()
    hs.keycodes.currentSourceID(self.inputEnglish)
    self.vimEscapeSynthetic = true
    hs.eventtap.keyStroke(modifiers, key, 0)
    hs.timer.doAfter(self.vimEscapeSyntheticResetDelay, function()
      self.vimEscapeSynthetic = false
    end)
  end)
end

function obj:start()
  if self.vimEscapeTap then
    self.vimEscapeTap:stop()
  end

  self.vimEscapeSynthetic = false
  self.vimEscapePendingUntil = 0

  self.vimEscapeTap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
    if self.vimEscapeSynthetic or not self:frontmostAppUsesVimImeGuard() then
      return false
    end

    if self:hasPendingVimEscape() then
      hs.keycodes.currentSourceID(self.inputEnglish)
    end

    if isPlainEscape(event) then
      self:scheduleVimEscape({}, 'escape', self.vimEscapeReplayDelay)
      return false
    end

    if isCtrlLeftBracket(event) then
      self:scheduleVimEscape({}, 'escape', self.vimEscapeCtrlReplayDelay)
      return false
    end

    return false
  end)

  self.vimEscapeTap:start()
  return self
end

function obj:stop()
  if self.vimEscapeTap then
    self.vimEscapeTap:stop()
  end
  return self
end

function obj:isEnabled()
  return self.vimEscapeTap and self.vimEscapeTap:isEnabled() or false
end

return obj
