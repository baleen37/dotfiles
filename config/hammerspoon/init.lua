hs.loadSpoon('Hyper')
hs.loadSpoon('Headspace'):start()
hs.loadSpoon('HyperModal')


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



toggleApp = function(appName, launch)
    launch = launch or false
    local app = hs.application.get(appName)
    if app then
        if app:isFrontmost() then
            app:hide()
        else
            app:activate()
        end
    else
        if launch then
            hs.application.launchOrFocus(appName)
        else
            hs.alert.show("App '" .. appName .. "' is not loaded!")
        end
    end
  end
  
  hs.hotkey.bind({"cmd", "shift", "ctrl"}, "o", function() toggleApp("obsidian") end)
  hs.hotkey.bind({"cmd", "shift", "ctrl"}, "i", function() toggleApp("iTerm") end)
  hs.hotkey.bind({"cmd", "shift", "ctrl"}, "t", function() toggleApp("Things") end)
