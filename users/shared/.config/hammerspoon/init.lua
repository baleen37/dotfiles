hs.loadSpoon('Hyper')
-- hs.loadSpoon('Headspace'):start()
hs.loadSpoon('HyperModal')
hs.loadSpoon('Pomodoro')  -- FIXED: hs.focus dependency removed


Config = {}
Config.applications = require('configApplications')
print('Config.applications = require("configApplications")')
print('Config.applications = ', Config.applications)

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
Pomodoro:start()  -- FIXED: hs.focus dependency removed

-- Bind hotkeys for manual control
Pomodoro:bindHotkeys({
  start = {{"ctrl"}, "1"},
  stop = {{"ctrl"}, "2"},
  toggle = {{"ctrl"}, "p"}
})
