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

-- Load yabai module
local yabai = require('yabai')

-- HyperModal with yabai bindings
HyperModal
 :start()
 :bind('', "1", function() yabai({"-m", "window", "--swap", "first"}) end)
 :bind('', "z", function() yabai({"-m", "window", "--toggle", "zoom-parent"}) end)
 :bind('', "v", function() yabai({"-m", "space", "--mirror", "y-axis"}) end)
 :bind('', "x", function() yabai({"-m", "window", "--toggle", "split"}) end)
 :bind('', "space", function() yabai({"-m", "space", "--toggle", "zoom-fullscreen"}) end)
 :bind('', "h", function() yabai({"-m", "window", "--swap", "west"}) end)
 :bind('', "j", function() yabai({"-m", "window", "--swap", "south"}) end)
 :bind('', "k", function() yabai({"-m", "window", "--swap", "north"}) end)
 :bind('', "l", function() yabai({"-m", "window", "--swap", "east"}) end)
 :bind({"alt"}, "h", function() yabai({"-m", "window", "--warp", "west"}) end)
 :bind({"alt"}, "j", function() yabai({"-m", "window", "--warp", "south"}) end)
 :bind({"alt"}, "k", function() yabai({"-m", "window", "--warp", "north"}) end)
 :bind({"alt"}, "l", function() yabai({"-m", "window", "--warp", "east"}) end)
 :bind({"shift"}, "l", function() yabai({"-m", "window", "--display", "east"}) end)
 :bind({"shift"}, "h", function() yabai({"-m", "window", "--display", "west"}) end)
 :bind("", "s", function() yabai({"-m", "window", "--stack", "mouse"}) end)
 :bind('', "r", function() yabai({"-m", "space", "--balance"}) end)
 :bind({"shift"}, "b", function() yabai({"-m", "space", "--layout", "stack"}) end)
 :bind("", "b", function() yabai({"-m", "space", "--layout", "bsp"}) end)
 :bind('', ";", function() hs.urlevent.openURL("raycast://extensions/raycast/system/toggle-system-appearance") end)
