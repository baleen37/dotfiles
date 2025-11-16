hs.loadSpoon('Hyper')
-- hs.loadSpoon('Headspace'):start()
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

-- Load aerospace module
local aerospace = require('aerospace')

-- HyperModal with aerospace bindings
HyperModal
 :start()
 :bind('', "1", function() aerospace({"move-node-to-workspace", "1"}) end)
 :bind('', "2", function() aerospace({"move-node-to-workspace", "2"}) end)
 :bind('', "3", function() aerospace({"move-node-to-workspace", "3"}) end)
 :bind('', "4", function() aerospace({"move-node-to-workspace", "4"}) end)
 :bind('', "5", function() aerospace({"move-node-to-workspace", "5"}) end)
 :bind('', "z", function() aerospace({"layout", "toggle", "accordion"}) end)
 :bind('', "v", function() aerospace({"layout", "tiles", "horizontal", "vertical"}) end)
 :bind('', "x", function() aerospace({"split", "vertical"}) end)
 :bind('', "space", function() aerospace({"fullscreen", "toggle"}) end)
 :bind('', "h", function() aerospace({"swap", "left"}) end)
 :bind('', "j", function() aerospace({"swap", "down"}) end)
 :bind('', "k", function() aerospace({"swap", "up"}) end)
 :bind('', "l", function() aerospace({"swap", "right"}) end)
 :bind({"alt"}, "h", function() aerospace({"focus", "left"}) end)
 :bind({"alt"}, "j", function() aerospace({"focus", "down"}) end)
 :bind({"alt"}, "k", function() aerospace({"focus", "up"}) end)
 :bind({"alt"}, "l", function() aerospace({"focus", "right"}) end)
 :bind({"shift"}, "l", function() aerospace({"move", "to-display", "east"}) end)
 :bind({"shift"}, "h", function() aerospace({"move", "to-display", "west"}) end)
 :bind("", "s", function() aerospace({"layout", "stack"}) end)
 :bind('', "r", function() aerospace({"balance", "root"}) end)
 :bind({"shift"}, "b", function() aerospace({"layout", "stack"}) end)
 :bind("", "b", function() aerospace({"layout", "bsp"}) end)
 :bind('', ";", function() hs.urlevent.openURL("raycast://extensions/raycast/system/toggle-system-appearance") end)
