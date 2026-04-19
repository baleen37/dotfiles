require('hs.ipc')
hs.allowAppleScript(true)
hs.loadSpoon('Hyper')
hs.loadSpoon('HyperModal')
hs.loadSpoon('Pomodoro')


Config = {}
Config.applications = require('configApplications')

Hyper = spoon.Hyper

Hyper:bindHotKeys({hyperKey = {{}, 'F19'}})

-- provide the ability to override config per computer
if (hs.fs.displayName('./localConfig.lua')) then
    require('localConfig')
end


hs.fnutils.each(Config.applications, function(appConfig)
  if appConfig.hyperKey then
    Hyper:bind({}, appConfig.hyperKey, function()
        if hs.application.get(appConfig.bundleID) and hs.application.get(appConfig.bundleID):isFrontmost() then
            hs.application.get(appConfig.bundleID):hide()
        else
            hs.application.launchOrFocusByBundleID(appConfig.bundleID)
        end
    end)
  end
  if appConfig.localBindings then
    hs.fnutils.each(appConfig.localBindings, function(key)
      Hyper:bindPassThrough(key, appConfig.bundleID)
    end)
  end
end)

HyperModal = spoon.HyperModal
Hyper:bind({}, 'm', function() HyperModal:toggle() end)

-- HyperModal with basic bindings
HyperModal
 :start()
 :bind('', ";", function() hs.urlevent.openURL("raycast://extensions/raycast/system/toggle-system-appearance") end)

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
